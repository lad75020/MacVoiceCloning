import SwiftUI
import UniformTypeIdentifiers

struct RecordStageView: View {
    @Environment(AppModel.self) private var model
    @State private var showImporter = false
    @State private var permissionDenied = false

    var body: some View {
        @Bindable var pipeline = model.pipeline

        StageCard(number: 1, title: "Record your voice") {
            HStack(spacing: 12) {
                Button {
                    Task { await toggleRecording() }
                } label: {
                    Label(
                        model.recorder.state == .recording ? "Stop" : "Record",
                        systemImage: model.recorder.state == .recording ? "stop.circle.fill" : "record.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(model.recorder.state == .recording ? .red : .accentColor)

                LevelMeterView(level: model.recorder.level)
                    .frame(width: 120)

                statusLabel

                Spacer()

                Button("Import…") { showImporter = true }
                    .disabled(model.recorder.state == .recording)
            }

            Text("Speak clearly for 5–15 seconds. At least 3 seconds are required.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField(
                    "Transcript of the recording (what you said)",
                    text: $pipeline.referenceTranscript,
                    axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .disabled(pipeline.isTranscribing)

                if pipeline.isTranscribing {
                    ProgressView().controlSize(.small)
                }
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { result in
            if case .success(let url) = result {
                Task { await importReference(url) }
            }
        }
        .alert("Microphone access needed", isPresented: $permissionDenied) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow MacVoiceCloning to use the microphone in System Settings → Privacy & Security.")
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        if model.recorder.state == .recording {
            let long = model.recorder.duration >= AudioRecorder.minimumDuration
            Text(String(format: "%.1f s", model.recorder.duration))
                .monospacedDigit()
                .foregroundStyle(long ? .green : .secondary)
        } else if model.pipeline.isPreparingReference {
            ProgressView().controlSize(.small)
        } else if let reference = model.pipeline.reference {
            Label(String(format: "%.1f s sample", reference.duration), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            PlayerControls(url: reference.url)
        } else {
            Text("No sample yet").foregroundStyle(.secondary)
        }
    }

    private func toggleRecording() async {
        if model.recorder.state == .recording {
            do {
                if let recording = try model.recorder.stop() {
                    await model.pipeline.setReference(fromRaw: recording.url)
                }
            } catch {
                model.pipeline.lastError = error.localizedDescription
            }
        } else {
            guard await model.recorder.requestPermission() else {
                permissionDenied = true
                return
            }
            model.player.stop()
            do {
                try model.recorder.start()
            } catch {
                model.pipeline.lastError = error.localizedDescription
            }
        }
    }

    private func importReference(_ url: URL) async {
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped { url.stopAccessingSecurityScopedResource() }
        }
        await model.pipeline.setReference(fromRaw: url)
    }
}
