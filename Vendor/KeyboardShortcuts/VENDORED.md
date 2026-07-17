# Vendored KeyboardShortcuts

This directory contains KeyboardShortcuts 1.9.4 by Sindre Sorhus, originally
published at <https://github.com/sindresorhus/KeyboardShortcuts>.

Narration Pilot vendors this pinned version so its localized resource bundle
can be resolved from `Contents/Resources` when the SwiftPM executable is
packaged as a signed macOS application. The upstream license is preserved in
`license`.

The Narration Pilot-specific change is in
`Sources/KeyboardShortcuts/Utilities.swift`: localization first checks the
standard macOS application resource directory and falls back to SwiftPM's
generated `Bundle.module` lookup for development and tests.
