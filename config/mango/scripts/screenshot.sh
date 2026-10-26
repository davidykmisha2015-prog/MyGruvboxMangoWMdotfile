#!/usr/bin/env bash
# ==============================================================================
#  MangoWM Screenshot Utility with Auto-Clipboard & Satty Annotation
# ==============================================================================

# Ensure Screenshots directory exists
mkdir -p "$HOME/Pictures/Screenshots"

# Select region with slurp
GEOM=$(slurp 2>/dev/null)

# Exit cleanly if cancelled (Esc or clicked outside)
if [ -z "$GEOM" ]; then
    exit 0
fi

# Create temporary file for screenshot
TEMP_SHOT=$(mktemp --suffix=.png /tmp/screenshot_XXXXXX)
grim -g "$GEOM" "$TEMP_SHOT"

# Ensure image was captured
if [ ! -s "$TEMP_SHOT" ]; then
    rm -f "$TEMP_SHOT"
    exit 1
fi

# 1. Automatically copy raw screenshot to Wayland clipboard immediately
wl-copy -t image/png < "$TEMP_SHOT"

# 2. Show notification with thumbnail
notify-send -a "Скріншот" -i "$TEMP_SHOT" "Скріншот скопійовано" "Зображення вже у буфері обміну (Ctrl+V)"

# 3. Open in Satty for optional annotations/drawing
satty --filename "$TEMP_SHOT" \
      --output-filename "$HOME/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png" \
      --copy-command "wl-copy" \
      --early-exit copy

# Clean up temp file
rm -f "$TEMP_SHOT"
