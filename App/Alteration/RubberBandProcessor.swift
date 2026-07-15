import Foundation

/// Offline (two-pass) Rubber Band processing of mono Float32 audio through the
/// vendored library's C API.
nonisolated enum RubberBandProcessor {
    enum ProcessorError: LocalizedError {
        case creationFailed
        case emptyOutput
        case nonFiniteOutput

        var errorDescription: String? {
            switch self {
            case .creationFailed: "The Rubber Band stretcher could not be created."
            case .emptyOutput: "Voice alteration produced no audio. Try a different effect setting."
            case .nonFiniteOutput: "Voice alteration produced invalid audio samples. Try a different effect setting."
            }
        }
    }

    private static let blockFrames = 16_384

    @concurrent
    static func process(
        samples: [Float],
        sampleRate: Int,
        parameters: VoiceEffectParameters
    ) async throws -> [Float] {
        try parameters.validate(sampleRate: sampleRate)
        guard !samples.isEmpty else { return samples }
        try Task.checkCancellation()
        guard !parameters.isIdentity else { return samples }

        var optionBits: UInt32 = RubberBandOptionProcessOffline.rawValue
            | RubberBandOptionPitchHighQuality.rawValue
        optionBits |= parameters.engine == .r3Finer
            ? RubberBandOptionEngineFiner.rawValue
            : RubberBandOptionEngineFaster.rawValue
        if parameters.preserveFormants {
            optionBits |= RubberBandOptionFormantPreserved.rawValue
        }

        guard let state = rubberband_new(
            UInt32(sampleRate), 1, RubberBandOptions(optionBits),
            parameters.timeRatio, parameters.pitchScale
        ) else { throw ProcessorError.creationFailed }
        defer { rubberband_delete(state) }

        let applicableFormantScale = parameters.applicableFormantScale
        if parameters.engine == .r3Finer, applicableFormantScale != 1.0 {
            rubberband_set_formant_scale(state, applicableFormantScale)
        }
        rubberband_set_expected_input_duration(state, UInt32(samples.count))
        rubberband_set_max_process_size(state, UInt32(blockFrames))

        // Pass 1: study the whole signal.
        try forEachBlock(of: samples) { pointer, count, isFinal in
            rubberband_study(state, pointer, count, isFinal)
        }

        // Pass 2: process and drain.
        var output: [Float] = []
        output.reserveCapacity(Int(Double(samples.count) * parameters.timeRatio) + blockFrames)
        var scratch = [Float](repeating: 0, count: blockFrames)

        try forEachBlock(of: samples) { pointer, count, isFinal in
            rubberband_process(state, pointer, count, isFinal)
            try drain(state, into: &output, scratch: &scratch)
        }
        try drain(state, into: &output, scratch: &scratch)

        guard !output.isEmpty else { throw ProcessorError.emptyOutput }
        guard output.allSatisfy(\.isFinite) else { throw ProcessorError.nonFiniteOutput }
        return output
    }

    /// Feeds `samples` to `body` in `blockFrames`-sized chunks as the
    /// pointer-to-channel-pointer layout the C API expects.
    private static func forEachBlock(
        of samples: [Float],
        _ body: (UnsafePointer<UnsafePointer<Float>?>, UInt32, Int32) throws -> Void
    ) throws {
        var offset = 0
        while offset < samples.count {
            try Task.checkCancellation()
            let count = min(blockFrames, samples.count - offset)
            let isFinal: Int32 = offset + count == samples.count ? 1 : 0
            try samples.withUnsafeBufferPointer { buffer in
                var channel: UnsafePointer<Float>? = buffer.baseAddress! + offset
                try withUnsafePointer(to: &channel) { channels in
                    try body(channels, UInt32(count), isFinal)
                }
            }
            offset += count
        }
    }

    private static func drain(_ state: RubberBandState?, into output: inout [Float], scratch: inout [Float]) throws {
        while true {
            try Task.checkCancellation()
            let available = rubberband_available(state)
            guard available > 0 else { break }
            let take = min(Int(available), scratch.count)
            let got = scratch.withUnsafeMutableBufferPointer { buffer -> UInt32 in
                var channel: UnsafeMutablePointer<Float>? = buffer.baseAddress
                return withUnsafePointer(to: &channel) { channels in
                    rubberband_retrieve(state, channels, UInt32(take))
                }
            }
            guard got > 0 else { break }
            output.append(contentsOf: scratch[0..<Int(got)])
        }
    }
}
