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

        let scenes = appModel.allSceneTexts.isEmpty ? [""] : appModel.allSceneTexts
        let selectedIndex = min(appModel.currentSceneIndexForEditor, max(scenes.count - 1, 0))
        let panel = makePanel(appModel: appModel, scenes: scenes, selectedIndex: selectedIndex)
        self.panel = panel
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel(appModel: AppModel, scenes: [String], selectedIndex: Int) -> NSPanel {
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
}
