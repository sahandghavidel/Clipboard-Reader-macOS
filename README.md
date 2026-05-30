# Clipboard Reader (macOS)

A native macOS menu bar app that reads your clipboard text aloud with built-in speech.

## Requirements

- Apple Silicon Mac
- macOS 15+ (this project currently targets `macOS(.v15)`)
- Xcode + Command Line Tools

## Fastest way to run (beginner-friendly)

### Option A: Run from VS Code

1. Open this folder in VS Code.
2. Open **Run and Debug**.
3. Choose **Debug clipboard-reader-mac**.
4. Start debugging.
5. Look for the app in your menu bar.

### Option B: Run from Terminal

```bash
cd /Users/sahand/Desktop/projects-test/clipboard-reader-mac
swift build
./.build/arm64-apple-macosx/debug/clipboard-reader-mac
```

To stop it, use the app's **Quit** menu item (or `Ctrl+C` in Terminal).

## Create a local "installed" app (.app)

This project is currently a Swift Package executable. You can still make a local `.app` wrapper for easy launching.

```bash
cd /Users/sahand/Desktop/projects-test/clipboard-reader-mac
swift build -c release
mkdir -p "$HOME/Applications/ClipboardReaderMac.app/Contents/MacOS"
mkdir -p "$HOME/Applications/ClipboardReaderMac.app/Contents/Resources"
cp ./.build/arm64-apple-macosx/release/clipboard-reader-mac "$HOME/Applications/ClipboardReaderMac.app/Contents/MacOS/ClipboardReaderMac"
cat > "$HOME/Applications/ClipboardReaderMac.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>ClipboardReaderMac</string>
  <key>CFBundleDisplayName</key>
  <string>ClipboardReaderMac</string>
  <key>CFBundleIdentifier</key>
  <string>local.clipboardreadermac</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>ClipboardReaderMac</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST
chmod +x "$HOME/Applications/ClipboardReaderMac.app/Contents/MacOS/ClipboardReaderMac"
codesign --force --deep --sign - "$HOME/Applications/ClipboardReaderMac.app"
open "$HOME/Applications/ClipboardReaderMac.app"
```

After this, you can launch it from Spotlight/Finder like a normal app.

## Manual test checklist

1. Copy text in any app.
2. Trigger **Read Clipboard** (button or shortcut).
3. Confirm speech starts.
4. Trigger **Pause/Resume** once → pauses.
5. Trigger **Pause/Resume** again → resumes.
6. Trigger **Stop** → speech stops immediately.
7. Move speed slider to **0.5x** and **1.5x**, verify slower/faster speech.
8. Reassign all 3 shortcuts and verify they still work globally.

## Troubleshooting

- If the menu bar icon does not appear, fully quit and relaunch.
- If a shortcut does not trigger, check for conflicts and assign a different combination.
- If no speech plays, verify your Mac output volume and selected voice.
- If build fails on older macOS, lower deployment target in `Package.swift`.

## Notes

- `swift build` and `swift build -c release` are verified in this environment.
- CLI `swift test` may fail in some environments due missing test modules/toolchain setup.
