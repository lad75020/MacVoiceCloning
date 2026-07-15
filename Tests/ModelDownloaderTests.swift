import Foundation
import Testing

struct ModelDownloaderTests {
    private func makeDownloader() throws -> (root: URL, downloader: ModelDownloader) {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "mvc-model-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return (root, ModelDownloader(modelsRoot: root))
    }

    @Test func completenessRequiresTokenizerAndMarker() throws {
        let harness = try makeDownloader()
        defer { try? FileManager.default.removeItem(at: harness.root) }
        try FileManager.default.createDirectory(
            at: harness.downloader.modelDirectory,
            withIntermediateDirectories: true)

        let tokenizer = harness.downloader.modelDirectory.appending(path: "tokenizer.json")
        let marker = harness.downloader.modelDirectory.appending(path: ".download-complete")

        #expect(!harness.downloader.isDownloadComplete)

        try Data().write(to: tokenizer)
        #expect(!harness.downloader.isDownloadComplete)

        try FileManager.default.removeItem(at: tokenizer)
        try Data().write(to: marker)
        #expect(!harness.downloader.isDownloadComplete)

        try Data().write(to: tokenizer)
        #expect(harness.downloader.isDownloadComplete)
    }

    @Test func modelDirectoryStaysInsideProvidedRoot() throws {
        let harness = try makeDownloader()
        defer { try? FileManager.default.removeItem(at: harness.root) }

        let rootPath = harness.root.standardizedFileURL.path + "/"
        let modelPath = harness.downloader.modelDirectory.standardizedFileURL.path + "/"

        #expect(modelPath.hasPrefix(rootPath))
    }
}
