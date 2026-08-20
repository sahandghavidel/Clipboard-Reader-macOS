import AppKit
import SwiftUI

struct JSONSceneManagerView: View {
    @EnvironmentObject private var appModel: AppModel
    let chapter: NarrationChapter
    let initialIndex: Int
    let close: () -> Void

    @State private var selectedIndex: Int
    @State private var workingChapter: NarrationChapter
    @State private var title = ""
    @State private var displayTitle = ""
    @State private var action = ""
    @State private var result = ""
    @State private var narration = ""
    @State private var annotation = ""
    @State private var activeField: EditableField?

    private enum EditableField { case title, displayTitle, action, result, narration }

    init(chapter: NarrationChapter, selectedIndex: Int, close: @escaping () -> Void) {
        self.chapter = chapter
        self.initialIndex = min(max(selectedIndex, 0), max(chapter.scenes.count - 1, 0))
        self.close = close
        self._selectedIndex = State(initialValue: self.initialIndex)
        self._workingChapter = State(initialValue: chapter)
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
            loadDraft()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sceneEditorShouldClose)) { _ in
            close()
        }
    }

    private var sceneList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chapter \(workingChapter.chapterNumber)")
                .font(.headline)

            Text(workingChapter.chapterTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(workingChapter.scenes.indices, id: \.self) { index in
                            let scene = workingChapter.scenes[index]
                            Button {
                                selectedIndex = index
                                loadDraft()
                                activeField = nil
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

            Text("Scene \(selectedIndex + 1) of \(workingChapter.scenes.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var sceneDetails: some View {
        let scene = workingChapter.scenes[selectedIndex]

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
                    select(min(selectedIndex + 1, workingChapter.scenes.count - 1))
                }
                .disabled(selectedIndex >= workingChapter.scenes.count - 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    editableField("Title", field: .title, text: $title)
                    editableField("Display Title", field: .displayTitle, text: $displayTitle)
                    editableField("Action", field: .action, text: $action)
                    editableField("Result", field: .result, text: $result)
                    editableField("Narration", field: .narration, text: $narration)
                    annotationField
                    if let code = scene.code {
                        codeSection(code)
                    }
                    if !scene.links.isEmpty || workingChapter.visualURL(for: scene) != nil {
                        linksSection(scene)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Cancel") { loadDraft(); activeField = nil }
                    .disabled(activeField == nil)
                Button("Save Changes") { saveChanges() }
                    .keyboardShortcut(.defaultAction)
                Text("Annotations are saved with the chapter and are never spoken.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done", action: close)
                    .keyboardShortcut(.cancelAction)
            }
        }
    }

    private func editableField(_ label: String, field: EditableField, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            if activeField == field {
                TextEditor(text: text)
                    .font(.body)
                    .frame(height: max(34, min(110, CGFloat(text.wrappedValue.count / 65 + 1) * 22)))
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.secondary.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.accentColor.opacity(0.7)))
            } else {
                Text(text.wrappedValue.isEmpty ? "None" : text.wrappedValue)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.secondary.opacity(0.08)))
                    .onTapGesture { activeField = field }
            }
        }
    }

    private var annotationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ANNOTATION").font(.caption.bold()).foregroundStyle(.secondary)
            TextEditor(text: $annotation)
                .font(.body)
                .frame(height: max(34, min(90, CGFloat(annotation.count / 65 + 1) * 22)))
                .padding(5)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.yellow.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.yellow.opacity(0.5)))
        }
    }

    private func loadDraft() {
        let scene = workingChapter.scenes[selectedIndex]
        title = scene.title
        displayTitle = scene.displayTitle
        action = scene.onScreen.action ?? ""
        result = scene.onScreen.result
        narration = scene.narration
        annotation = scene.annotation ?? ""
    }

    private func saveChanges() {
        let old = workingChapter.scenes[selectedIndex]
        let updated = NarrationScene(
            id: old.id, sceneNumber: old.sceneNumber, sceneType: old.sceneType,
            title: title, annotation: annotation.isEmpty ? nil : annotation,
            displayTitle: displayTitle,
            onScreen: NarrationOnScreen(action: old.sceneType == .action ? action : nil, result: result),
            narration: narration, code: old.code, links: old.links, visualId: old.visualId
        )
        var scenes = workingChapter.scenes
        scenes[selectedIndex] = updated
        let updatedChapter = NarrationChapter(
            schemaVersion: workingChapter.schemaVersion, projectSlug: workingChapter.projectSlug,
            chapterNumber: workingChapter.chapterNumber, chapterTitle: workingChapter.chapterTitle,
            status: workingChapter.status, annotation: workingChapter.annotation, scenes: scenes
        )
        do {
            try NarrationChapterLoader.validate(updatedChapter)
            let data = try JSONEncoder.narrationPilot.encode(updatedChapter)
            appModel.saveEditedChapterJSON(String(data: data, encoding: .utf8) ?? "")
            workingChapter = updatedChapter
            activeField = nil
        } catch {
            appModel.statusMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
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

            if let visualURL = workingChapter.visualURL(for: scene) {
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
        loadDraft()
        activeField = nil
        appModel.selectSceneForEditing(index)
    }
}
