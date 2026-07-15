import SwiftUI

/// Play/stop button bound to the app's single shared player.
struct PlayerControls: View {
    @Environment(AppModel.self) private var model

    let url: URL?
    var label = "Play"

    private var isCurrent: Bool {
        url != nil && model.player.currentURL == url && model.player.isPlaying
    }

    var body: some View {
        Button {
            if let url {
                model.player.toggle(url: url)
            }
        } label: {
            Label(isCurrent ? "Stop" : label, systemImage: isCurrent ? "stop.fill" : "play.fill")
        }
        .disabled(url == nil)
    }
}
