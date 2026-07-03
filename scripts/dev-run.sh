#!/usr/bin/env bash
set -euo pipefail

APP_PROCESS_NAMES=("clipboard-reader-mac" "ClipboardReaderMac")
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Stopping existing Clipboard Reader processes..."
for process_name in "${APP_PROCESS_NAMES[@]}"; do
    if pgrep -x "$process_name" >/dev/null; then
        pkill -x "$process_name"
        echo "Stopped $process_name."
    fi
done

echo "Building debug binary..."
swift build
BINARY_DIR="$(swift build --show-bin-path)"
BINARY_PATH="$BINARY_DIR/clipboard-reader-mac"

if [[ ! -x "$BINARY_PATH" ]]; then
    echo "Build completed, but expected binary was not found:"
    echo "$BINARY_PATH"
    exit 1
fi

echo "Launching local debug build..."
echo "$BINARY_PATH"
"$BINARY_PATH"
