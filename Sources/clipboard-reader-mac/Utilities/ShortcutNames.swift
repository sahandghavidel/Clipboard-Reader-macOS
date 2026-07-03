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

    static let replayScriptScene = Self(
        "replayScriptScene",
        default: KeyboardShortcuts.Shortcut(.upArrow, modifiers: [.command, .option])
    )

    static let previousScriptScene = Self(
        "previousScriptScene",
        default: KeyboardShortcuts.Shortcut(.leftArrow, modifiers: [.command, .option])
    )

    static let nextScriptScene = Self(
        "nextScriptScene",
        default: KeyboardShortcuts.Shortcut(.rightArrow, modifiers: [.command, .option])
    )

    static let togglePresenterOverlay = Self(
        "togglePresenterOverlay",
        default: KeyboardShortcuts.Shortcut(.o, modifiers: [.command, .option])
    )
}
