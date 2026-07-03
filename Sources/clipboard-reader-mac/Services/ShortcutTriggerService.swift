import AppKit
import ApplicationServices
import Foundation

struct ShortcutTriggerService {
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityTrustPrompt() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func trigger(_ shortcut: TriggerShortcut) -> Bool {
        guard Self.isAccessibilityTrusted else {
            return false
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyCode = CGKeyCode(shortcut.keyCode)
        let flags = cgEventFlags(from: shortcut.modifiers)

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else {
            return false
        }

        keyDown.flags = flags
        keyDown.post(tap: .cghidEventTap)

        keyUp.flags = flags
        keyUp.post(tap: .cghidEventTap)

        return true
    }

    private func cgEventFlags(from modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags = CGEventFlags()

        if modifiers.contains(.command) {
            flags.insert(.maskCommand)
        }

        if modifiers.contains(.option) {
            flags.insert(.maskAlternate)
        }

        if modifiers.contains(.control) {
            flags.insert(.maskControl)
        }

        if modifiers.contains(.shift) {
            flags.insert(.maskShift)
        }

        return flags
    }
}
