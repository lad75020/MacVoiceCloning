import SwiftUI

struct TextStageView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var pipeline = model.pipeline

        StageCard(number: 2, title: "Write what your clone should say") {
            TextEditor(text: $pipeline.targetText)
                .font(.body)
                .frame(minHeight: 72)
                .disabled(pipeline.isSynthesizing)
                .accessibilityLabel("Text to synthesize")
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(alignment: .topLeading) {
                    if pipeline.synthesisText.isEmpty {
                        Text("Type the text to synthesize in your cloned voice…")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 13)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: pipeline.targetText) {
                    model.player.stop()
                }

            Picker("Language", selection: $pipeline.language) {
                ForEach(TTSLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .frame(maxWidth: 280)
            .disabled(pipeline.isSynthesizing)
            .onChange(of: pipeline.language) {
                model.player.stop()
            }
        }
    }
}
