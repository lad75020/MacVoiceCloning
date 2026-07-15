import Foundation
import Testing

struct SynthesisContractsTests {
    @Test func estimatesAudioDurationFromCodecTokens() {
        let progress = SynthesisProgress(generatedTokens: 25)

        #expect(progress.estimatedAudioSeconds == 2)
        #expect(SynthesisProgress.codecTokensPerSecond == 12.5)
    }

    @Test func calculatesTokenThroughput() {
        let stats = SynthesisStats(generatedTokens: 48, totalSeconds: 4)

        #expect(stats.tokensPerSecond == 12)
        #expect(SynthesisStats(generatedTokens: 1, totalSeconds: 0).tokensPerSecond == 0)
    }

    @Test func validatesGeneratedAudio() throws {
        try SynthesisResult(samples: [0, 0.25, -0.25], sampleRate: 24_000, stats: nil).validate()

        #expect(throws: TTSEngineError.self) {
            try SynthesisResult(samples: [], sampleRate: 24_000, stats: nil).validate()
        }
        #expect(throws: TTSEngineError.self) {
            try SynthesisResult(samples: [0], sampleRate: 0, stats: nil).validate()
        }
        #expect(throws: TTSEngineError.self) {
            try SynthesisResult(samples: [.nan], sampleRate: 24_000, stats: nil).validate()
        }
        #expect(throws: TTSEngineError.self) {
            try SynthesisResult(samples: [.infinity], sampleRate: 24_000, stats: nil).validate()
        }
    }

    @Test func validatesSynthesisRequests() throws {
        let reference = URL(filePath: "/tmp/reference.wav")
        try SynthesisRequest(
            text: "Hello", referenceAudioURL: reference, referenceText: "Reference").validate()

        #expect(throws: TTSEngineError.self) {
            try SynthesisRequest(
                text: "  \n", referenceAudioURL: reference, referenceText: "Reference").validate()
        }
        #expect(throws: TTSEngineError.self) {
            try SynthesisRequest(
                text: "Hello", referenceAudioURL: reference, referenceText: " ").validate()
        }
        #expect(throws: TTSEngineError.self) {
            try SynthesisRequest(
                text: "Hello", referenceAudioURL: reference, referenceText: "Reference", maxTokens: 0).validate()
        }
    }

    @Test func commitsFirstAndReplacementSynthesis() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "synthesis-contract-\(UUID().uuidString)")
        let staging = directory.appending(path: "staging.wav")
        let destination = directory.appending(path: "synthesis.wav")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try Data("first".utf8).write(to: staging)
        try SessionFiles.commitPreparedSynthesis(at: staging, to: destination)
        #expect(try Data(contentsOf: destination) == Data("first".utf8))
        #expect(!FileManager.default.fileExists(atPath: staging.path))

        try Data("replacement".utf8).write(to: staging)
        try SessionFiles.commitPreparedSynthesis(at: staging, to: destination)
        #expect(try Data(contentsOf: destination) == Data("replacement".utf8))
        #expect(!FileManager.default.fileExists(atPath: staging.path))
    }
}