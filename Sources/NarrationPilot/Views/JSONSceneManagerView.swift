import AppKit
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
        .onReceive(NotificationCenter.default.publisher(for: .sceneEditorShouldClose)) { _ in
            close()
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
                                    HStack(spacing: 5) {
                                        Text("Scene \(scene.sceneNumber)")
                                            .font(.caption.bold())
                                    }
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
                    onScreenSection(scene)
                    detailSection("Narration", text: scene.narration)
                    detailSection("Display Title", text: scene.displayTitle)
                    if let code = scene.code {
                        codeSection(code)
                    }
                    if !scene.links.isEmpty || chapter.visualURL(for: scene) != nil {
                        linksSection(scene)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Text("JSON scenes are read-only. Saved source-file changes reload automatically.")
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

            ForEach(detectedURLs(in: text), id: \.absoluteString) { url in
                Link(destination: url) {
                    Label(url.absoluteString, systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
            }
        }
    }

    private func onScreenSection(_ scene: NarrationScene) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ON SCREEN")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                if scene.sceneType == .action, let action = scene.onScreen.action {
                    labeledValue("Action", text: action)
                    Divider()
                } else if scene.sceneType == .result {
                    Text("RESULT ONLY — DO NOT PERFORM A NEW ACTION")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                } else {
                    Text("EXPLANATION — KEEP THE CURRENT SCREEN VISIBLE")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                labeledValue("Result", text: scene.onScreen.result)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.secondary.opacity(0.08)))
        }
    }

    private func labeledValue(_ label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(text)
                .textSelection(.enabled)
            ForEach(detectedURLs(in: text), id: \.absoluteString) { url in
                Link(destination: url) {
                    Label(url.absoluteString, systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
            }
        }
    }

    private func codeSection(_ code: NarrationCode) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CODE → \(code.targetFile) · \(code.language.uppercased()) · \(code.action.rawValue.capitalized)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code.text, forType: .string)
                } label: {
                    Label("Copy Code", systemImage: "doc.on.doc")
                }
            }

            Text(code.text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.secondary.opacity(0.08)))
        }
    }

    private func linksSection(_ scene: NarrationScene) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LINKS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(scene.links) { link in
                if let url = URL(string: link.url) {
                    Link(destination: url) {
                        Label(link.label, systemImage: "arrow.up.right.square")
                    }
                }
            }

            if let visualURL = chapter.visualURL(for: scene) {
                Button {
                    openVisual(visualURL)
                } label: {
                    Label("Open Visual", systemImage: "rectangle.on.rectangle.angled")
                }
                .buttonStyle(.link)
                .help(visualURL.absoluteString)
            }
        }
    }

    private func openVisual(_ url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            NSWorkspace.shared.open(url)
            return
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "visualOpen" }
        queryItems.append(
            URLQueryItem(
                name: "visualOpen",
                value: String(Int(Date().timeIntervalSince1970 * 1_000))
            )
        )
        components.queryItems = queryItems
        NSWorkspace.shared.open(components.url ?? url)
    }

    private func detectedURLs(in text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.matches(in: text, range: range).compactMap(\.url)
    }

    private func select(_ index: Int) {
        selectedIndex = index
        appModel.selectSceneForEditing(index)
    }
}
