import AppKit
import Foundation

struct TriggerShortcut: Codable, Equatable {
    struct KeyOption: Identifiable, Equatable {
        let keyCode: Int
        let label: String

        var id: Int {
            keyCode
        }
    }

    let keyCode: Int
    let modifierFlagsRawValue: UInt
    let keyDisplay: String

    var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlagsRawValue)
    }

    var displayName: String {
        let modifierText = Self.displayName(for: modifiers)
        return modifierText.isEmpty ? keyDisplay : "\(modifierText)\(keyDisplay)"
    }

    init(keyOption: KeyOption, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyOption.keyCode
        self.modifierFlagsRawValue = Self.filteredModifiers(modifiers).rawValue
        self.keyDisplay = keyOption.label
    }

    static let defaultKeyOption = KeyOption(keyCode: 51, label: "Backspace")

    static let keyOptions: [KeyOption] = [
        KeyOption(keyCode: 0, label: "A"),
        KeyOption(keyCode: 11, label: "B"),
        KeyOption(keyCode: 8, label: "C"),
        KeyOption(keyCode: 2, label: "D"),
        KeyOption(keyCode: 14, label: "E"),
        KeyOption(keyCode: 3, label: "F"),
        KeyOption(keyCode: 5, label: "G"),
        KeyOption(keyCode: 4, label: "H"),
        KeyOption(keyCode: 34, label: "I"),
        KeyOption(keyCode: 38, label: "J"),
        KeyOption(keyCode: 40, label: "K"),
        KeyOption(keyCode: 37, label: "L"),
        KeyOption(keyCode: 46, label: "M"),
        KeyOption(keyCode: 45, label: "N"),
        KeyOption(keyCode: 31, label: "O"),
        KeyOption(keyCode: 35, label: "P"),
        KeyOption(keyCode: 12, label: "Q"),
        KeyOption(keyCode: 15, label: "R"),
        KeyOption(keyCode: 1, label: "S"),
        KeyOption(keyCode: 17, label: "T"),
        KeyOption(keyCode: 32, label: "U"),
        KeyOption(keyCode: 9, label: "V"),
        KeyOption(keyCode: 13, label: "W"),
        KeyOption(keyCode: 7, label: "X"),
        KeyOption(keyCode: 16, label: "Y"),
        KeyOption(keyCode: 6, label: "Z"),
        KeyOption(keyCode: 29, label: "0"),
        KeyOption(keyCode: 18, label: "1"),
        KeyOption(keyCode: 19, label: "2"),
        KeyOption(keyCode: 20, label: "3"),
        KeyOption(keyCode: 21, label: "4"),
        KeyOption(keyCode: 23, label: "5"),
        KeyOption(keyCode: 22, label: "6"),
        KeyOption(keyCode: 26, label: "7"),
        KeyOption(keyCode: 28, label: "8"),
        KeyOption(keyCode: 25, label: "9"),
        KeyOption(keyCode: 51, label: "Backspace"),
        KeyOption(keyCode: 117, label: "Forward Delete"),
        KeyOption(keyCode: 36, label: "Return"),
        KeyOption(keyCode: 48, label: "Tab"),
        KeyOption(keyCode: 49, label: "Space"),
        KeyOption(keyCode: 53, label: "Escape"),
        KeyOption(keyCode: 123, label: "Left Arrow"),
        KeyOption(keyCode: 124, label: "Right Arrow"),
        KeyOption(keyCode: 125, label: "Down Arrow"),
        KeyOption(keyCode: 126, label: "Up Arrow"),
        KeyOption(keyCode: 122, label: "F1"),
        KeyOption(keyCode: 120, label: "F2"),
        KeyOption(keyCode: 99, label: "F3"),
        KeyOption(keyCode: 118, label: "F4"),
        KeyOption(keyCode: 96, label: "F5"),
        KeyOption(keyCode: 97, label: "F6"),
        KeyOption(keyCode: 98, label: "F7"),
        KeyOption(keyCode: 100, label: "F8"),
        KeyOption(keyCode: 101, label: "F9"),
        KeyOption(keyCode: 109, label: "F10"),
        KeyOption(keyCode: 103, label: "F11"),
        KeyOption(keyCode: 111, label: "F12"),
        KeyOption(keyCode: 105, label: "F13"),
        KeyOption(keyCode: 107, label: "F14"),
        KeyOption(keyCode: 113, label: "F15"),
        KeyOption(keyCode: 106, label: "F16"),
        KeyOption(keyCode: 64, label: "F17"),
        KeyOption(keyCode: 79, label: "F18"),
        KeyOption(keyCode: 80, label: "F19"),
        KeyOption(keyCode: 90, label: "F20"),
    ]

    static func keyOption(for keyCode: Int) -> KeyOption {
        keyOptions.first { $0.keyCode == keyCode } ?? defaultKeyOption
    }

    static func filteredModifiers(_ modifiers: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        modifiers.intersection([.command, .option, .control, .shift])
    }

    private static func displayName(for modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []

        if modifiers.contains(.control) {
            parts.append("Control")
        }

        if modifiers.contains(.option) {
            parts.append("Option")
        }

        if modifiers.contains(.shift) {
            parts.append("Shift")
        }

        if modifiers.contains(.command) {
            parts.append("Command")
        }

        return parts.isEmpty ? "" : "\(parts.joined(separator: "+"))+"
    }
}
