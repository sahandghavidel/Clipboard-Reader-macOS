#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <project.focusee> [minimum-seconds]" >&2
    exit 64
fi

PROJECT_PATH="${1%/}"
MINIMUM_SECONDS="${2:-3}"

if [[ ! -d "$PROJECT_PATH" || "$PROJECT_PATH" != *.focusee ]]; then
    echo "Expected a FocuSee project directory ending in .focusee: $PROJECT_PATH" >&2
    exit 66
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required." >&2
    exit 69
fi

if ! [[ "$MINIMUM_SECONDS" =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] || ! awk -v value="$MINIMUM_SECONDS" 'BEGIN { exit !(value > 0) }'; then
    echo "Minimum duration must be a number greater than zero." >&2
    exit 64
fi

CONFIG_FILES=(
    "$PROJECT_PATH/configure.focuseeproj"
    "$PROJECT_PATH/.configure.focuseeproj.autosave"
)

BACKUP_PATH="$PROJECT_PATH/.zoom-duration-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_PATH"

UPDATED_FILES=0
UPDATED_ZOOMS=0

for CONFIG_PATH in "${CONFIG_FILES[@]}"; do
    if [[ ! -f "$CONFIG_PATH" ]]; then
        continue
    fi

    ZOOM_COUNT="$(jq '(.zoomTracks // []) | length' "$CONFIG_PATH")"
    if [[ "$ZOOM_COUNT" -eq 0 ]]; then
        continue
    fi

    cp -p "$CONFIG_PATH" "$BACKUP_PATH/$(basename "$CONFIG_PATH")"

    CHANGED_COUNT="$(jq --argjson minimum "$MINIMUM_SECONDS" '
        (.zoomTracks // []) as $tracks
        | [range(0; ($tracks | length)) as $index
            | $tracks[$index]
            | select(.duration > 0)
            | ((.end - .begin) * .duration) as $seconds
            | ([1, (if $index + 1 < ($tracks | length) then $tracks[$index + 1].begin else 1 end)] | min) as $limit
            | select($seconds < $minimum and .end < $limit)
        ] | length
    ' "$CONFIG_PATH")"

    if [[ "$CHANGED_COUNT" -eq 0 ]]; then
        continue
    fi

    TEMP_PATH="$(mktemp "$PROJECT_PATH/.zoom-duration.XXXXXX")"
    jq --argjson minimum "$MINIMUM_SECONDS" '
        (.zoomTracks // []) as $tracks
        | .zoomTracks = [
            range(0; ($tracks | length)) as $index
            | $tracks[$index]
            | if .duration > 0 then
                ((.end - .begin) * .duration) as $seconds
                | ([1, (if $index + 1 < ($tracks | length) then $tracks[$index + 1].begin else 1 end)] | min) as $limit
                | if $seconds < $minimum then
                    .end = ([.begin + ($minimum / .duration), $limit] | min)
                    | .isAutoZoom2D = false
                    | .isAutoZoom3D = false
                  else . end
              else . end
        ]
    ' "$CONFIG_PATH" > "$TEMP_PATH"

    chmod --reference="$CONFIG_PATH" "$TEMP_PATH" 2>/dev/null || true
    mv "$TEMP_PATH" "$CONFIG_PATH"

    if [[ "$(basename "$CONFIG_PATH")" == ".configure.focuseeproj.autosave" ]]; then
        MAIN_CONFIG_PATH="$PROJECT_PATH/configure.focuseeproj"
        if [[ -f "$MAIN_CONFIG_PATH" && ! -f "$BACKUP_PATH/configure.focuseeproj" ]]; then
            cp -p "$MAIN_CONFIG_PATH" "$BACKUP_PATH/configure.focuseeproj"
        fi
        if [[ -f "$MAIN_CONFIG_PATH" ]]; then
            MAIN_TEMP_PATH="$(mktemp "$PROJECT_PATH/.zoom-duration-main.XXXXXX")"
            jq --slurpfile zoom_config "$CONFIG_PATH" \
                '.zoomTracks = $zoom_config[0].zoomTracks' \
                "$MAIN_CONFIG_PATH" > "$MAIN_TEMP_PATH"
            chmod --reference="$MAIN_CONFIG_PATH" "$MAIN_TEMP_PATH" 2>/dev/null || true
            mv "$MAIN_TEMP_PATH" "$MAIN_CONFIG_PATH"
        else
            cp -p "$CONFIG_PATH" "$MAIN_CONFIG_PATH"
        fi
    fi

    UPDATED_FILES=$((UPDATED_FILES + 1))
    UPDATED_ZOOMS=$((UPDATED_ZOOMS + CHANGED_COUNT))
done

if [[ "$UPDATED_FILES" -eq 0 ]]; then
    rmdir "$BACKUP_PATH"
    echo "No zooms needed updating."
    exit 0
fi

echo "Updated $UPDATED_ZOOMS zooms across $UPDATED_FILES configuration file(s)."
echo "Requested minimum: $MINIMUM_SECONDS seconds"
echo "Backup: $BACKUP_PATH"
