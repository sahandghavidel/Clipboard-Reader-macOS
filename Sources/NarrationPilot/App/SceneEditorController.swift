import AppKit
import SwiftUI

@MainActor
final class SceneEditorController {
    private weak var appModel: AppModel?
    private var panel: NSPanel?

    init(appModel: AppModel) {
        self.appModel = appModel
    }

    func show() {
        guard let appModel else {
            return
        }

        let panel: NSPanel
        if let chapter = appModel.loadedChapter, appModel.scriptInputFormat == .json {
            let selectedIndex = min(appModel.currentSceneIndexForEditor, max(chapter.scenes.count - 1, 0))
            panel = makeJSONPanel(appModel: appModel, chapter: chapter, selectedIndex: selectedIndex)
        } else {
            let scenes = appModel.allSceneTexts.isEmpty ? [""] : appModel.allSceneTexts
            let selectedIndex = min(appModel.currentSceneIndexForEditor, max(scenes.count - 1, 0))
            panel = makeTextPanel(appModel: appModel, scenes: scenes, selectedIndex: selectedIndex)
        }
        self.panel = panel
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makeTextPanel(appModel: AppModel, scenes: [String], selectedIndex: Int) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.contentView = NSHostingView(
            rootView: CurrentSceneEditorView(scenes: scenes, selectedIndex: selectedIndex) { [weak self] in
                self?.panel?.close()
                self?.panel = nil
            }
            .environmentObject(appModel)
        )
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.minSize = NSSize(width: 720, height: 420)
        panel.sharingType = .none
        panel.title = "Scene Manager"

        return panel
    }

    private func makeJSONPanel(appModel: AppModel, chapter: NarrationChapter, selectedIndex: Int) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.contentView = NSHostingView(
            rootView: JSONSceneManagerView(
                chapter: chapter,
                selectedIndex: selectedIndex
            ) { [weak self] in
                self?.panel?.close()
                self?.panel = nil
            }
            .environmentObject(appModel)
        )
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.minSize = NSSize(width: 780, height: 500)
        panel.sharingType = .none
        panel.title = "JSON Scene Manager"

        return panel
    }
}
