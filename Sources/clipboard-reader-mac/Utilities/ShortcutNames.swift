@preconcurrency import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let readClipboard = Self(
        "readClipboard",
        default: KeyboardShortcuts.Shortcut(.r, modifiers: [.command, .option])
    )

    static let stopReading = Self(
        "stopReading",
        default: KeyboardShortcuts.Shortcut(.s, modifiers: [.command, .option])
    )

    static let pauseResumeReading = Self(
        "pauseResumeReading",
        default: KeyboardShortcuts.Shortcut(.p, modifiers: [.command, .option])
    )
}