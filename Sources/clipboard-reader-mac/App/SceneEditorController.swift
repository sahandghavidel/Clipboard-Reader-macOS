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

        let currentSceneText = appModel.currentSceneText ?? ""

        let panel = makePanel(appModel: appModel, initialText: currentSceneText)
        self.panel = panel
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel(appModel: AppModel, initialText: String) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 360),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.contentView = NSHostingView(
            rootView: CurrentSceneEditorView(initialText: initialText) { [weak self] in
                self?.panel?.close()
                self?.panel = nil
            }
            .environmentObject(appModel)
        )
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.minSize = NSSize(width: 520, height: 260)
        panel.sharingType = .none
        panel.title = "Edit Current Scene"

        return panel
    }
}
