import Foundation
import Testing

struct RubberBandProcessorTests {
    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func sine(frequency: Double = 440, seconds: Double = 2.0, sampleRate: Int = 24_000) -> [Float] {
        let count = Int(Double(sampleRate) * seconds)
        return (0..<count).map { 0.5 * Float(sin(2 * .pi * frequency * Double($0) / Double(sampleRate))) }
    }

    private func zeroCrossings(_ samples: [Float]) -> Int {
        var count = 0
        for i in 1..<samples.count where (samples[i - 1] < 0) != (samples[i] < 0) {
            count += 1
        }
        return count
    }

    private func source(_ relativePath: String) throws -> String {
        try String(contentsOf: projectRoot.appending(path: relativePath), encoding: .utf8)
    }

    @Test func validationRejectsInvalidSampleRateAndParameters() async throws {
        for sampleRate in [0, -24_000] {
            do {
                _ = try await RubberBandProcessor.process(
                    samples: [0, 0.1, -0.1],
                    sampleRate: sampleRate,
                    parameters: VoiceEffectParameters())
                Issue.record("Expected sample rate \(sampleRate) to fail before processing")
            } catch {
                #expect(error.localizedDescription.localizedCaseInsensitiveContains("sample rate"))
            }
        }

        let invalidParameters: [(VoiceEffectParameters, String)] = [
            (.init(pitchSemitones: .nan), "pitch"),
            (.init(pitchSemitones: 13), "pitch"),
            (.init(speed: .infinity), "speed"),
            (.init(speed: 0.49), "speed"),
            (.init(formantScale: .nan), "formant"),
            (.init(formantScale: 2.01), "formant"),
        ]

        for (parameters, expectedMessage) in invalidParameters {
            do {
                _ = try await RubberBandProcessor.process(
                    samples: [0, 0.1, -0.1],
                    sampleRate: 24_000,
                    parameters: parameters)
                Issue.record("Expected invalid \(expectedMessage) parameters to fail before processing")
            } catch {
                #expect(error.localizedDescription.localizedCaseInsensitiveContains(expectedMessage))
            }
        }
    }

    @Test func parameterConversionsAndEngineSemanticsAreExplicit() throws {
        let r3 = VoiceEffectParameters(pitchSemitones: 12, speed: 0.5, formantScale: 1.4)
        try r3.validate(sampleRate: 24_000)

        #expect(abs(r3.pitchScale - 2.0) < 0.0001)
        #expect(abs(r3.timeRatio - 2.0) < 0.0001)
        #expect(r3.applicableFormantScale == 1.4)
        #expect(!r3.isIdentity)

        var r2 = r3
        r2.engine = .r2Faster
        try r2.validate(sampleRate: 24_000)

        #expect(r2.formantScale == 1.4, "R2 must retain the selected timbre value")
        #expect(r2.applicableFormantScale == 1.0, "R2 must ignore independent formant scaling")
    }

    @Test func presetsAreCompleteValidUniqueConfigurationsAndResetIsIdentity() throws {
        #expect(!VoiceEffectParameters.presets.isEmpty)
        #expect(Set(VoiceEffectParameters.presets.map(\.name)).count == VoiceEffectParameters.presets.count)

        for preset in VoiceEffectParameters.presets {
            #expect(!preset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            try preset.parameters.validate(sampleRate: 24_000)
            #expect(preset.parameters.speed >= 0.5 && preset.parameters.speed <= 2.0)
            #expect(preset.parameters.pitchSemitones.rounded() == preset.parameters.pitchSemitones)
        }

        #expect(VoiceEffectParameters().isIdentity)
        try VoiceEffectParameters().validate(sampleRate: 24_000)
    }

    @Test func halfSpeedDoublesLength() async throws {
        let input = sine()
        var parameters = VoiceEffectParameters()
        parameters.speed = 0.5

        let output = try await RubberBandProcessor.process(
            samples: input, sampleRate: 24_000, parameters: parameters)

        let ratio = Double(output.count) / Double(input.count)
        #expect(abs(ratio - 2.0) < 0.1, "time ratio 2.0 should roughly double the length, got \(ratio)")
        #expect(output.allSatisfy { $0.isFinite })
    }

    @Test func octaveUpDoublesFrequency() async throws {
        let input = sine()
        var parameters = VoiceEffectParameters()
        parameters.pitchSemitones = 12
        parameters.preserveFormants = false

        let output = try await RubberBandProcessor.process(
            samples: input, sampleRate: 24_000, parameters: parameters)

        let lengthRatio = Double(output.count) / Double(input.count)
        #expect(abs(lengthRatio - 1.0) < 0.05, "pitch shift should keep duration, got \(lengthRatio)")

        // Compare zero-crossing rates over the middle of each signal to avoid edge ramps.
        let inputMiddle = Array(input[input.count / 4 ..< 3 * input.count / 4])
        let outputMiddle = Array(output[output.count / 4 ..< 3 * output.count / 4])
        let inputRate = Double(zeroCrossings(inputMiddle)) / Double(inputMiddle.count)
        let outputRate = Double(zeroCrossings(outputMiddle)) / Double(outputMiddle.count)
        let frequencyRatio = outputRate / inputRate
        #expect(abs(frequencyRatio - 2.0) < 0.2, "octave up should double zero-crossing rate, got \(frequencyRatio)")
    }

    @Test func identityParametersUseExactFastPath() async throws {
        let input = sine(seconds: 1.0)
        let output = try await RubberBandProcessor.process(
            samples: input, sampleRate: 24_000, parameters: VoiceEffectParameters())

        #expect(output == input)
    }

    @Test func emptyInputReturnsEmptyWithoutValidatingProcessingState() async throws {
        let output = try await RubberBandProcessor.process(
            samples: [], sampleRate: 24_000, parameters: VoiceEffectParameters())

        #expect(output.isEmpty)
    }

    @Test func cancellationStopsOfflineProcessing() async throws {
        let input = sine(seconds: 30.0)
        var parameters = VoiceEffectParameters()
        parameters.speed = 0.5

        let task = Task {
            try await RubberBandProcessor.process(
                samples: input, sampleRate: 24_000, parameters: parameters)
        }
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected cancellation to be observed during offline processing")
        } catch is CancellationError {
            #expect(true)
        }
    }

    @Test func r2EngineProcesses() async throws {
        let input = sine(seconds: 1.0)
        var parameters = VoiceEffectParameters()
        parameters.engine = .r2Faster
        parameters.pitchSemitones = -5

        let output = try await RubberBandProcessor.process(
            samples: input, sampleRate: 24_000, parameters: parameters)

        #expect(!output.isEmpty)
        #expect(output.allSatisfy { $0.isFinite })
    }

    @Test func r2RetainsButDoesNotApplyIndependentFormantScale() async throws {
        let input = sine(seconds: 1.0)
        var r2 = VoiceEffectParameters()
        r2.engine = .r2Faster
        r2.formantScale = 1.7
        r2.pitchSemitones = -3

        let output = try await RubberBandProcessor.process(
            samples: input, sampleRate: 24_000, parameters: r2)

        #expect(r2.formantScale == 1.7)
        #expect(r2.applicableFormantScale == 1.0)
        #expect(!output.isEmpty)
        #expect(output.allSatisfy { $0.isFinite })
    }

    @Test func alterationRevisionGateRejectsStaleRequests() {
        var gate = AlterationRevisionGate()
        let first = gate.advance()
        #expect(gate.isCurrent(first))

        let second = gate.advance()
        #expect(!gate.isCurrent(first))
        #expect(gate.isCurrent(second))
    }

    @Test func sessionFilesProvideUniqueStagingAndAtomicAlteredCommit() throws {
        let firstStaging = SessionFiles.alteredStagingURL(revision: 7)
        let secondStaging = SessionFiles.alteredStagingURL(revision: 7)
        #expect(firstStaging != secondStaging)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacVoiceCloningTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let destination = root.appendingPathComponent("altered.wav")
        let firstPrepared = root.appendingPathComponent("first.partial")
        try Data("first".utf8).write(to: firstPrepared)
        try SessionFiles.commitPreparedAltered(at: firstPrepared, to: destination)
        #expect(try Data(contentsOf: destination) == Data("first".utf8))

        let replacementPrepared = root.appendingPathComponent("replacement.partial")
        try Data("replacement".utf8).write(to: replacementPrepared)
        try SessionFiles.commitPreparedAltered(at: replacementPrepared, to: destination)
        #expect(try Data(contentsOf: destination) == Data("replacement".utf8))
    }

    @Test func pipelineSourceGuardsLatestAlterationAndRetainsPriorPreview() throws {
        let pipeline = try source("App/Model/PipelineState.swift")

        #expect(pipeline.contains("AlterationRevisionGate"))
        #expect(pipeline.contains("alterationRevision.advance()"))
        #expect(pipeline.contains("capturedRevision"))
        #expect(pipeline.contains("guard alterationRevision.isCurrent(capturedRevision)"))
        #expect(pipeline.contains("alteredStagingURL"))
        #expect(pipeline.contains("commitPreparedAltered"))
        #expect(pipeline.contains("lastError = nil"))
        #expect(!pipeline.contains("guard !effect.isIdentity else {\n            altered = nil"))
    }

    @Test func pipelineSourceKeepsBypassIndependentFromProcessing() throws {
        let pipeline = try source("App/Model/PipelineState.swift")
        let view = try source("App/Views/AlterStageView.swift")

        #expect(pipeline.contains("bypassEffect ? synthesis"))
        #expect(pipeline.contains("effect.isIdentity ? synthesis"))
        #expect(!view.contains("onChange(of: pipeline.bypassEffect) {\n            model.player.stop()\n            pipeline.scheduleAlteration"))
        #expect(!view.contains("onChange(of: pipeline.bypassEffect) {\n            model.player.stop()\n            pipeline.alterationTask?.cancel"))
    }
}
