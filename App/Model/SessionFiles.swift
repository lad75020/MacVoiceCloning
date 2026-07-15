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
    static var referenceStaging: URL { sessionDir.appending(path: "reference-staging.wav") }
    static var reference24k: URL { sessionDir.appending(path: "reference-24k.wav") }
    static var synthesisStaging: URL { sessionDir.appending(path: "synthesis-staging.wav") }
    static var synthesisWAV: URL { sessionDir.appending(path: "synthesis.wav") }
    static var alteredWAV: URL { sessionDir.appending(path: "altered.wav") }

    static func prepareDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: modelsRoot, withIntermediateDirectories: true)
        try fm.createDirectory(at: sessionDir, withIntermediateDirectories: true)
    }

    static func commitPreparedReference(at staging: URL, to destination: URL = reference24k) throws {
        try commitPreparedFile(at: staging, to: destination)
    }

    static func commitPreparedSynthesis(at staging: URL, to destination: URL = synthesisWAV) throws {
        try commitPreparedFile(at: staging, to: destination)
    }

    private static func commitPreparedFile(at staging: URL, to destination: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: destination.path) {
            _ = try fm.replaceItemAt(destination, withItemAt: staging)
        } else {
            try fm.moveItem(at: staging, to: destination)
        }
    }
}
