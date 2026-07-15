import Foundation
import Hub

/// Downloads the Qwen3-TTS Base model snapshot from Hugging Face into the app's
/// models directory. `HubApi.snapshot` verifies and resumes, so retrying after a
/// failure is simply calling `download` again.
nonisolated struct ModelDownloader: Sendable {
    static let repoID = "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-bf16"
    static let approximateDownloadGB = 3.5

    /// The TTS repos ship vocab.json/merges.txt but no tokenizer.json, which
    /// swift-transformers' AutoTokenizer requires. Qwen/Qwen3-1.7B has a
    /// byte-identical text vocab (same git blob) and provides tokenizer.json.
    static let tokenizerFallbackRepoID = "Qwen/Qwen3-1.7B"

    let modelsRoot: URL

    private var hub: HubApi { HubApi(downloadBase: modelsRoot) }
    private var repo: Hub.Repo { Hub.Repo(id: Self.repoID) }

    var modelDirectory: URL { hub.localRepoLocation(repo) }

    /// Marker written only after a snapshot call returned successfully, so a
    /// half-finished download is never mistaken for a usable model.
    private var completionMarker: URL { modelDirectory.appending(path: ".download-complete") }

    var isDownloadComplete: Bool {
        FileManager.default.fileExists(atPath: completionMarker.path)
            && FileManager.default.fileExists(atPath: modelDirectory.appending(path: "tokenizer.json").path)
    }

    @discardableResult
    func download(progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let directory = try await hub.snapshot(
            from: repo,
            matching: ["*.json", "*.safetensors", "*.txt"]
        ) { snapshotProgress in
            progress(snapshotProgress.fractionCompleted)
        }
        try await ensureTokenizerJSON(in: directory)
        FileManager.default.createFile(atPath: completionMarker.path, contents: Data())
        return directory
    }

    private func ensureTokenizerJSON(in directory: URL) async throws {
        let target = directory.appending(path: "tokenizer.json")
        guard !FileManager.default.fileExists(atPath: target.path) else { return }
        let fallbackDirectory = try await hub.snapshot(
            from: Hub.Repo(id: Self.tokenizerFallbackRepoID),
            matching: ["tokenizer.json"])
        try FileManager.default.copyItem(
            at: fallbackDirectory.appending(path: "tokenizer.json"), to: target)
    }
}
