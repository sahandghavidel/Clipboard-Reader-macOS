import AppKit
import KeyboardShortcuts
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clipboard Reader")
                .font(.headline)

            Text(appModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("Read Clipboard") {
                    appModel.readClipboardNow()
                }

                Button("Stop") {
                    appModel.stopReading()
                }

                Button(appModel.speechState.pauseResumeTitle) {
                    appModel.togglePauseResume()
                }
                .disabled(appModel.speechState == .idle || appModel.speechState == .stopping)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Read Speed: \(appModel.speedMultiplier, specifier: "%.2f")x")
                    .font(.subheadline)

                Slider(
                    value: $appModel.speedMultiplier,
                    in: SpeechRateMapper.minMultiplier...SpeechRateMapper.maxMultiplier,
                    step: 0.05
                )

                Text("Range: 0.5x to 1.5x")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Voice")
                    .font(.subheadline)

                Text("Using: \(appModel.outputVoiceDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let note = appModel.outputVoiceNote {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Picker(
                    "Voice",
                    selection: Binding(
                        get: { appModel.selectedVoiceIdentifierForPicker },
                        set: { appModel.updateVoiceSelection($0) }
                    )
                ) {
                    Text("System Default").tag("")
                    ForEach(appModel.availableVoices, id: \.identifier) { voice in
                        Text("\(voice.name) (\(voice.language))")
                            .tag(voice.identifier)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Global Shortcuts")
                    .font(.subheadline.bold())

                KeyboardShortcuts.Recorder("Read Clipboard", name: .readClipboard)
                KeyboardShortcuts.Recorder("Stop Reading", name: .stopReading)
                KeyboardShortcuts.Recorder("Pause / Resume", name: .pauseResumeReading)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .frame(width: 420)
    }
}