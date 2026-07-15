import SwiftUI

struct ExportStageView: View {
    @Environment(AppModel.self) private var model
    @State private var format: AudioExporter.Format = .wav
    @State private var exportedURL: URL?

    var body: some View {
        let pipeline = model.pipeline

        StageCard(number: 5, title: "Download the final voice") {
            HStack(spacing: 12) {
                Picker("Format", selection: $format) {
                    ForEach(AudioExporter.Format.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .frame(maxWidth: 180)

                Button {
                    Task { await export() }
                } label: {
                    Label("Save As…", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(pipeline.exportClip == nil)

                if let exportedURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([exportedURL])
                    } label: {
                        Label(exportedURL.lastPathComponent, systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.link)
                }

                Spacer()
            }

            Text(pipeline.altered != nil
                 ? "Exports the altered voice."
                 : "Exports the synthesized voice (no alteration active).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .disabled(pipeline.exportClip == nil)
    }

    private func export() async {
        guard let clip = model.pipeline.exportClip else { return }
        model.player.stop()
        do {
            exportedURL = try await AudioExporter.export(
                clip: clip, format: format, suggestedName: "cloned-voice")
        } catch {
            model.pipeline.lastError = error.localizedDescription
        }
    }
}
