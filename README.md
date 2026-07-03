# Clipboard Reader (macOS)

A native macOS menu bar app that reads clipboard text or typed text aloud with built-in speech.

Current local version: `1.5`.

## Requirements

- Apple Silicon Mac
- macOS 15+ (this project currently targets `macOS(.v15)`)
- Xcode + Command Line Tools

## Fastest way to develop

Use the local development runner while changing code. It quits any existing copy of the app, rebuilds this project, and launches the newest debug binary directly from `.build`.

```bash
cd /Users/sahand/Desktop/projects-test/clipboard-reader-mac
./scripts/dev-run.sh
```

When you change code, quit the menu bar app or stop the terminal command, then run the same script again. You do not need to reinstall the `.app` package while developing.

If you want to test the optimized release binary without installing it:

```bash
./scripts/dev-release-run.sh
```

Important: if you installed `ClipboardReaderMac.app` in `~/Applications`, make sure it is not still running while testing local builds. Otherwise you may be looking at the old installed app instead of the newest code.

## Reading modes

The menu bar app has a toggle named **Read typed text instead of clipboard**.

- Toggle off: **Read Clipboard** and the read shortcut use the macOS clipboard.
- Toggle on: **Read Text** and the same read shortcut use the text typed into the app.
- Stop, pause/resume, speed, voice, and shortcut settings work the same in both modes.
- Typed text is not saved when the app quits.

### Run from VS Code

1. Open this folder in VS Code.
2. Open **Terminal > Run Task...**.
3. Choose **Dev Run Clipboard Reader**.
4. Look for the app in your menu bar.

You can still use **Run and Debug** with the existing debug configuration, but the task is better when you want the old running app to be stopped automatically first.

## Other ways to run

### Run from VS Code debugger

1. Open this folder in VS Code.
2. Open **Run and Debug**.
3. Choose **Debug clipboard-reader-mac**.
4. Start debugging.
5. Look for the app in your menu bar.

### Run manually from Terminal

```bash
cd /Users/sahand/Desktop/projects-test/clipboard-reader-mac
swift build
./.build/arm64-apple-macosx/debug/clipboard-reader-mac
```

To stop it, use the app's **Quit** menu item (or `Ctrl+C` in Terminal).

## Create a local "installed" app (.app)

This project is currently a Swift Package executable. You can still make a local `.app` wrapper for easy launching after you are happy with a version. The installed app is a copied build artifact; it will not update automatically when you edit source files.

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
  <string>5</string>
  <key>CFBundleShortVersionString</key>
  <string>1.5</string>
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
2. Leave **Read typed text instead of clipboard** off.
3. Trigger **Read Clipboard** (button or shortcut), then confirm speech starts.
4. Turn **Read typed text instead of clipboard** on and type text into the app.
5. Trigger **Read Text** (button or same shortcut), then confirm it reads typed text instead of clipboard.
6. Trigger **Pause/Resume** once → pauses.
7. Trigger **Pause/Resume** again → resumes.
8. Trigger **Stop** → speech stops immediately.
9. Move speed slider to **0.5x** and **1.5x**, verify slower/faster speech.
10. Reassign all 3 shortcuts and verify they still work globally.

## Troubleshooting

- If the menu bar icon does not appear, fully quit and relaunch.
- If a shortcut does not trigger, check for conflicts and assign a different combination.
- If no speech plays, verify your Mac output volume and selected voice.
- If build fails on older macOS, lower deployment target in `Package.swift`.

## Notes

- `swift build` and `swift build -c release` are verified in this environment.
- CLI `swift test` may fail in some environments due missing test modules/toolchain setup.
