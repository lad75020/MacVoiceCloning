import SwiftUI

struct SynthesizeStageView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let pipeline = model.pipeline

        StageCard(number: 3, title: "Synthesize") {
            HStack(spacing: 12) {
                Button {
                    model.player.stop()
                    Task { await model.synthesize() }
                } label: {
                    Label("Generate", systemImage: "waveform")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canSynthesize)

                if pipeline.isSynthesizing {
                    ProgressView().controlSize(.small)
                    Text(String(format: "Generated %.1f s…", pipeline.synthesisProgress))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else if let synthesis = pipeline.synthesis {
                    PlayerControls(url: synthesis.url)
                    Text(String(format: "%.1f s", synthesis.duration))
                        .foregroundStyle(.secondary)
                    if let stats = pipeline.synthesisStats {
                        Text(String(format: "%.0f tok/s", stats.tokensPerSecond))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }

            if !model.canSynthesize && !pipeline.isSynthesizing {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hint: String {
        if model.modelManager.state != .ready {
            return "Load the voice model first (top of the window)."
        }
        if model.pipeline.reference == nil {
            return "Record or import a voice sample first."
        }
        if model.pipeline.referenceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Fill in the transcript of your voice sample (stage 1)."
        }
        if model.pipeline.targetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Write the text to synthesize (stage 2)."
        }
        return ""
    }
}
