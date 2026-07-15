import Foundation
import Synchronization
import Testing

/// End-to-end voice-clone smoke test. Gated behind MVC_TTS_SMOKE=1 because the first
/// run downloads the ~3.5 GB model and generation itself takes a while.
///
///   xcodebuild test ... -only-testing:MacVoiceCloningTests/TTSSmokeTests \
///       TEST_RUNNER_MVC_TTS_SMOKE=1
struct TTSSmokeTests {
    nonisolated static let smokeEnabled = ProcessInfo.processInfo.environment["MVC_TTS_SMOKE"] == "1"

    /// Same location the app uses, so the download is shared with normal app runs.
    private var modelsRoot: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "MacVoiceCloning/Models", directoryHint: .isDirectory)
    }

    @Test(.enabled(if: smokeEnabled), .timeLimit(.minutes(60)))
    func voiceCloneEndToEnd() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "mvc-smoke-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // 1. Fabricate a reference speaker with the system voice.
        let referenceText =
            "The quick brown fox jumps over the lazy dog, then it runs far away across the quiet green field before resting."
        let aiff = dir.appending(path: "ref.aiff")
        let say = Process()
        say.executableURL = URL(filePath: "/usr/bin/say")
        say.arguments = ["-o", aiff.path, referenceText]
        try say.run()
        say.waitUntilExit()
        try #require(say.terminationStatus == 0)

        // 2. Convert to the 24 kHz mono reference format.
        let reference = dir.appending(path: "ref-24k.wav")
        let referenceDuration = try await AudioConverting.convertToMono24kWAV(input: aiff, output: reference)
        try #require(referenceDuration >= 3.0)

        // 3. Ensure the model snapshot is present (resumes/no-ops when already there).
        try FileManager.default.createDirectory(at: modelsRoot, withIntermediateDirectories: true)
        let downloader = ModelDownloader(modelsRoot: modelsRoot)
        let lastReported = Mutex(-1)
        let modelDirectory = try await downloader.download { fraction in
            let percent = Int(fraction * 100)
            let shouldPrint = lastReported.withLock { last in
                guard percent / 5 != last / 5 else { return false }
                last = percent
                return true
            }
            if shouldPrint { print("SMOKE download: \(percent)%") }
        }

        // 4. Load and clone.
        let engine = QwenTTSEngine(modelDirectory: modelDirectory)
        try await engine.load()
        let request = SynthesisRequest(
            text: "Hello! This is my cloned voice, generated entirely on this Mac by the smoke test.",
            language: .english,
            referenceAudioURL: reference,
            referenceText: referenceText)
        let result = try await engine.synthesize(request) { seconds in
            print("SMOKE generated: \(String(format: "%.1f", seconds)) s")
        }
        await engine.unload()

        // 5. Sanity-check and persist the audio for human audition.
        #expect(result.sampleRate == 24_000)
        #expect(result.samples.count > 24_000, "expected at least 1 s of audio")
        #expect(result.samples.allSatisfy { $0.isFinite })
        let rms = sqrt(result.samples.reduce(0) { $0 + $1 * $1 } / Float(result.samples.count))
        #expect(rms > 0.001, "output should not be silence")

        let out = dir.appending(path: "smoke-out.wav")
        try await AudioConverting.writeWAV(samples: result.samples, sampleRate: result.sampleRate, to: out)
        if let stats = result.stats {
            print("SMOKE stats: \(stats.generatedTokens) tokens in \(String(format: "%.1f", stats.totalSeconds)) s (\(String(format: "%.1f", stats.tokensPerSecond)) tok/s)")
        }
        print("SMOKE OUTPUT: \(out.path)")

        // 6. Drive the rest of the pipeline exactly as the UI does:
        //    Rubber Band alteration, then M4A export.
        var effect = VoiceEffectParameters()
        effect.pitchSemitones = 7
        effect.speed = 1.15
        effect.preserveFormants = false
        let altered = try await RubberBandProcessor.process(
            samples: result.samples, sampleRate: result.sampleRate, parameters: effect)
        let expectedLength = Double(result.samples.count) * effect.timeRatio
        #expect(abs(Double(altered.count) - expectedLength) / expectedLength < 0.1)
        #expect(altered.allSatisfy { $0.isFinite })

        let m4a = dir.appending(path: "smoke-out.m4a")
        try await AudioConverting.writeM4A(samples: altered, sampleRate: result.sampleRate, to: m4a)
        let attributes = try FileManager.default.attributesOfItem(atPath: m4a.path)
        #expect((attributes[.size] as? Int ?? 0) > 10_000, "M4A export should not be empty")
        let (roundTrip, roundTripRate) = try await AudioConverting.readMonoFloat(url: m4a)
        #expect(roundTripRate == result.sampleRate)
        #expect(abs(Double(roundTrip.count) - Double(altered.count)) < Double(result.sampleRate),
                "M4A round-trip duration should be within 1 s (AAC priming)")
        print("SMOKE ALTERED M4A: \(m4a.path)")
    }
}
