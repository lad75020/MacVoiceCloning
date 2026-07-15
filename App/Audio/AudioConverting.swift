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

    /// Chunked file feed for AVAudioConverter's pull-model input block. The converter
    /// calls the block synchronously inside `convert`, so unchecked Sendable is safe.
    /// Note: `AVAudioFile.read(into:)` may return fewer frames than requested, which
    /// this feed handles naturally by reading chunk-by-chunk until zero frames remain.
    private final class ConverterFeed: @unchecked Sendable {
        private let file: AVAudioFile
        private let buffer: AVAudioPCMBuffer
        private(set) var readError: Error?
        private var finished = false

        init?(file: AVAudioFile, chunkFrames: AVAudioFrameCount) {
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat, frameCapacity: chunkFrames
            ) else { return nil }
            self.file = file
            self.buffer = buffer
        }

        func next() -> AVAudioPCMBuffer? {
            guard !finished, file.framePosition < file.length else {
                finished = true
                return nil
            }
            buffer.frameLength = 0
            do {
                try file.read(into: buffer)
            } catch {
                readError = error
                finished = true
                return nil
            }
            if buffer.frameLength == 0 {
                finished = true
                return nil
            }
            return buffer
        }
    }

    /// Converts any readable audio file to a 24 kHz mono Float32 WAV (the reference
    /// format Qwen3-TTS requires). Returns the output duration in seconds.
    @concurrent
    @discardableResult
    static func convertToMono24kWAV(input: URL, output: URL) async throws -> TimeInterval {
        let inFile = try AVAudioFile(forReading: input)
        let inFormat = inFile.processingFormat
        guard inFile.length > 0,
              let feed = ConverterFeed(file: inFile, chunkFrames: 32_768)
        else { throw ConversionError.unreadable(input) }

        guard let outFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false
        ), let converter = AVAudioConverter(from: inFormat, to: outFormat) else {
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

        let chunk: AVAudioFrameCount = 16_384
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: chunk) else {
            throw ConversionError.converterUnavailable
        }

        var wroteFrames: Int64 = 0
        while true {
            outBuffer.frameLength = 0
            var conversionError: NSError?
            let status = converter.convert(to: outBuffer, error: &conversionError) { _, outStatus in
                if let chunk = feed.next() {
                    outStatus.pointee = .haveData
                    return chunk
                }
                outStatus.pointee = .endOfStream
                return nil
            }
            if let readError = feed.readError { throw readError }
            if let conversionError {
                throw ConversionError.conversionFailed(conversionError.localizedDescription)
            }
            if outBuffer.frameLength > 0 {
                try outFile.write(from: outBuffer)
                wroteFrames += Int64(outBuffer.frameLength)
            }
            if status == .endOfStream || status == .error { break }
            if status == .inputRanDry && outBuffer.frameLength == 0 { break }
        }
        outFile.close()

        return TimeInterval(wroteFrames) / 24_000.0
    }

    /// Reads an audio file's first channel as Float32 samples at its native rate.
    /// Loops until exhaustion because `AVAudioFile.read(into:)` may return short reads.
    @concurrent
    static func readMonoFloat(url: URL) async throws -> (samples: [Float], sampleRate: Int) {
        let file = try AVAudioFile(forReading: url)
        guard file.length > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 32_768)
        else { throw ConversionError.unreadable(url) }

        var samples: [Float] = []
        samples.reserveCapacity(Int(file.length))
        while file.framePosition < file.length {
            buffer.frameLength = 0
            try file.read(into: buffer)
            if buffer.frameLength == 0 { break }
            guard let channels = buffer.floatChannelData else { throw ConversionError.unreadable(url) }
            samples.append(contentsOf: UnsafeBufferPointer(start: channels[0], count: Int(buffer.frameLength)))
        }
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

    /// Writes mono Float32 samples as an AAC .m4a file. The encoder picks the
    /// bitrate for the sample rate/channel count (an explicit bitrate that doesn't
    /// suit 24 kHz mono makes AudioConverter reject the settings).
    @concurrent
    static func writeM4A(samples: [Float], sampleRate: Int, to url: URL) async throws {
        try? FileManager.default.removeItem(at: url)
        let file = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
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
        file.close()
    }

    static func duration(of url: URL) throws -> TimeInterval {
        let file = try AVAudioFile(forReading: url)
        return TimeInterval(file.length) / file.processingFormat.sampleRate
    }
}
