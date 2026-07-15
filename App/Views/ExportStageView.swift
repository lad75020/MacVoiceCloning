import SwiftUI

struct ExportStageView: View {
    @Environment(AppModel.self) private var model
    @State private var format: AudioExporter.Format = .wav
    @State private var exportedURL: URL?
    @State private var isExporting = false

    var body: some View {
        let pipeline = model.pipeline
        let canExport = pipeline.exportClip != nil && !isExporting

        StageCard(number: 5, title: "Download the final voice") {
            HStack(spacing: 12) {
                Picker("Format", selection: $format) {
                    ForEach(AudioExporter.Format.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .frame(maxWidth: 180)
                .disabled(!canExport)

                Button {
                    Task { await export() }
                } label: {
                    Label("Save As…", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canExport)

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

            Text(exportDescription(for: pipeline))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func export() async {
        guard !isExporting, let clip = model.pipeline.exportClip else { return }
        isExporting = true
        defer { isExporting = false }
        model.player.stop()
        do {
            let savedURL = try await AudioExporter.export(
                clip: AudioExporter.Clip(samples: clip.samples, sampleRate: clip.sampleRate),
                format: format,
                suggestedName: "cloned-voice")
            if let savedURL {
                exportedURL = savedURL
            }
        } catch {
            model.pipeline.lastError = error.localizedDescription
        }
    }

    private func exportDescription(for pipeline: PipelineState) -> String {
        guard let exportClip = pipeline.exportClip else {
            return "Export will be available when the current voice is ready."
        }
        return exportClip.url == SessionFiles.alteredWAV
            ? "Exports the altered voice."
            : "Exports the synthesized voice."
    }
}
