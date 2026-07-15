import Foundation

/// Languages supported by Qwen3-TTS Base. Raw values match the package's `language` parameter.
nonisolated enum TTSLanguage: String, CaseIterable, Sendable, Identifiable {
    case auto, english, chinese, japanese, korean, german, french, russian, portuguese, spanish, italian

    var id: String { rawValue }
    var displayName: String { rawValue == "auto" ? "Auto-detect" : rawValue.capitalized }

    /// Locale used for on-device transcription of the reference sample.
    var localeIdentifier: String? {
        switch self {
        case .auto: nil
        case .english: "en-US"
        case .chinese: "zh-CN"
        case .japanese: "ja-JP"
        case .korean: "ko-KR"
        case .german: "de-DE"
        case .french: "fr-FR"
        case .russian: "ru-RU"
        case .portuguese: "pt-BR"
        case .spanish: "es-ES"
        case .italian: "it-IT"
        }
    }
}

nonisolated struct SynthesisRequest: Sendable {
    var text: String
    var language: TTSLanguage = .auto
    /// Must point at a 24 kHz mono WAV of at least 3 seconds.
    var referenceAudioURL: URL
    var referenceText: String
    var maxTokens: Int = 2048
}

nonisolated struct SynthesisStats: Sendable {
    var generatedTokens: Int
    var totalSeconds: TimeInterval
    var tokensPerSecond: Double { totalSeconds > 0 ? Double(generatedTokens) / totalSeconds : 0 }
}

nonisolated struct SynthesisResult: Sendable {
    var samples: [Float]
    var sampleRate: Int
    var stats: SynthesisStats?
}

/// Backend boundary: implementations may run in-process (MLX) or out-of-process.
/// Only Sendable value types cross this interface.
nonisolated protocol TTSEngine: Sendable {
    /// Idempotent; brings the model from disk into memory.
    func load() async throws
    /// `onProgress` reports seconds of audio generated so far.
    func synthesize(
        _ request: SynthesisRequest,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> SynthesisResult
    func unload() async
}

nonisolated enum TTSEngineError: LocalizedError {
    case modelNotLoaded
    case badReferenceAudio(String)
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            "The voice model is not loaded yet."
        case .badReferenceAudio(let detail):
            "The reference recording can't be used: \(detail)"
        case .generationFailed(let detail):
            "Speech generation failed: \(detail)"
        }
    }
}
