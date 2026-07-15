import Foundation
import Testing

@MainActor
struct AudioPlayerTests {
    @Test func switchesSourcesAndTogglesCurrentSourceOff() throws {
        let firstURL = URL(filePath: "/tmp/first.wav")
        let secondURL = URL(filePath: "/tmp/second.wav")
        let first = FakePlaybackBackend()
        let second = FakePlaybackBackend()
        let backends = [firstURL: first, secondURL: second]
        let player = AudioPlayer { try #require(backends[$0]) }

        try player.toggle(url: firstURL)
        #expect(player.currentURL == firstURL)
        #expect(player.isPlaying)

        try player.toggle(url: secondURL)
        #expect(first.stopCount == 1)
        #expect(player.currentURL == secondURL)
        #expect(player.isPlaying)

        try player.toggle(url: secondURL)
        #expect(second.stopCount == 1)
        #expect(player.currentURL == nil)
        #expect(!player.isPlaying)
        #expect(player.progress == 0)
    }

    @Test func rejectsOpenAndStartFailuresWithoutPublishingState() {
        let url = URL(filePath: "/tmp/unavailable.wav")
        let openFailure = AudioPlayer { _ in throw StubError.unavailable }

        #expect(throws: AudioPlayerError.self) {
            try openFailure.toggle(url: url)
        }
        #expect(openFailure.currentURL == nil)
        #expect(!openFailure.isPlaying)

        let backend = FakePlaybackBackend(playResult: false)
        let startFailure = AudioPlayer { _ in backend }
        #expect(throws: AudioPlayerError.self) {
            try startFailure.toggle(url: url)
        }
        #expect(backend.stopCount == 1)
        #expect(startFailure.currentURL == nil)
        #expect(!startFailure.isPlaying)
    }

    @Test func normalizesProgressIntoFiniteUnitRange() {
        #expect(AudioPlayer.normalizedProgress(currentTime: 5, duration: 10) == 0.5)
        #expect(AudioPlayer.normalizedProgress(currentTime: -1, duration: 10) == 0)
        #expect(AudioPlayer.normalizedProgress(currentTime: 12, duration: 10) == 1)
        #expect(AudioPlayer.normalizedProgress(currentTime: .nan, duration: 10) == 0)
        #expect(AudioPlayer.normalizedProgress(currentTime: 1, duration: .infinity) == 0)
        #expect(AudioPlayer.normalizedProgress(currentTime: 1, duration: 0) == 0)
    }

    @Test func pollsProgressAndRetainsNaturalCompletion() throws {
        let url = URL(filePath: "/tmp/completes.wav")
        let backend = FakePlaybackBackend(duration: 10, currentTime: 5)
        let player = AudioPlayer { _ in backend }

        try player.toggle(url: url)
        player.refreshProgress()
        #expect(player.progress == 0.5)

        backend.currentTime = 10
        backend.isPlaying = false
        player.refreshProgress()
        #expect(player.currentURL == url)
        #expect(!player.isPlaying)
        #expect(player.progress == 1)

        try player.toggle(url: url)
        #expect(player.isPlaying)
        #expect(player.progress == 0)
    }

    @Test func resetsStateWhenBackendStopsBeforeCompletion() throws {
        let url = URL(filePath: "/tmp/stops-early.wav")
        let backend = FakePlaybackBackend(duration: 10, currentTime: 4)
        let player = AudioPlayer { _ in backend }

        try player.toggle(url: url)
        backend.isPlaying = false
        player.refreshProgress()

        #expect(player.currentURL == nil)
        #expect(!player.isPlaying)
        #expect(player.progress == 0)
    }
}

@MainActor
private final class FakePlaybackBackend: AudioPlaybackBackend {
    var duration: TimeInterval
    var currentTime: TimeInterval
    var isPlaying = false
    var stopCount = 0

    private let playResult: Bool

    init(playResult: Bool = true, duration: TimeInterval = 10, currentTime: TimeInterval = 0) {
        self.playResult = playResult
        self.duration = duration
        self.currentTime = currentTime
    }

    func play() -> Bool {
        isPlaying = playResult
        return playResult
    }

    func stop() {
        stopCount += 1
        isPlaying = false
    }
}

private enum StubError: Error {
    case unavailable
}