import AVFoundation
import Speech

/// Best-effort on-device transcription of the recorded reference sample using the
/// macOS 26 SpeechAnalyzer API. Strictly additive: callers treat any failure as
/// "leave the transcript for the user to type".
nonisolated enum ReferenceTranscriber {
    enum TranscriberError: LocalizedError {
        case unsupportedLocale(String)
        var errorDescription: String? {
            switch self {
            case .unsupportedLocale(let identifier):
                "On-device transcription doesn't support the locale \(identifier)."
            }
        }
    }

    @concurrent
    static func transcribe(fileURL: URL, localeIdentifier: String?) async throws -> String {
        let wanted = localeIdentifier.map(Locale.init(identifier:)) ?? .current

        let supported = await SpeechTranscriber.supportedLocales
        guard let locale = supported.first(where: {
            $0.identifier(.bcp47) == wanted.identifier(.bcp47)
        }) ?? supported.first(where: {
            $0.language.languageCode == wanted.language.languageCode
        }) else {
            throw TranscriberError.unsupportedLocale(wanted.identifier)
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: [])

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }

        let file = try AVAudioFile(forReading: fileURL)
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        async let collected = transcriber.results.reduce(into: "") { text, result in
            text += String(result.text.characters)
        }

        _ = try await analyzer.analyzeSequence(from: file)
        try await analyzer.finalizeAndFinishThroughEndOfInput()

        return try await collected.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
