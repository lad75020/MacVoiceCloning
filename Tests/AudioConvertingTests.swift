import AVFoundation
import Foundation
import Testing

struct AudioConvertingTests {
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "mvc-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func sine(frequency: Double, seconds: Double, sampleRate: Int, amplitude: Float = 0.5) -> [Float] {
        let count = Int(Double(sampleRate) * seconds)
        return (0..<count).map { amplitude * Float(sin(2 * .pi * frequency * Double($0) / Double(sampleRate))) }
    }

    private func rms(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        return sqrt(samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count))
    }

    private func clip(
        samples: [Float]? = nil,
        sampleRate: Int = 24_000
    ) -> AudioExporter.Clip {
        AudioExporter.Clip(
            samples: samples ?? sine(frequency: 440, seconds: 0.5, sampleRate: sampleRate),
            sampleRate: sampleRate)
    }

    private func source(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appending(path: relativePath),
            encoding: .utf8)
    }

    @Test func wavRoundTripPreservesSamples() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "tone.wav")
        let input = sine(frequency: 440, seconds: 1.0, sampleRate: 24_000)

        try await AudioConverting.writeWAV(samples: input, sampleRate: 24_000, to: url)
        let (output, sampleRate) = try await AudioConverting.readMonoFloat(url: url)

        #expect(sampleRate == 24_000)
        #expect(output.count == input.count)
        #expect(abs(rms(output) - rms(input)) < 0.001)
    }

    @Test func downsamples48kTo24kMono() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = dir.appending(path: "tone-48k.wav")
        let converted = dir.appending(path: "tone-24k.wav")
        let input = sine(frequency: 440, seconds: 2.0, sampleRate: 48_000)
        try await AudioConverting.writeWAV(samples: input, sampleRate: 48_000, to: source)

        let duration = try await AudioConverting.convertToMono24kWAV(input: source, output: converted)

        #expect(abs(duration - 2.0) < 0.05)
        let (output, sampleRate) = try await AudioConverting.readMonoFloat(url: converted)
        #expect(sampleRate == 24_000)
        #expect(abs(output.count - 48_000) < 480)
        // A 440 Hz tone is far below the new Nyquist limit; energy should be preserved.
        #expect(abs(rms(output) - rms(input)) < 0.02)
    }

    @Test func convertsSayGeneratedSpeechToReferenceFormat() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let aiff = dir.appending(path: "ref.aiff")
        let wav = dir.appending(path: "ref-24k.wav")

        let say = Process()
        say.executableURL = URL(filePath: "/usr/bin/say")
        say.arguments = ["-o", aiff.path, "The quick brown fox jumps over the lazy dog near the river bank."]
        try say.run()
        say.waitUntilExit()
        try #require(say.terminationStatus == 0)

        let duration = try await AudioConverting.convertToMono24kWAV(input: aiff, output: wav)

        #expect(duration > 2.0)
        let (samples, sampleRate) = try await AudioConverting.readMonoFloat(url: wav)
        #expect(sampleRate == 24_000)
        #expect(rms(samples) > 0.001)
    }

    @Test func rejectsEmptyInput() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = dir.appending(path: "empty.wav")
        let output = dir.appending(path: "converted.wav")
        let format = try #require(AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48_000,
            channels: 1,
            interleaved: false))
        let file = try AVAudioFile(forWriting: source, settings: format.settings)
        file.close()

        await #expect(throws: AudioConverting.ConversionError.self) {
            try await AudioConverting.convertToMono24kWAV(input: source, output: output)
        }
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test func committingPreparedReferenceReplacesExistingFile() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let staging = dir.appending(path: "staging.wav")
        let destination = dir.appending(path: "reference.wav")
        try Data("old".utf8).write(to: destination)
        try Data("new".utf8).write(to: staging)

        try SessionFiles.commitPreparedReference(at: staging, to: destination)

        #expect(try Data(contentsOf: destination) == Data("new".utf8))
        #expect(!FileManager.default.fileExists(atPath: staging.path))
    }

    @Test func exportWriterRejectsInvalidClipsBeforeTouchingDestination() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let destination = dir.appending(path: "voice.wav")
        let original = Data("existing audio".utf8)
        try original.write(to: destination)

        for invalidClip in [
            clip(samples: []),
            clip(sampleRate: 0),
            clip(samples: [0, .nan]),
            clip(samples: [0, .infinity]),
        ] {
            await #expect(throws: Error.self) {
                try await AudioExporter.write(clip: invalidClip, format: .wav, to: destination)
            }
            #expect(try Data(contentsOf: destination) == original)
        }
    }

    @Test func exportWriterPublishesWAVAtomicallyAndPreservesFidelity() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let destination = dir.appending(path: "voice.wav")
        try Data("old".utf8).write(to: destination)
        let input = sine(frequency: 880, seconds: 0.25, sampleRate: 24_000)

        try await AudioExporter.write(
            clip: clip(samples: input, sampleRate: 24_000),
            format: .wav,
            to: destination)

        let (output, sampleRate) = try await AudioConverting.readMonoFloat(url: destination)
        #expect(sampleRate == 24_000)
        #expect(output.count == input.count)
        #expect(zip(output, input).allSatisfy { abs($0 - $1) < 0.000001 })
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path).allSatisfy {
            !$0.contains(".partial")
        })
    }

    @Test func exportWriterPublishesReadableDurationPreservingM4A() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let destination = dir.appending(path: "voice.m4a")
        let input = sine(frequency: 330, seconds: 1.0, sampleRate: 24_000)

        try await AudioExporter.write(
            clip: clip(samples: input, sampleRate: 24_000),
            format: .m4a,
            to: destination)

        let (decoded, sampleRate) = try await AudioConverting.readMonoFloat(url: destination)
        #expect(sampleRate == 24_000)
        #expect(decoded.contains(where: { $0.isFinite && abs($0) > 0.0001 }))
        let sourceDuration = Double(input.count) / 24_000.0
        let decodedDuration = Double(decoded.count) / Double(sampleRate)
        #expect(abs(decodedDuration - sourceDuration) <= sourceDuration * 0.05)
    }

    @Test func pipelineExportClipRequiresCurrentCompletedEffect() throws {
        let pipeline = try source("App/Model/PipelineState.swift")

        #expect(pipeline.contains("private(set) var alteredEffect"))
        #expect(pipeline.contains("if effect.isIdentity { return synthesis }"))
        #expect(pipeline.contains("guard !isAltering, alteredEffect == effect else { return nil }"))
        #expect(pipeline.contains("alteredEffect = parameters"))
        #expect(pipeline.contains("alteredEffect = nil"))
        #expect(pipeline.contains("bypassEffect ? synthesis"))
    }

    @Test func exportSourceContractsKeepPanelWriterAndRevealStateSeparate() throws {
        let exporter = try source("App/Export/AudioExporter.swift")
        let view = try source("App/Views/ExportStageView.swift")

        #expect(exporter.contains("static func write("))
        #expect(exporter.contains("NSSavePanel"))
        #expect(exporter.contains("return nil"))
        #expect(view.contains("isExporting"))
        #expect(view.contains("exportedURL = savedURL"))
        #expect(!view.contains("exportedURL = try await AudioExporter.export"))
        #expect(view.contains("activateFileViewerSelecting"))
    }
}
