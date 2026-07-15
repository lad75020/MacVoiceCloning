import Foundation

/// Offline (two-pass) Rubber Band processing of mono Float32 audio through the
/// vendored library's C API.
nonisolated enum RubberBandProcessor {
    enum ProcessorError: LocalizedError {
        case creationFailed
        var errorDescription: String? {
            switch self {
            case .creationFailed: "The Rubber Band stretcher could not be created."
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
        guard !samples.isEmpty else { return samples }

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

        if parameters.engine == .r3Finer, parameters.formantScale != 1.0 {
            rubberband_set_formant_scale(state, parameters.formantScale)
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
            drain(state, into: &output, scratch: &scratch)
        }
        drain(state, into: &output, scratch: &scratch)

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

    private static func drain(_ state: RubberBandState?, into output: inout [Float], scratch: inout [Float]) {
        while true {
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
