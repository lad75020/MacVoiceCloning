import SwiftUI

struct AlterStageView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var pipeline = model.pipeline

        StageCard(number: 4, title: "Alter the voice") {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("Pitch")
                    Slider(value: $pipeline.effect.pitchSemitones, in: -12...12, step: 1)
                    Text(String(format: "%+.0f st", pipeline.effect.pitchSemitones))
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
                GridRow {
                    Text("Speed")
                    Slider(value: $pipeline.effect.speed, in: 0.5...2.0)
                    Text(String(format: "×%.2f", pipeline.effect.speed))
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
                GridRow {
                    Text("Timbre")
                    Slider(value: $pipeline.effect.formantScale, in: 0.5...2.0)
                        .disabled(pipeline.effect.engine == .r2Faster)
                    Text(String(format: "×%.2f", pipeline.effect.formantScale))
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
            }

            HStack(spacing: 16) {
                Toggle("Preserve vocal character", isOn: $pipeline.effect.preserveFormants)

                Picker("Engine", selection: $pipeline.effect.engine) {
                    ForEach(VoiceEffectParameters.Engine.allCases) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)

                Spacer()
            }

            HStack(spacing: 12) {
                Menu("Presets") {
                    ForEach(VoiceEffectParameters.presets) { preset in
                        Button(preset.name) {
                            pipeline.effect = preset.parameters
                        }
                    }
                    Divider()
                    Button("Reset") {
                        pipeline.effect = VoiceEffectParameters()
                    }
                }
                .frame(maxWidth: 110)

                Spacer()

                if pipeline.isAltering {
                    ProgressView().controlSize(.small)
                    Text("Processing…").font(.caption).foregroundStyle(.secondary)
                }

                Toggle("Bypass (hear original)", isOn: $pipeline.bypassEffect)
                    .disabled(pipeline.effect.isIdentity)

                PlayerControls(url: pipeline.previewClip?.url, label: "Preview")
            }

            if pipeline.effect.engine == .r2Faster && pipeline.effect.formantScale != 1.0 {
                Text("Timbre requires the R3 engine.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .disabled(pipeline.synthesis == nil)
        .onChange(of: pipeline.effect) {
            model.player.stop()
            pipeline.scheduleAlteration()
        }
        .onChange(of: pipeline.bypassEffect) {
            model.player.stop()
        }
    }
}
