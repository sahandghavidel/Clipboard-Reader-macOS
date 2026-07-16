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

    func updateLayout() {
        guard let panel else {
            return
        }

        position(panel)
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
        panel.ignoresMouseEvents = false
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
        let width = min(screenFrame.width - 40, CGFloat(appModel.presenterOverlayWidth))
        let height = CGFloat(appModel.presenterOverlayHeight)
        let minX = screenFrame.minX + 20
        let maxX = screenFrame.maxX - width - 20
        let minY = screenFrame.minY + 8
        let maxY = screenFrame.maxY - height - 20
        let preferredX = screenFrame.midX - width / 2 + CGFloat(appModel.presenterOverlayHorizontalOffset)
        let preferredY = screenFrame.minY + CGFloat(appModel.presenterOverlayBottomOffset)
        let x = min(max(preferredX, minX), maxX)
        let y = min(max(preferredY, minY), maxY)

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}
