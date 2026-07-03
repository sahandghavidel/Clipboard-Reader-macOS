import AppKit
import SwiftUI

struct TriggerShortcutCaptureView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Shortcut")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(appModel.recordingTriggerShortcut?.displayName ?? "Not set")
                    .font(.caption.bold())

                Spacer()

                Button("Clear") {
                    appModel.clearRecordingTriggerShortcut()
                }
                .disabled(appModel.recordingTriggerShortcut == nil)
            }

            HStack(spacing: 10) {
                modifierToggle("Control", flag: .control)
                modifierToggle("Option", flag: .option)
                modifierToggle("Shift", flag: .shift)
                modifierToggle("Command", flag: .command)
            }

            Picker("Key", selection: keySelection) {
                ForEach(TriggerShortcut.keyOptions) { keyOption in
                    Text(keyOption.label).tag(keyOption.keyCode)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var keySelection: Binding<Int> {
        Binding(
            get: {
                appModel.recordingTriggerShortcut?.keyCode ?? TriggerShortcut.defaultKeyOption.keyCode
            },
            set: { keyCode in
                updateShortcut(keyOption: TriggerShortcut.keyOption(for: keyCode), modifiers: currentModifiers)
            }
        )
    }

    private var currentModifiers: NSEvent.ModifierFlags {
        appModel.recordingTriggerShortcut?.modifiers ?? [.command, .shift]
    }

    private func modifierToggle(_ title: String, flag: NSEvent.ModifierFlags) -> some View {
        Toggle(title, isOn: Binding(
            get: {
                currentModifiers.contains(flag)
            },
            set: { isEnabled in
                var modifiers = currentModifiers

                if isEnabled {
                    modifiers.insert(flag)
                } else {
                    modifiers.remove(flag)
                }

                updateShortcut(keyOption: currentKeyOption, modifiers: modifiers)
            }
        ))
        .toggleStyle(.checkbox)
    }

    private var currentKeyOption: TriggerShortcut.KeyOption {
        guard let shortcut = appModel.recordingTriggerShortcut else {
            return TriggerShortcut.defaultKeyOption
        }

        return TriggerShortcut.keyOption(for: shortcut.keyCode)
    }

    private func updateShortcut(keyOption: TriggerShortcut.KeyOption, modifiers: NSEvent.ModifierFlags) {
        let shortcut = TriggerShortcut(
            keyOption: keyOption,
            modifiers: modifiers
        )
        appModel.updateRecordingTriggerShortcut(shortcut)
    }
}
