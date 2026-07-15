import Foundation
import Observation

/// All pipeline data and orchestration: reference sample → target text →
/// synthesis → alteration → export source.
@Observable
@MainActor
final class PipelineState {
    nonisolated struct ReferenceSample: Equatable, Sendable {
        /// 24 kHz mono WAV, ready for the TTS engine.
        var url: URL
        var duration: TimeInterval
    }

    nonisolated struct AudioClip: Equatable, Sendable {
        var samples: [Float]
        var sampleRate: Int
        var url: URL

        var duration: TimeInterval { Double(samples.count) / Double(sampleRate) }
    }

    // Stage 1 — reference
    private(set) var reference: ReferenceSample?
    var referenceTranscript: String = ""
    private(set) var isPreparingReference = false
    private(set) var isTranscribing = false

    // Stage 2 — text
    var targetText: String = "" {
        didSet {
            guard targetText != oldValue else { return }
            invalidateSynthesis()
        }
    }
    var language: TTSLanguage = .auto {
        didSet {
            guard language != oldValue else { return }
            invalidateSynthesis()
        }
    }

    var synthesisText: String {
        targetText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Stage 3 — synthesis
    private(set) var isSynthesizing = false
    private(set) var synthesisProgress: Double = 0
    private(set) var synthesis: AudioClip?
    private(set) var synthesisStats: SynthesisStats?

    // Stage 4 — alteration
    var effect = VoiceEffectParameters()
    var bypassEffect = false
    private(set) var isAltering = false
    private(set) var altered: AudioClip?

    var lastError: String?

    /// What export (stage 5) will save.
    var exportClip: AudioClip? { altered ?? synthesis }

    /// What the alter stage's preview button plays.
    var previewClip: AudioClip? { bypassEffect ? synthesis : (altered ?? synthesis) }

    private var transcriptionTask: Task<Void, Never>?
    private var alterationTask: Task<Void, Never>?
    private var synthesisRevision: UInt = 0

    // MARK: - Reference

    /// Converts a raw recording or imported file into the 24 kHz mono reference
    /// and kicks off transcription.
    func setReference(fromRaw rawURL: URL) async {
        guard !isPreparingReference else { return }
        isPreparingReference = true
        defer {
            try? FileManager.default.removeItem(at: SessionFiles.referenceStaging)
            isPreparingReference = false
        }
        do {
            try SessionFiles.prepareDirectories()
            let duration = try await AudioConverting.convertToMono24kWAV(
                input: rawURL, output: SessionFiles.referenceStaging)
            guard duration >= AudioRecorder.minimumDuration else {
                lastError = String(
                    format: "The sample lasts %.1f s — Qwen3-TTS needs at least %.0f s (5–15 s of clear speech works best).",
                    duration, AudioRecorder.minimumDuration)
                return
            }
            try SessionFiles.commitPreparedReference(at: SessionFiles.referenceStaging)
            reference = ReferenceSample(url: SessionFiles.reference24k, duration: duration)
            invalidateSynthesis()
            transcribeReference()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func transcribeReference() {
        transcriptionTask?.cancel()
        guard let reference else { return }
        isTranscribing = true
        referenceTranscript = ""
        let url = reference.url
        let localeIdentifier = language.localeIdentifier
        transcriptionTask = Task { [weak self] in
            let text = try? await ReferenceTranscriber.transcribe(
                fileURL: url, localeIdentifier: localeIdentifier)
            guard let self, !Task.isCancelled else { return }
            if let text, !text.isEmpty, self.referenceTranscript.isEmpty {
                self.referenceTranscript = text
            }
            self.isTranscribing = false
        }
    }

    // MARK: - Synthesis

    var hasSynthesisInputs: Bool {
        reference != nil
            && !synthesisText.isEmpty
            && !referenceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func synthesize(with engine: any TTSEngine) async {
        guard let reference, hasSynthesisInputs, !isSynthesizing else { return }
        let revision = synthesisRevision
        let request = SynthesisRequest(
            text: synthesisText,
            language: language,
            referenceAudioURL: reference.url,
            referenceText: referenceTranscript.trimmingCharacters(in: .whitespacesAndNewlines))
        isSynthesizing = true
        synthesisProgress = 0
        lastError = nil
        defer {
            try? FileManager.default.removeItem(at: SessionFiles.synthesisStaging)
            isSynthesizing = false
        }
        do {
            let result = try await engine.synthesize(request) { progress in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.synthesisRevision == revision,
                          self.isSynthesizing
                    else { return }
                    self.synthesisProgress = max(
                        self.synthesisProgress, progress.estimatedAudioSeconds)
                }
            }
            guard synthesisRevision == revision else { return }
            try result.validate()
            try SessionFiles.prepareDirectories()
            try await AudioConverting.writeWAV(
                samples: result.samples,
                sampleRate: result.sampleRate,
                to: SessionFiles.synthesisStaging)
            guard synthesisRevision == revision else { return }
            try SessionFiles.commitPreparedSynthesis(at: SessionFiles.synthesisStaging)
            synthesis = AudioClip(
                samples: result.samples, sampleRate: result.sampleRate, url: SessionFiles.synthesisWAV)
            synthesisStats = result.stats
            altered = nil
            scheduleAlteration(debounced: false)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func invalidateSynthesis() {
        synthesisRevision &+= 1
        alterationTask?.cancel()
        synthesis = nil
        synthesisStats = nil
        altered = nil
        synthesisProgress = 0
    }

    // MARK: - Alteration

    /// Re-runs Rubber Band over the synthesis with the current parameters,
    /// debounced so slider drags don't queue up work.
    func scheduleAlteration(debounced: Bool = true) {
        alterationTask?.cancel()
        guard synthesis != nil else { return }
        alterationTask = Task { [weak self] in
            if debounced {
                try? await Task.sleep(for: .milliseconds(300))
            }
            guard let self, !Task.isCancelled else { return }
            await self.refreshAlteration()
        }
    }

    private func refreshAlteration() async {
        guard let synthesis else {
            altered = nil
            return
        }
        guard !effect.isIdentity else {
            altered = nil
            return
        }
        isAltering = true
        defer { isAltering = false }
        do {
            let processed = try await RubberBandProcessor.process(
                samples: synthesis.samples, sampleRate: synthesis.sampleRate, parameters: effect)
            try Task.checkCancellation()
            try await AudioConverting.writeWAV(
                samples: processed, sampleRate: synthesis.sampleRate, to: SessionFiles.alteredWAV)
            altered = AudioClip(
                samples: processed, sampleRate: synthesis.sampleRate, url: SessionFiles.alteredWAV)
        } catch is CancellationError {
            // A newer parameter change superseded this run.
        } catch {
            lastError = error.localizedDescription
        }
    }
}
