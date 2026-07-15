import AVFoundation
import Observation

@MainActor
protocol AudioPlaybackBackend: AnyObject {
    var duration: TimeInterval { get }
    var currentTime: TimeInterval { get }
    var isPlaying: Bool { get }

    func play() -> Bool
    func stop()
}

extension AVAudioPlayer: AudioPlaybackBackend {}

nonisolated enum AudioPlayerError: LocalizedError {
    case couldNotOpen(String)
    case couldNotStart

    var errorDescription: String? {
        switch self {
        case .couldNotOpen(let detail):
            "Could not open audio for playback: \(detail)"
        case .couldNotStart:
            "Could not start audio playback."
        }
    }
}

/// One shared playback slot for the whole pipeline, so the play buttons of the
/// different stages are mutually exclusive by construction.
@Observable
@MainActor
final class AudioPlayer {
    typealias BackendFactory = (URL) throws -> any AudioPlaybackBackend

    private let makePlayer: BackendFactory
    private var player: (any AudioPlaybackBackend)?
    private var pollTask: Task<Void, Never>?

    private(set) var currentURL: URL?
    private(set) var isPlaying = false
    private(set) var progress: Double = 0

    init(makePlayer: @escaping BackendFactory = { try AVAudioPlayer(contentsOf: $0) }) {
        self.makePlayer = makePlayer
    }

    /// Starts playing `url`, or stops if that URL is already playing.
    func toggle(url: URL) throws {
        if isPlaying, currentURL == url {
            stop()
            return
        }

        stop()
        let newPlayer: any AudioPlaybackBackend
        do {
            newPlayer = try makePlayer(url)
        } catch {
            throw AudioPlayerError.couldNotOpen(error.localizedDescription)
        }
        guard newPlayer.play() else {
            newPlayer.stop()
            throw AudioPlayerError.couldNotStart
        }

        player = newPlayer
        currentURL = url
        isPlaying = true

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch {
                    break
                }
                guard let self else { break }
                self.refreshProgress()
                guard self.isPlaying else { break }
            }
        }
    }

    func refreshProgress() {
        guard let player else { return }
        let next = Self.normalizedProgress(
            currentTime: player.currentTime,
            duration: player.duration)
        progress = max(progress, next)
        guard !player.isPlaying else { return }
        if next == 1 {
            completeNaturally()
        } else {
            stop()
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        player?.stop()
        player = nil
        currentURL = nil
        isPlaying = false
        progress = 0
    }

    static func normalizedProgress(currentTime: TimeInterval, duration: TimeInterval) -> Double {
        guard currentTime.isFinite, duration.isFinite, duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    private func completeNaturally() {
        pollTask?.cancel()
        pollTask = nil
        player = nil
        isPlaying = false
        progress = 1
    }
}
