import Foundation
import Observation

@Observable
@MainActor
final class AppModel {
    let modelManager = ModelManager()
    let pipeline = PipelineState()
    let recorder = AudioRecorder()
    let player = AudioPlayer()

    var canSynthesize: Bool {
        modelManager.state == .ready && pipeline.hasSynthesisInputs && !pipeline.isSynthesizing
    }

    func onLaunch() async {
        try? SessionFiles.prepareDirectories()
        modelManager.refreshOnLaunch()
        if case .downloaded = modelManager.state {
            await modelManager.load()
        }
    }

    func synthesize() async {
        guard let engine = modelManager.engine else { return }
        player.stop()
        await pipeline.synthesize(with: engine)
    }
}
