import AppKit
import UniformTypeIdentifiers

@MainActor
enum AudioExporter {
    enum Format: String, CaseIterable, Identifiable {
        case wav
        case m4a

        var id: String { rawValue }
        var displayName: String { rawValue.uppercased() }
        var contentType: UTType { self == .wav ? .wav : .mpeg4Audio }
    }

    /// Shows a save panel and writes the clip. Returns the saved URL, or nil when
    /// the user cancelled.
    static func export(
        clip: PipelineState.AudioClip,
        format: Format,
        suggestedName: String
    ) async throws -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(suggestedName).\(format.rawValue)"
        panel.title = "Export Voice"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        switch format {
        case .wav:
            try await AudioConverting.writeWAV(samples: clip.samples, sampleRate: clip.sampleRate, to: url)
        case .m4a:
            try await AudioConverting.writeM4A(samples: clip.samples, sampleRate: clip.sampleRate, to: url)
        }
        return url
    }
}
