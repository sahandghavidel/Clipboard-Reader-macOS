import SwiftUI

struct CurrentSceneEditorView: View {
    @EnvironmentObject private var appModel: AppModel
    @FocusState private var isEditorFocused: Bool
    @State private var draftText: String
    @State private var scenes: [String]
    @State private var selectedIndex: Int
    let close: () -> Void

    init(scenes: [String], selectedIndex: Int, close: @escaping () -> Void) {
        let initialScenes = scenes.isEmpty ? [""] : scenes
        let initialIndex = min(max(selectedIndex, 0), max(initialScenes.count - 1, 0))
        self._scenes = State(initialValue: initialScenes)
        self._selectedIndex = State(initialValue: initialIndex)
        self._draftText = State(initialValue: initialScenes[initialIndex])
        self.close = close
    }

    var body: some View {
        HStack(spacing: 0) {
            sceneList
                .frame(width: 260)
                .padding(.vertical, 14)
                .padding(.leading, 14)
                .padding(.trailing, 10)

            Divider()

            editorPane
                .padding(18)
        }
        .frame(minWidth: 720, minHeight: 420)
        .onAppear {
            DispatchQueue.main.async {
                isEditorFocused = true
                appModel.selectSceneForEditing(selectedIndex)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sceneEditorShouldClose)) { _ in
            saveAndClose()
        }
    }

    private var sceneList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scenes")
                .font(.headline)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(scenes.indices, id: \.self) { index in
                            Button {
                                selectScene(index)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Scene \(index + 1)")
                                        .font(.caption.bold())

                                    Text(preview(for: scenes[index]))
                                        .font(.caption2)
                                        .lineLimit(3)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(index == selectedIndex ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(selectedIndex, anchor: .top)
                    }
                }
            }

            Text("Scene \(selectedIndex + 1) of \(scenes.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var editorPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scene \(selectedIndex + 1) of \(scenes.count)")
                    .font(.headline)

                Spacer()

                Button("Previous") {
                    selectScene(max(selectedIndex - 1, 0))
                }
                .disabled(selectedIndex == 0)

                Button("Next") {
                    selectScene(min(selectedIndex + 1, scenes.count - 1))
                }
                .disabled(selectedIndex >= scenes.count - 1)
            }

            TextEditor(text: $draftText)
                .font(.system(size: 18))
                .focused($isEditorFocused)
                .frame(minHeight: 230)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25))
                )

            HStack(spacing: 8) {
                Button("Split") {
                    splitScene()
                }

                Button("Merge Previous") {
                    mergeWithPrevious()
                }
                .disabled(selectedIndex == 0)

                Button("Merge Next") {
                    mergeWithNext()
                }
                .disabled(selectedIndex >= scenes.count - 1)

                Button("Delete") {
                    deleteScene()
                }
                .disabled(scenes.count == 1 && draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                Button("Done") {
                    saveAndClose()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
    }

    private func selectScene(_ index: Int) {
        saveDraftToSelection()
        selectedIndex = min(max(index, 0), max(scenes.count - 1, 0))
        draftText = scenes[selectedIndex]
        appModel.selectSceneForEditing(selectedIndex)
        DispatchQueue.main.async {
            isEditorFocused = true
        }
    }

    private func saveDraftToSelection() {
        guard scenes.indices.contains(selectedIndex) else {
            return
        }

        scenes[selectedIndex] = draftText
    }

    private func saveAndClose() {
        saveDraftToSelection()
        appModel.saveSceneManagerScenes(scenes, selectedIndex: selectedIndex)
        close()
    }

    private func splitScene() {
        saveDraftToSelection()
        let splitScenes = ScriptSceneSplitter.scenes(from: draftText)
        guard splitScenes.count > 1 else {
            return
        }

        scenes.replaceSubrange(selectedIndex...selectedIndex, with: splitScenes)
        draftText = scenes[selectedIndex]
        appModel.selectSceneForEditing(selectedIndex)
    }

    private func mergeWithPrevious() {
        saveDraftToSelection()
        guard selectedIndex > 0 else {
            return
        }

        scenes[selectedIndex - 1] = mergedText(scenes[selectedIndex - 1], scenes[selectedIndex])
        scenes.remove(at: selectedIndex)
        selectedIndex -= 1
        draftText = scenes[selectedIndex]
        appModel.selectSceneForEditing(selectedIndex)
    }

    private func mergeWithNext() {
        saveDraftToSelection()
        guard selectedIndex + 1 < scenes.count else {
            return
        }

        scenes[selectedIndex] = mergedText(scenes[selectedIndex], scenes[selectedIndex + 1])
        scenes.remove(at: selectedIndex + 1)
        draftText = scenes[selectedIndex]
        appModel.selectSceneForEditing(selectedIndex)
    }

    private func deleteScene() {
        if scenes.count == 1 {
            scenes[0] = ""
            draftText = ""
            return
        }

        scenes.remove(at: selectedIndex)
        selectedIndex = min(selectedIndex, scenes.count - 1)
        draftText = scenes[selectedIndex]
        appModel.selectSceneForEditing(selectedIndex)
    }

    private func mergedText(_ first: String, _ second: String) -> String {
        [first, second]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func preview(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Empty" : trimmed
    }
}
