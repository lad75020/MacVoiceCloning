import Foundation
import Testing

struct TTSLanguageTests {
    @Test func exposesExactModelLanguageCatalog() {
        #expect(TTSLanguage.allCases.map(\.rawValue) == [
            "auto", "english", "chinese", "japanese", "korean", "german",
            "french", "russian", "portuguese", "spanish", "italian",
        ])
        #expect(TTSLanguage.allCases.map(\.displayName) == [
            "Auto-detect", "English", "Chinese", "Japanese", "Korean", "German",
            "French", "Russian", "Portuguese", "Spanish", "Italian",
        ])
    }

    @Test func mapsReferenceTranscriptionLocales() {
        #expect(TTSLanguage.allCases.map(\.localeIdentifier) == [
            nil, "en-US", "zh-CN", "ja-JP", "ko-KR", "de-DE",
            "fr-FR", "ru-RU", "pt-BR", "es-ES", "it-IT",
        ])
    }

    @Test func synthesisRequestDefaultsToAutoDetect() {
        let request = SynthesisRequest(
            text: "Bonjour le monde",
            referenceAudioURL: URL(filePath: "/tmp/reference.wav"),
            referenceText: "Hello world")

        #expect(request.language == .auto)
        #expect(request.text == "Bonjour le monde")
    }
}