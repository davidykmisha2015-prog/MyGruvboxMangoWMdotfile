#!/usr/bin/env bash
# ==============================================================================
#  🛡️ RAM Guardian for MangoWM
#  Protects system from hard OOM freezes by alerting before memory exhaustion
# ==============================================================================

COOLDOWN_WARN=60
COOLDOWN_CRIT=20
LAST_WARN=0
LAST_CRIT=0

# Clean exit on signals
trap "exit 0" SIGINT SIGTERM

while true; do
    TOTAL_KB=0
    AVAIL_KB=0

    # Read memory info efficiently from /proc/meminfo
    while read -r key val _; do
        case "$key" in
            MemTotal:) TOTAL_KB="$val" ;;
            MemAvailable:) AVAIL_KB="$val" ;;
        esac
    done < /proc/meminfo

    if [ "$TOTAL_KB" -gt 0 ]; then
        USED_KB=$((TOTAL_KB - AVAIL_KB))
        PERCENT=$((USED_KB * 100 / TOTAL_KB))
        AVAIL_MB=$((AVAIL_KB / 1024))
        NOW=$(date +%s)

        # Critical: >= 92% or less than 800 MB available
        if [ "$PERCENT" -ge 92 ] || [ "$AVAIL_MB" -lt 800 ]; then
            if [ $((NOW - LAST_CRIT)) -ge "$COOLDOWN_CRIT" ]; then
                # Find the top non-critical process consuming the most RAM
                TOP_HOG=$(ps -eo pid,comm,%mem --sort=-%mem | grep -vE "mango|Xwayland|waybar|swaync|dbus|systemd|pipewire|wireplumber|bwrap|sh|bash" | head -n 2 | tail -n 1)
                HOG_PID=$(echo "$TOP_HOG" | awk '{print $1}')
                HOG_NAME=$(echo "$TOP_HOG" | awk '{print $2}')
                HOG_MEM=$(echo "$TOP_HOG" | awk '{print $3}')

                notify-send -u critical -i dialog-error -a "RAM Guardian" \
                    "🚨 КРИТИЧНИЙ РІВЕНЬ ПАМ'ЯТІ (${PERCENT}%)" \
                    "Залишилося лише ${AVAIL_MB} МБ! Загроза зависання!\nГоловний процес: <b>${HOG_NAME}</b> (PID: ${HOG_PID}, ${HOG_MEM}% RAM)\nЗбережи роботу і закрий важкі програми!"
                
                LAST_CRIT=$NOW
                LAST_WARN=$NOW
            fi
        # Warning: >= 78% or less than 2500 MB available
        elif [ "$PERCENT" -ge 78 ] || [ "$AVAIL_MB" -lt 2500 ]; then
            if [ $((NOW - LAST_WARN)) -ge "$COOLDOWN_WARN" ]; then
                notify-send -u normal -i dialog-warning -a "RAM Guardian" \
                    "⚠️ Пам'ять заповнена на ${PERCENT}%" \
                    "Залишилося ${AVAIL_MB} МБ вільної оперативки.\nЗакрий непотрібні вкладки браузера або проекти."
                LAST_WARN=$NOW
            fi
        fi
    fi

    sleep 3
done
