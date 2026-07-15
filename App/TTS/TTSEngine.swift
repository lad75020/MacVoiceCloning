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

    func validate() throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TTSEngineError.invalidRequest("target text is empty")
        }
        guard !referenceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TTSEngineError.invalidRequest("reference transcript is empty")
        }
        guard maxTokens > 0 else {
            throw TTSEngineError.invalidRequest("maximum token count must be positive")
        }
    }
}

nonisolated struct SynthesisProgress: Sendable {
    static let codecTokensPerSecond = 12.5

    let generatedTokens: Int
    var estimatedAudioSeconds: TimeInterval {
        Double(generatedTokens) / Self.codecTokensPerSecond
    }
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

    func validate() throws {
        guard sampleRate > 0 else {
            throw TTSEngineError.invalidOutput("sample rate must be positive")
        }
        guard !samples.isEmpty else {
            throw TTSEngineError.invalidOutput("no audio samples were generated")
        }
        guard samples.allSatisfy(\.isFinite) else {
            throw TTSEngineError.invalidOutput("audio contains non-finite samples")
        }
    }
}

/// Backend boundary: implementations may run in-process (MLX) or out-of-process.
/// Only Sendable value types cross this interface.
nonisolated protocol TTSEngine: Sendable {
    /// Idempotent; brings the model from disk into memory.
    func load() async throws
    /// `onProgress` reports emitted codec tokens and their estimated audio duration.
    func synthesize(
        _ request: SynthesisRequest,
        onProgress: @escaping @Sendable (SynthesisProgress) -> Void
    ) async throws -> SynthesisResult
    func unload() async
}

nonisolated enum TTSEngineError: LocalizedError {
    case modelNotLoaded
    case invalidRequest(String)
    case badReferenceAudio(String)
    case generationFailed(String)
    case invalidOutput(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            "The voice model is not loaded yet."
        case .invalidRequest(let detail):
            "The synthesis request can't be used: \(detail)."
        case .badReferenceAudio(let detail):
            "The reference recording can't be used: \(detail)"
        case .generationFailed(let detail):
            "Speech generation failed: \(detail)"
        case .invalidOutput(let detail):
            "Generated audio can't be used: \(detail)."
        }
    }
}
