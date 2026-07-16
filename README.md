# Clipboard Reader (macOS)

A native macOS menu bar app that reads clipboard text, typed text, or tutorial scripts aloud with built-in speech.

Current local version: `1.24`.

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

## Script mode

Turn on **Script mode** when the text box contains a tutorial script.

- The app splits the script into sentence-based scenes.
- **Play Scene** and the read shortcut read one scene, stop, then advance to the next scene after speech finishes.
- Use **Previous**, **Replay**, **Next**, and **Restart** to control the current scene.
- Default scene shortcuts are `Command+Option+Up` for replay, `Command+Option+Left` for previous, and `Command+Option+Right` for next.
- The current scene preview shows what will be read next.

## Presenter overlay

Turn on **Show presenter overlay** inside Script mode to show previous, current, and next scenes in a floating bottom overlay. Use **Hide overlay from screen recordings** to ask macOS not to include the overlay in standard screen capture output.

The overlay settings let you adjust opacity, width, height, bottom position, horizontal position, current text size, previous/next text size, text colors, text transparency, and quick color presets. Use **Reset overlay defaults** to return to the default presenter layout.

Use the **Toggle Overlay** shortcut to show or hide the presenter overlay without opening the menu. The default shortcut is `Command+Option+O`. Turn on **Hide overlay while audio is playing** if you want the overlay visible while preparing but hidden during narration playback.

Use the **Edit Scene** button in the presenter overlay, or the **Edit Current Scene** global shortcut, to open the hidden-from-recording Scene Manager. It shows all scenes, lets you select the current scene, edit text, split, merge, and delete scenes. Merged scenes stay merged after saving and reopening the manager. The editor focuses the text box immediately; **Done** or **Escape** saves once and closes.

## External shortcut triggers

The **Global Shortcuts** section includes two separate read shortcuts:

- **Read Current Input 1**
- **Read Current Input 2**
- **Read Clipboard Always 1**
- **Read Clipboard Always 2**
- **Read Clipboard Always 3**

Both read the same current input: clipboard mode reads the clipboard, typed text mode reads the text box, and Script mode plays the current scene. Each read shortcut has its own speech speed plus options to trigger an external shortcut before reading, after reading, or both.

All **Read Clipboard Always** shortcuts ignore typed-text mode and Script mode. They always read the current macOS clipboard, and each one has its own speech speed plus before/after external trigger options.

The global read speed and shortcut-specific speeds support `0.25x` through `2.5x`.

The external trigger shortcut is configured with modifier checkboxes and a key picker. It is not registered as a global shortcut by Clipboard Reader, so it can match a shortcut that already belongs to your recording app. macOS Accessibility permission is required to send the external shortcut.

The app does not repeatedly force the Accessibility permission dialog during playback. Use **Request Accessibility Permission** only when you want macOS to show the permission prompt again.

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
  <string>24</string>
  <key>CFBundleShortVersionString</key>
  <string>1.24</string>
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
6. Turn **Script mode** on and paste a multi-sentence tutorial script.
7. Trigger **Play Scene** or the read shortcut, then confirm it reads one scene and advances to the next.
8. Use **Previous**, **Replay**, **Next**, and **Restart** to navigate scenes.
9. Use the overlay **Edit Scene** button or **Edit Current Scene** shortcut, select scenes, edit, split/merge/delete, press **Escape**, and confirm previous/current/next update.
10. Turn **Show presenter overlay** on and confirm previous/current/next scenes appear near the bottom of the screen.
11. Adjust overlay opacity, width, height, position, font sizes, text colors, and text transparency.
12. Use the **Toggle Overlay** shortcut and confirm the overlay shows/hides.
13. Turn **Hide overlay while audio is playing** on and confirm the overlay hides during speech, then returns after speech stops or finishes.
14. Use **Reset overlay defaults** and confirm the overlay returns to the default layout.
15. Start a short screen recording and verify the overlay behavior with **Hide overlay from screen recordings** on and off.
16. Trigger **Pause/Resume** once → pauses.
17. Trigger **Pause/Resume** again → resumes.
18. Trigger **Stop** → speech stops immediately.
19. Configure **Read Current Input 1** and **Read Current Input 2** with different shortcut combinations.
20. Set **Read Current Input 1** to `0.5x` and **Read Current Input 2** to `1.5x`, then verify each shortcut uses its own speed.
21. Turn **Read typed text instead of clipboard** on, then trigger **Read Clipboard Always 1**, **2**, and **3** and confirm each still reads the clipboard.
22. Enable **Trigger external shortcut before reading** and verify the recording app receives the external shortcut before speech starts.
23. Enable **Trigger external shortcut after reading** and verify the recording app receives the external shortcut after speech finishes.
24. Move speed sliders to **0.25x** and **2.5x**, verify slower/faster speech.
25. Reassign shortcuts and verify they still work globally.

## Troubleshooting

- If the menu bar icon does not appear, fully quit and relaunch.
- If a shortcut does not trigger, check for conflicts and assign a different combination.
- If no speech plays, verify your Mac output volume and selected voice.
- If build fails on older macOS, lower deployment target in `Package.swift`.

## Notes

- `swift build` and `swift build -c release` are verified in this environment.
- CLI `swift test` may fail in some environments due missing test modules/toolchain setup.
