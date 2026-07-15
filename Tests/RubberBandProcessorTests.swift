import Foundation
import Testing

struct RubberBandProcessorTests {
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

    @Test func identityParametersKeepLength() async throws {
        let input = sine(seconds: 1.0)
        let output = try await RubberBandProcessor.process(
            samples: input, sampleRate: 24_000, parameters: VoiceEffectParameters())

        let ratio = Double(output.count) / Double(input.count)
        #expect(abs(ratio - 1.0) < 0.02)
        #expect(output.allSatisfy { $0.isFinite })
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
}
