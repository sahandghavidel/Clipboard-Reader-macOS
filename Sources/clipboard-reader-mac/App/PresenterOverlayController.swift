import AppKit
import SwiftUI

@MainActor
final class PresenterOverlayController {
    private var panel: NSPanel?
    private let appModel: AppModel

    init(appModel: AppModel) {
        self.appModel = appModel
    }

    func updateVisibility() {
        if appModel.shouldShowPresenterOverlay {
            show()
        } else {
            hide()
        }
    }

    func updateCaptureVisibility() {
        panel?.sharingType = appModel.hidePresenterOverlayFromCapture ? .none : .readOnly
    }

    private func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        position(panel)
        updateCaptureVisibility()
        panel.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        panel.contentView = NSHostingView(
            rootView: PresenterOverlayView()
                .environmentObject(appModel)
        )
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.level = .statusBar
        panel.titleVisibility = .hidden

        return panel
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else {
            return
        }

        let screenFrame = screen.frame
        let width = min(screenFrame.width - 80, 980)
        let height: CGFloat = 170
        let x = screenFrame.midX - width / 2
        let y = screenFrame.minY + 24

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}
