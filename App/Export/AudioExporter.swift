import AppKit
import UniformTypeIdentifiers

nonisolated enum AudioExporter {
    struct Clip: Equatable, Sendable {
        var samples: [Float]
        var sampleRate: Int
    }

    enum Format: String, CaseIterable, Identifiable {
        case wav
        case m4a

        var id: String { rawValue }
        var displayName: String { rawValue.uppercased() }
        var contentType: UTType { self == .wav ? .wav : .mpeg4Audio }
        var fileExtension: String { rawValue }
    }

    enum ExportError: LocalizedError, Equatable {
        case emptyClip
        case invalidSampleRate(Int)
        case nonFiniteSamples
        case nonLocalDestination

        var errorDescription: String? {
            switch self {
            case .emptyClip:
                "Export failed because the current voice has no audio samples."
            case .invalidSampleRate(let sampleRate):
                "Export failed because the current voice has an invalid sample rate of \(sampleRate) Hz."
            case .nonFiniteSamples:
                "Export failed because the current voice contains invalid audio samples."
            case .nonLocalDestination:
                "Export failed because the selected destination is not a local file."
            }
        }
    }

    /// Shows a save panel and writes the clip. Returns the saved URL, or nil when
    /// the user cancelled.
    @MainActor
    static func export(
        clip: Clip,
        format: Format,
        suggestedName: String
    ) async throws -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(suggestedName).\(format.fileExtension)"
        panel.title = "Export Voice"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        try await write(clip: clip, format: format, to: url)
        return url
    }

    /// Writes a validated clip to a unique sibling staging file, then publishes it
    /// to the selected destination only after encoding succeeds.
    static func write(
        clip: Clip,
        format: Format,
        to destination: URL
    ) async throws {
        try validate(clip: clip, destination: destination)

        let staging = stagingURL(for: destination, format: format)
        defer { try? FileManager.default.removeItem(at: staging) }

        switch format {
        case .wav:
            try await AudioConverting.writeWAV(
                samples: clip.samples, sampleRate: clip.sampleRate, to: staging)
        case .m4a:
            try await AudioConverting.writeM4A(
                samples: clip.samples, sampleRate: clip.sampleRate, to: staging)
        }

        try publish(staging: staging, to: destination)
    }

    private static func validate(clip: Clip, destination: URL) throws {
        guard destination.isFileURL else { throw ExportError.nonLocalDestination }
        guard !clip.samples.isEmpty else { throw ExportError.emptyClip }
        guard clip.sampleRate > 0 else { throw ExportError.invalidSampleRate(clip.sampleRate) }
        guard clip.samples.allSatisfy(\.isFinite) else { throw ExportError.nonFiniteSamples }
    }

    private static func stagingURL(for destination: URL, format: Format) -> URL {
        let directory = destination.deletingLastPathComponent()
        let baseName = destination.deletingPathExtension().lastPathComponent
        return directory.appending(
            path: ".\(baseName)-\(UUID().uuidString).partial.\(format.fileExtension)")
    }

    private static func publish(staging: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destination.path) {
            _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
        } else {
            try fileManager.moveItem(at: staging, to: destination)
        }
    }
}
