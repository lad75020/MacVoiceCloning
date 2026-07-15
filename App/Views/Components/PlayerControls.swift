import SwiftUI

/// Play/stop button bound to the app's single shared player.
struct PlayerControls: View {
    @Environment(AppModel.self) private var model

    let url: URL?
    var label = "Play"

    private var isSelected: Bool {
        url != nil && model.player.currentURL == url
    }

    private var isPlayingCurrent: Bool {
        isSelected && model.player.isPlaying
    }

    var body: some View {
        Button {
            if let url {
                do {
                    try model.player.toggle(url: url)
                } catch {
                    model.pipeline.lastError = error.localizedDescription
                }
            }
        } label: {
            Label(
                isPlayingCurrent ? "Stop" : label,
                systemImage: isPlayingCurrent ? "stop.fill" : "play.fill")
        }
        .disabled(url == nil)

        if isSelected {
            ProgressView(value: model.player.progress)
                .frame(width: 72)
                .accessibilityLabel("Playback progress")
                .accessibilityValue(
                    "\(Int((model.player.progress * 100).rounded())) percent")
        }
    }
}
