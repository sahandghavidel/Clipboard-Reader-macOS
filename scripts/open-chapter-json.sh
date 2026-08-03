#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    echo "Usage: scripts/open-chapter-json.sh <chapter.json>" >&2
    exit 64
fi

chapter_path="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

if [[ ! -f "$chapter_path" ]]; then
    echo "Chapter JSON not found: $chapter_path" >&2
    exit 66
fi

encoded_path="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$chapter_path")"
open "narrationpilot://import?path=$encoded_path"
