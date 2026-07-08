import SwiftUI

struct CurrentSceneEditorView: View {
    @EnvironmentObject private var appModel: AppModel
    @FocusState private var isEditorFocused: Bool
    @State private var draftText: String
    let close: () -> Void

    init(initialText: String, close: @escaping () -> Void) {
        self._draftText = State(initialValue: initialText)
        self.close = close
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appModel.scriptSceneProgress)
                .font(.headline)

            TextEditor(text: $draftText)
                .font(.system(size: 18))
                .focused($isEditorFocused)
                .frame(minHeight: 190)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25))
                )

            HStack {
                Spacer()

                Button("Done") {
                    saveAndClose()
                }
                .keyboardShortcut(.cancelAction)
                .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .frame(minWidth: 520, minHeight: 260)
        .onAppear {
            DispatchQueue.main.async {
                isEditorFocused = true
            }
        }
    }

    private func saveAndClose() {
        appModel.saveCurrentSceneEdit(draftText)
        close()
    }
}
