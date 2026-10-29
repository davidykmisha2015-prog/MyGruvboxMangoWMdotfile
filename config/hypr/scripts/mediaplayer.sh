#!/usr/bin/env bash

STATUS=$(playerctl status 2>/dev/null)

if [ "$STATUS" = "Playing" ]; then
    ICON="󰐊"
elif [ "$STATUS" = "Paused" ]; then
    ICON="󰏤"
else
    exit 0
fi

ARTIST=$(playerctl metadata --format "{{ artist }}" 2>/dev/null)
TITLE=$(playerctl metadata --format "{{ title }}" 2>/dev/null)

if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
    INFO="$ARTIST — $TITLE"
elif [ -n "$TITLE" ]; then
    INFO="$TITLE"
else
    INFO="Медіа грає"
fi

if [ ${#INFO} -gt 50 ]; then
    INFO="${INFO:0:47}..."
fi

echo "󰝚  $INFO  $ICON"
