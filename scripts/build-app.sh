#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONFIGURATION="${1:-release}"

case "$CONFIGURATION" in
    debug|release) ;;
    *)
        echo "Usage: scripts/build-app.sh [debug|release]" >&2
        exit 64
        ;;
esac

cd "$REPO_ROOT"

swift build -c "$CONFIGURATION"
BINARY_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_PATH=".build/app/$CONFIGURATION/Narration Pilot.app"
CONTENTS_PATH="$APP_PATH/Contents"

mkdir -p "$CONTENTS_PATH/MacOS" "$CONTENTS_PATH/Resources"
cp "$BINARY_DIR/NarrationPilot" "$CONTENTS_PATH/MacOS/NarrationPilot"
find "$CONTENTS_PATH/Resources" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

while IFS= read -r -d '' resource_bundle; do
    cp -R "$resource_bundle" "$CONTENTS_PATH/Resources/"
done < <(find "$BINARY_DIR" -maxdepth 1 -type d -name '*.bundle' -print0)

cat > "$CONTENTS_PATH/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Narration Pilot</string>
  <key>CFBundleDisplayName</key>
  <string>Narration Pilot</string>
  <key>CFBundleIdentifier</key>
  <string>local.clipboardreadermac</string>
  <key>CFBundleVersion</key>
  <string>26</string>
  <key>CFBundleShortVersionString</key>
  <string>1.26</string>
  <key>CFBundleExecutable</key>
  <string>NarrationPilot</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

chmod +x "$CONTENTS_PATH/MacOS/NarrationPilot"
codesign --force --deep --sign - --timestamp=none "$APP_PATH"

echo "$APP_PATH"
