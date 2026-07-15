import AVFoundation

/// Stateless audio file conversion helpers. All heavy functions are `@concurrent`
/// so they run off the main actor.
nonisolated enum AudioConverting {
    enum ConversionError: LocalizedError {
        case unreadable(URL)
        case converterUnavailable
        case conversionFailed(String)

        var errorDescription: String? {
            switch self {
            case .unreadable(let url): "Can't read audio file \(url.lastPathComponent)."
            case .converterUnavailable: "Audio converter could not be created."
            case .conversionFailed(let detail): "Audio conversion failed: \(detail)"
            }
        }
    }

    /// Converts any readable audio file to a 24 kHz mono Float32 WAV (the reference
    /// format Qwen3-TTS requires). Returns the output duration in seconds.
    @concurrent
    @discardableResult
    static func convertToMono24kWAV(input: URL, output: URL) async throws -> TimeInterval {
        let inFile = try AVAudioFile(forReading: input)
        let inFormat = inFile.processingFormat

        guard let outFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false
        ) else { throw ConversionError.converterUnavailable }

        guard let converter = AVAudioConverter(from: inFormat, to: outFormat) else {
            throw ConversionError.converterUnavailable
        }
        converter.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Mastering
        converter.sampleRateConverterQuality = AVAudioQuality.max.rawValue
        converter.downmix = true

        try? FileManager.default.removeItem(at: output)
        let outFile = try AVAudioFile(forWriting: output, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 24_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
        ], commonFormat: .pcmFormatFloat32, interleaved: false)

        let readCapacity: AVAudioFrameCount = 16_384
        guard let inBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: readCapacity),
              let outBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: readCapacity)
        else { throw ConversionError.converterUnavailable }

        var reachedEnd = false
        var wroteFrames: Int64 = 0
        while true {
            var readError: Error?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                if reachedEnd {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                do {
                    inBuffer.frameLength = 0
                    try inFile.read(into: inBuffer, frameCount: readCapacity)
                } catch {
                    readError = error
                    outStatus.pointee = .endOfStream
                    return nil
                }
                if inBuffer.frameLength == 0 {
                    reachedEnd = true
                    outStatus.pointee = .endOfStream
                    return nil
                }
                outStatus.pointee = .haveData
                return inBuffer
            }

            outBuffer.frameLength = 0
            var conversionError: NSError?
            let status = converter.convert(to: outBuffer, error: &conversionError, withInputFrom: inputBlock)
            if let readError { throw readError }
            if let conversionError { throw ConversionError.conversionFailed(conversionError.localizedDescription) }

            if outBuffer.frameLength > 0 {
                try outFile.write(from: outBuffer)
                wroteFrames += Int64(outBuffer.frameLength)
            }
            if status == .endOfStream || status == .error { break }
        }

        return TimeInterval(wroteFrames) / 24_000.0
    }

    /// Reads an audio file's first channel as Float32 samples at its native rate.
    @concurrent
    static func readMonoFloat(url: URL) async throws -> (samples: [Float], sampleRate: Int) {
        let file = try AVAudioFile(forReading: url)
        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount)
        else { throw ConversionError.unreadable(url) }
        try file.read(into: buffer)
        guard let channels = buffer.floatChannelData else { throw ConversionError.unreadable(url) }
        let samples = Array(UnsafeBufferPointer(start: channels[0], count: Int(buffer.frameLength)))
        return (samples, Int(file.processingFormat.sampleRate))
    }

    /// Writes mono Float32 samples as a WAV file.
    @concurrent
    static func writeWAV(samples: [Float], sampleRate: Int, to url: URL) async throws {
        try? FileManager.default.removeItem(at: url)
        let file = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
        ], commonFormat: .pcmFormatFloat32, interleaved: false)
        try write(samples: samples, sampleRate: sampleRate, to: file)
    }

    /// Writes mono Float32 samples as an AAC .m4a file.
    @concurrent
    static func writeM4A(samples: [Float], sampleRate: Int, to url: URL, bitRate: Int = 128_000) async throws {
        try? FileManager.default.removeItem(at: url)
        let file = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: bitRate,
        ], commonFormat: .pcmFormatFloat32, interleaved: false)
        try write(samples: samples, sampleRate: sampleRate, to: file)
    }

    private static func write(samples: [Float], sampleRate: Int, to file: AVAudioFile) throws {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32, sampleRate: Double(sampleRate), channels: 1, interleaved: false
        ), let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(max(samples.count, 1)))
        else { throw ConversionError.converterUnavailable }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            buffer.floatChannelData![0].update(from: source.baseAddress!, count: samples.count)
        }
        try file.write(from: buffer)
    }

    static func duration(of url: URL) throws -> TimeInterval {
        let file = try AVAudioFile(forReading: url)
        return TimeInterval(file.length) / file.processingFormat.sampleRate
    }
}
