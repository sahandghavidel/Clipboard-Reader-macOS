import SwiftUI

struct CurrentSceneEditorView: View {
    @EnvironmentObject private var appModel: AppModel
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
                .frame(minHeight: 190)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25))
                )

            HStack {
                Spacer()

                Button("Cancel") {
                    close()
                }

                Button("Save") {
                    appModel.saveCurrentSceneEdit(draftText)
                    close()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .frame(minWidth: 520, minHeight: 260)
    }
}
