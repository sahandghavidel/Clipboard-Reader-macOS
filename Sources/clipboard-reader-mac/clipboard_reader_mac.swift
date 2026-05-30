import SwiftUI

@main
struct ClipboardReaderMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra("Clipboard Reader", systemImage: "text.bubble") {
            MenuBarView()
                .environmentObject(appModel)
        }
        .menuBarExtraStyle(.window)
    }
}
