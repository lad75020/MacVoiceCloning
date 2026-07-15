import Foundation
import Hub

/// Downloads the Qwen3-TTS Base model snapshot from Hugging Face into the app's
/// models directory. `HubApi.snapshot` verifies and resumes, so retrying after a
/// failure is simply calling `download` again.
nonisolated struct ModelDownloader: Sendable {
    static let repoID = "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-bf16"
    static let approximateDownloadGB = 3.5

    let modelsRoot: URL

    private var hub: HubApi { HubApi(downloadBase: modelsRoot) }
    private var repo: Hub.Repo { Hub.Repo(id: Self.repoID) }

    var modelDirectory: URL { hub.localRepoLocation(repo) }

    /// Marker written only after a snapshot call returned successfully, so a
    /// half-finished download is never mistaken for a usable model.
    private var completionMarker: URL { modelDirectory.appending(path: ".download-complete") }

    var isDownloadComplete: Bool {
        FileManager.default.fileExists(atPath: completionMarker.path)
    }

    @discardableResult
    func download(progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let directory = try await hub.snapshot(
            from: repo,
            matching: ["*.json", "*.safetensors", "*.txt"]
        ) { snapshotProgress in
            progress(snapshotProgress.fractionCompleted)
        }
        FileManager.default.createFile(atPath: completionMarker.path, contents: Data())
        return directory
    }
}
