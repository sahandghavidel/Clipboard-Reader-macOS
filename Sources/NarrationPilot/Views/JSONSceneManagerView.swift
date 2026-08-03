import SwiftUI

struct JSONSceneManagerView: View {
    @EnvironmentObject private var appModel: AppModel
    let chapter: NarrationChapter
    let initialIndex: Int
    let close: () -> Void

    @State private var selectedIndex: Int

    init(chapter: NarrationChapter, selectedIndex: Int, close: @escaping () -> Void) {
        self.chapter = chapter
        self.initialIndex = min(max(selectedIndex, 0), max(chapter.scenes.count - 1, 0))
        self.close = close
        self._selectedIndex = State(initialValue: self.initialIndex)
    }

    var body: some View {
        HStack(spacing: 0) {
            sceneList
                .frame(width: 260)
                .padding(.vertical, 14)
                .padding(.leading, 14)
                .padding(.trailing, 10)

            Divider()

            sceneDetails
                .padding(18)
        }
        .frame(minWidth: 780, minHeight: 500)
        .onAppear {
            appModel.selectSceneForEditing(selectedIndex)
        }
    }

    private var sceneList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chapter \(chapter.chapterNumber)")
                .font(.headline)

            Text(chapter.chapterTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(chapter.scenes.indices, id: \.self) { index in
                            let scene = chapter.scenes[index]
                            Button {
                                selectedIndex = index
                                appModel.selectSceneForEditing(index)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Scene \(scene.sceneNumber)")
                                        .font(.caption.bold())
                                    Text(scene.title)
                                        .font(.caption2)
                                        .lineLimit(2)
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

            Text("Scene \(selectedIndex + 1) of \(chapter.scenes.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var sceneDetails: some View {
        let scene = chapter.scenes[selectedIndex]

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Scene \(scene.sceneNumber)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(scene.title)
                        .font(.title2.bold())
                }

                Spacer()

                Button("Previous") {
                    select(max(selectedIndex - 1, 0))
                }
                .disabled(selectedIndex == 0)

                Button("Next") {
                    select(min(selectedIndex + 1, chapter.scenes.count - 1))
                }
                .disabled(selectedIndex >= chapter.scenes.count - 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailSection("On Screen", text: scene.onScreen.joined(separator: "\n"))
                    detailSection("Narration", text: scene.narration)
                    if let code = scene.code, !code.isEmpty {
                        detailSection("Code", text: code, monospaced: true)
                    }
                    if let expectedResult = scene.expectedResult, !expectedResult.isEmpty {
                        detailSection("Expected Result", text: expectedResult)
                    }
                    if let estimatedSeconds = scene.estimatedSeconds {
                        detailSection("Estimated Time", text: "\(estimatedSeconds.formatted()) seconds")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Text("JSON scenes are read-only. Edit the source file and reload it to make changes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done", action: close)
                    .keyboardShortcut(.cancelAction)
            }
        }
    }

    private func detailSection(_ title: String, text: String, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(text.isEmpty ? "None" : text)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.secondary.opacity(0.08)))
        }
    }

    private func select(_ index: Int) {
        selectedIndex = index
        appModel.selectSceneForEditing(index)
    }
}
