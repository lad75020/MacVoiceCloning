import Foundation

/// Well-known locations for working files and downloaded models.
nonisolated enum SessionFiles {
    static var appSupport: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "MacVoiceCloning", directoryHint: .isDirectory)
    }

    static var modelsRoot: URL {
        appSupport.appending(path: "Models", directoryHint: .isDirectory)
    }

    static var sessionDir: URL {
        appSupport.appending(path: "Session", directoryHint: .isDirectory)
    }

    static var rawRecording: URL { sessionDir.appending(path: "recording-raw.caf") }
    static var reference24k: URL { sessionDir.appending(path: "reference-24k.wav") }
    static var synthesisWAV: URL { sessionDir.appending(path: "synthesis.wav") }
    static var alteredWAV: URL { sessionDir.appending(path: "altered.wav") }

    static func prepareDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: modelsRoot, withIntermediateDirectories: true)
        try fm.createDirectory(at: sessionDir, withIntermediateDirectories: true)
    }
}
