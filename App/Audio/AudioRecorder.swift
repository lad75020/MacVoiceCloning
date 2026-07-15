import AVFoundation
import Accelerate
import Observation
import os

/// Records the reference voice sample from the default input device into a raw
/// CAF file at the hardware format. The realtime tap writes to disk and updates a
/// lock-guarded stats box; a MainActor task polls the box for the level meter.
@Observable
@MainActor
final class AudioRecorder {
    enum State: Equatable {
        case idle
        case recording
    }

    static let minimumDuration: TimeInterval = 3.0

    private(set) var state: State = .idle
    /// 0…1 smoothed input level for the meter.
    private(set) var level: Float = 0
    private(set) var duration: TimeInterval = 0

    enum RecorderError: LocalizedError {
        case noInputDevice
        var errorDescription: String? {
            switch self {
            case .noInputDevice: "No usable microphone input was found."
            }
        }
    }

    /// Written from the realtime audio thread, read from the main actor.
    private final class TapBox: @unchecked Sendable {
        struct Stats {
            var rms: Float = 0
            var frames: Int64 = 0
            var error: (any Error)?
        }

        let file: AVAudioFile
        let sampleRate: Double
        let stats = OSAllocatedUnfairLock(initialState: Stats())

        init(file: AVAudioFile, sampleRate: Double) {
            self.file = file
            self.sampleRate = sampleRate
        }

        func ingest(_ buffer: AVAudioPCMBuffer) {
            var writeError: (any Error)?
            do {
                try file.write(from: buffer)
            } catch {
                writeError = error
            }
            var rms: Float = 0
            if let data = buffer.floatChannelData, buffer.frameLength > 0 {
                vDSP_rmsqv(data[0], 1, &rms, vDSP_Length(buffer.frameLength))
            }
            stats.withLock { s in
                s.rms = rms
                s.frames += Int64(buffer.frameLength)
                if s.error == nil { s.error = writeError }
            }
        }
    }

    private var engine: AVAudioEngine?
    private var tapBox: TapBox?
    private var pollTask: Task<Void, Never>?

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func start() throws {
        guard state != .recording else { return }
        try SessionFiles.prepareDirectories()

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw RecorderError.noInputDevice
        }

        try? FileManager.default.removeItem(at: SessionFiles.rawRecording)
        let file = try AVAudioFile(forWriting: SessionFiles.rawRecording, settings: format.settings)
        let box = TapBox(file: file, sampleRate: format.sampleRate)

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            box.ingest(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw error
        }

        self.engine = engine
        self.tapBox = box
        level = 0
        duration = 0
        state = .recording

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                guard let self, let box = self.tapBox else { break }
                let stats = box.stats.withLock { $0 }
                self.level = min(1, stats.rms * 6)
                self.duration = Double(stats.frames) / box.sampleRate
            }
        }
    }

    /// Stops recording. Returns the raw file URL and its duration, or nil when
    /// nothing usable was captured; a disk write error is thrown.
    func stop() throws -> (url: URL, duration: TimeInterval)? {
        guard state == .recording, let engine, let box = tapBox else { return nil }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        pollTask?.cancel()
        pollTask = nil
        box.file.close()

        let stats = box.stats.withLock { $0 }
        self.engine = nil
        self.tapBox = nil
        state = .idle
        level = 0
        duration = Double(stats.frames) / box.sampleRate

        if let error = stats.error { throw error }
        guard stats.frames > 0 else { return nil }
        return (SessionFiles.rawRecording, duration)
    }
}
