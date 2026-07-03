import AppKit
import KeyboardShortcuts
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Clipboard Reader")
                    .font(.headline)

                Spacer()

                Text("v\(AppVersion.shortVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(appModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Read typed text instead of clipboard", isOn: $appModel.readsTypedTextInsteadOfClipboard)

                Toggle("Script mode", isOn: $appModel.scriptModeEnabled)

                Text(appModel.inputModeStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                TextEditor(text: $appModel.typedText)
                    .font(.body)
                    .frame(minHeight: 100)
                    .onChange(of: appModel.typedText) {
                        appModel.refreshScriptScenes()
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    )

                HStack(spacing: 8) {
                    Button(appModel.readButtonTitle) {
                        appModel.readNow()
                    }

                    Button("Clear") {
                        appModel.clearTypedText()
                    }
                    .disabled(appModel.typedText.isEmpty)
                }

                if appModel.scriptModeEnabled {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(appModel.scriptSceneProgress)
                            .font(.subheadline.bold())

                        Text(appModel.currentSceneText ?? "Paste a script to create scenes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 8) {
                            Button("Previous") {
                                appModel.goToPreviousScene()
                            }
                            .disabled(!appModel.canGoToPreviousScene)

                            Button("Replay") {
                                appModel.replayCurrentScriptScene()
                            }
                            .disabled(appModel.currentSceneText == nil)

                            Button("Next") {
                                appModel.goToNextScene()
                            }
                            .disabled(!appModel.canGoToNextScene)

                            Button("Restart") {
                                appModel.restartScript()
                            }
                            .disabled(appModel.currentSceneText == nil)
                        }
                    }
                }
            }

            HStack(spacing: 8) {

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

                KeyboardShortcuts.Recorder("Read Current Input", name: .readClipboard)
                KeyboardShortcuts.Recorder("Stop Reading", name: .stopReading)
                KeyboardShortcuts.Recorder("Pause / Resume", name: .pauseResumeReading)
                KeyboardShortcuts.Recorder("Replay Scene", name: .replayScriptScene)
                KeyboardShortcuts.Recorder("Previous Scene", name: .previousScriptScene)
                KeyboardShortcuts.Recorder("Next Scene", name: .nextScriptScene)
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
