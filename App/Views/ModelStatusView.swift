import SwiftUI

/// Pinned status bar for model download/load state.
struct ModelStatusView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            trailingControls
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .contextMenu {
            Button("Reveal Model Folder in Finder") {
                model.modelManager.revealModelFolder()
            }
        }
    }

    private var indicatorColor: Color {
        switch model.modelManager.state {
        case .ready: .green
        case .failed: .red
        case .downloading, .loading: .yellow
        case .notDownloaded, .downloaded: .secondary.opacity(0.5)
        }
    }

    private var title: String {
        switch model.modelManager.state {
        case .notDownloaded: "Voice model not downloaded"
        case .downloading: "Downloading voice model…"
        case .downloaded: "Voice model downloaded"
        case .loading: "Loading voice model…"
        case .ready: "Voice model ready"
        case .failed: "Voice model problem"
        }
    }

    private var subtitle: String {
        switch model.modelManager.state {
        case .notDownloaded:
            "Qwen3-TTS Base (~\(ModelDownloader.approximateDownloadGB.formatted()) GB) — runs fully on this Mac"
        case .downloading(let fraction):
            "\(Int(fraction * 100)) % of ~\(ModelDownloader.approximateDownloadGB.formatted()) GB"
        case .downloaded:
            model.modelManager.modelName
        case .loading:
            "Bringing \(model.modelManager.modelName) into memory"
        case .ready:
            model.modelManager.modelName
        case .failed(let message):
            message
        }
    }

    @ViewBuilder
    private var trailingControls: some View {
        switch model.modelManager.state {
        case .notDownloaded:
            Button("Download") {
                Task { await model.modelManager.downloadAndLoad() }
            }
            .buttonStyle(.borderedProminent)
        case .downloading(let fraction):
            ProgressView(value: fraction)
                .frame(width: 160)
        case .downloaded:
            Button("Load") {
                Task { await model.modelManager.load() }
            }
            .buttonStyle(.borderedProminent)
        case .loading:
            ProgressView().controlSize(.small)
        case .ready:
            Button("Unload") {
                Task { await model.modelManager.unload() }
            }
        case .failed:
            Button("Retry") {
                Task { await model.modelManager.retry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
