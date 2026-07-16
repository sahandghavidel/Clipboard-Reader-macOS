# Narration Pilot

Narration Pilot is a native macOS menu bar companion for scene-by-scene narration and screen-recording workflows. Paste or type a script, organize it into scenes, play each scene with macOS speech, and control the session with global shortcuts while you record.

Current version: `1.25`

## Features

- Clipboard, typed-text, and scene-based script reading
- Automatic sentence-based scene splitting
- Scene Manager for editing, splitting, merging, deleting, and selecting scenes
- Previous, replay, next, and restart controls
- Presenter overlay with previous, current, and next scene context
- Optional capture-hidden overlay and Scene Manager windows
- Adjustable voice, speech rate, colors, sizes, position, and opacity
- Configurable global shortcuts with per-shortcut speech speeds
- Optional external shortcut triggers before or after narration
- Bracketed production directions skipped during normal playback and included during Replay Scene
- Local-first operation using macOS speech services

## Requirements

- macOS 15 or newer
- Xcode and the Xcode Command Line Tools
- Apple Silicon is the currently tested architecture

## Build from source

```bash
git clone https://github.com/sahandghavidel/narration-pilot.git
cd narration-pilot
swift build
```

Launch the latest debug build:

```bash
./scripts/dev-run.sh
```

Launch an optimized release build without installing an app bundle:

```bash
./scripts/dev-release-run.sh
```

The raw SwiftPM executable and the installed app use different macOS preferences domains. Use the installed app for your normal workflow if you want to keep one stable set of shortcuts and settings.

## Install a local app bundle

```bash
./scripts/install-local-app.sh
```

This installs `Narration Pilot.app` in `~/Applications`. Upgrades retain the legacy `local.clipboardreadermac` bundle identifier so existing Clipboard Reader users keep their shortcuts and settings after renaming.

## Using Narration Pilot

### Reading modes

- Leave **Read typed text instead of clipboard** off to read the current clipboard.
- Turn it on to read text entered in the app.
- Turn on **Script mode** to split a tutorial script into scenes and play one scene at a time.

### Scene workflow

Normal scene playback skips production directions enclosed in square brackets. **Replay Scene** reads the complete scene, including bracketed directions.

Use **Previous**, **Replay**, **Next**, and **Restart** to navigate. Open **Edit Current Scene** to select, edit, split, merge, or delete scenes. Manual scene boundaries are retained until the raw script is changed directly.

### Presenter overlay

The overlay shows the previous, current, and next scenes. It supports custom sizing, placement, opacity, typography, and colors. It can also be hidden from standard macOS screen capture or hidden automatically while speech is playing.

### Shortcuts and recording triggers

Narration Pilot provides two shortcuts for reading the current input and three shortcuts that always read the clipboard. Each read shortcut can use a different speed and optionally send a configured recording shortcut before speech, after speech, or both.

Sending external shortcuts requires macOS Accessibility permission.

## VS Code

Open the repository and choose one of these tasks from **Terminal > Run Task**:

- **Dev Run Narration Pilot**
- **Dev Release Run Narration Pilot**

The Run and Debug panel also includes debug and release configurations for the `NarrationPilot` executable.

## Testing

```bash
swift build
swift build -c release
swift test
```

Some standalone Swift toolchains may not provide XCTest. In that environment the executable builds still work, but `swift test` reports `no such module 'XCTest'`.

## Privacy

Narration Pilot is local-first. Script text is passed to macOS speech services and is not uploaded by this project. The app does not include analytics, accounts, advertising, or remote storage.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

Narration Pilot is available under the [MIT License](LICENSE).
