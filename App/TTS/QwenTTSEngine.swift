import Foundation
import MLX
@preconcurrency import Qwen3TTS

/// In-process Qwen3-TTS Base engine running on MLX.
///
/// `Qwen3TTSModel.generateVoiceClone` is synchronous and can run for minutes, so this
/// actor uses its own serial dispatch queue as executor — the blocking call occupies
/// that queue's thread rather than a thread of the shared cooperative pool. MLX types
/// never leave this actor; the `TTSEngine` boundary speaks `[Float]`/`URL` only.
actor QwenTTSEngine: TTSEngine {
    private let modelDirectory: URL
    private let queue = DispatchSerialQueue(label: "com.dubertrand.MacVoiceCloning.tts", qos: .userInitiated)
    private var model: Qwen3TTSModel?

    nonisolated var unownedExecutor: UnownedSerialExecutor { queue.asUnownedSerialExecutor() }

    init(modelDirectory: URL) {
        self.modelDirectory = modelDirectory
    }

    func load() async throws {
        guard model == nil else { return }
        let loaded = try await Qwen3TTSModel.fromPretrained(modelDirectory.path)
        guard loaded.ttsModelType == "base" else {
            throw TTSEngineError.generationFailed(
                "Model at \(modelDirectory.lastPathComponent) is '\(loaded.ttsModelType)', not a Base (voice clone) model.")
        }
        model = loaded
    }

    func synthesize(
        _ request: SynthesisRequest,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> SynthesisResult {
        guard let model else { throw TTSEngineError.modelNotLoaded }

        // Read via AudioConverting (not the package's loadAudioArray, whose single
        // read call can silently truncate the file on macOS 26).
        let (referenceSamples, sampleRate) = try await AudioConverting.readMonoFloat(
            url: request.referenceAudioURL)
        guard sampleRate == model.sampleRate else {
            throw TTSEngineError.badReferenceAudio(
                "expected \(model.sampleRate) Hz, got \(sampleRate) Hz")
        }
        let referenceSeconds = Double(referenceSamples.count) / Double(sampleRate)
        guard referenceSeconds >= 3.0 else {
            throw TTSEngineError.badReferenceAudio(
                "it lasts \(String(format: "%.1f", referenceSeconds)) s; at least 3 s are needed")
        }
        let referenceAudio = MLXArray(referenceSamples)

        let started = Date()
        var tokenCount = 0
        defer { GPU.clearCache() }
        do {
            let audio = try model.generateVoiceClone(
                text: request.text,
                referenceAudio: referenceAudio,
                referenceText: request.referenceText,
                language: request.language.rawValue,
                maxTokens: request.maxTokens,
                onToken: { _ in
                    // The Int argument is the token *value*; progress comes from counting.
                    tokenCount += 1
                    if tokenCount % 6 == 0 {
                        onProgress(Double(tokenCount) / 12.0)
                    }
                }
            )
            let samples = audio.asArray(Float.self)
            let stats = SynthesisStats(
                generatedTokens: tokenCount,
                totalSeconds: Date().timeIntervalSince(started))
            return SynthesisResult(samples: samples, sampleRate: model.sampleRate, stats: stats)
        } catch let error as TTSEngineError {
            throw error
        } catch {
            throw TTSEngineError.generationFailed(String(describing: error))
        }
    }

    func unload() async {
        model = nil
        GPU.clearCache()
    }
}
