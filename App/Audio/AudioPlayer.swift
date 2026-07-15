import AVFoundation
import Observation

/// One shared playback slot for the whole pipeline, so the play buttons of the
/// different stages are mutually exclusive by construction.
@Observable
@MainActor
final class AudioPlayer {
    private var player: AVAudioPlayer?
    private var pollTask: Task<Void, Never>?

    private(set) var currentURL: URL?
    private(set) var isPlaying = false
    private(set) var progress: Double = 0

    /// Starts playing `url`, or stops if that URL is already playing.
    func toggle(url: URL) {
        if isPlaying, currentURL == url {
            stop()
            return
        }
        stop()
        guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else { return }
        player = newPlayer
        currentURL = url
        newPlayer.play()
        isPlaying = true

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, let player = self.player else { break }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
                if !player.isPlaying {
                    self.stop()
                    break
                }
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
        currentURL = nil
    }
}
