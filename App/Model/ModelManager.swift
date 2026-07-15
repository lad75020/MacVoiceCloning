import AppKit
import Foundation
import Observation
import Synchronization

/// Owns the model lifecycle: download → load → ready, plus the engine instance.
/// Generation busy-ness lives in PipelineState; this type only tracks model
/// availability.
@Observable
@MainActor
final class ModelManager {
    enum State: Equatable {
        case notDownloaded
        case downloading(Double)
        case downloaded
        case loading
        case ready
        case failed(String)
    }

    private(set) var state: State = .notDownloaded
    private(set) var engine: (any TTSEngine)?

    private let downloader = ModelDownloader(modelsRoot: SessionFiles.modelsRoot)

    var modelName: String { ModelDownloader.repoID }

    func refreshOnLaunch() {
        state = downloader.isDownloadComplete ? .downloaded : .notDownloaded
    }

    func downloadAndLoad() async {
        do {
            try SessionFiles.prepareDirectories()
            state = .downloading(0)
            // Throttle: HubApi reports progress very frequently.
            let lastShown = Mutex(-1.0)
            let directory = try await downloader.download { fraction in
                let shouldForward = lastShown.withLock { last in
                    guard fraction - last >= 0.005 || fraction >= 1.0 else { return false }
                    last = fraction
                    return true
                }
                guard shouldForward else { return }
                Task { @MainActor [weak self] in
                    if case .downloading = self?.state {
                        self?.state = .downloading(fraction)
                    }
                }
            }
            state = .downloaded
            await load(directory: directory)
        } catch {
            state = .failed("Download failed: \(error.localizedDescription)")
        }
    }

    func load(directory: URL? = nil) async {
        guard state != .loading, state != .ready else { return }
        state = .loading
        do {
            let engine = QwenTTSEngine(modelDirectory: directory ?? downloader.modelDirectory)
            try await engine.load()
            self.engine = engine
            state = .ready
        } catch {
            engine = nil
            state = .failed("Model load failed: \(error.localizedDescription)")
        }
    }

    /// Frees the ~4 GB of memory the loaded model occupies.
    func unload() async {
        await engine?.unload()
        engine = nil
        state = downloader.isDownloadComplete ? .downloaded : .notDownloaded
    }

    func retry() async {
        if downloader.isDownloadComplete {
            state = .downloaded
            await load()
        } else {
            await downloadAndLoad()
        }
    }

    func revealModelFolder() {
        let modelDirectory = downloader.modelDirectory
        let location = FileManager.default.fileExists(atPath: modelDirectory.path)
            ? modelDirectory
            : SessionFiles.modelsRoot
        NSWorkspace.shared.activateFileViewerSelecting([location])
    }
}
