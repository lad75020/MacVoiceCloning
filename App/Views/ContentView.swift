import SwiftUI

struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        @Bindable var pipeline = model.pipeline

        ScrollView {
            VStack(spacing: 14) {
                ModelStatusView()
                RecordStageView()
                TextStageView()
                SynthesizeStageView()
                AlterStageView()
                ExportStageView()
            }
            .padding(18)
        }
        .frame(minWidth: 660, idealWidth: 740, minHeight: 640, idealHeight: 920)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(model)
        .task {
            await model.onLaunch()
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { pipeline.lastError != nil },
                set: { if !$0 { pipeline.lastError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pipeline.lastError ?? "")
        }
    }
}
