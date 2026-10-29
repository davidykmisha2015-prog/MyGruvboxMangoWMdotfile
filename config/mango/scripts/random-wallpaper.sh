#!/usr/bin/env bash

# Папка зі шпалерами
WALL_DIR="$HOME/Pictures/wallpapers"

# Перевірка наявності папки
if [ ! -d "$WALL_DIR" ]; then
    mkdir -p "$WALL_DIR"
fi

# Визначаємо доступну утиліту для шпалер (awww або swww)
if command -v awww >/dev/null 2>&1; then
    WALL_CMD="awww"
    WALL_DAEMON="awww-daemon"
elif command -v swww >/dev/null 2>&1; then
    WALL_CMD="swww"
    WALL_DAEMON="swww-daemon"
else
    notify-send -u critical "Шпалери" "Не знайдено awww або swww! Встановіть swww або awww."
    exit 1
fi

# Запуск демона, якщо він ще не запущений
if ! $WALL_CMD query >/dev/null 2>&1; then
    $WALL_DAEMON &
    sleep 0.5
fi

# Отримуємо поточні шпалери
CURRENT_WALL=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)

# Список усіх зображень
shopt -s nullglob
WALLPAPERS=("$WALL_DIR"/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP})
shopt -u nullglob

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send -u low "Шпалери" "Папка $WALL_DIR порожня!"
    exit 1
fi

# Фільтруємо, щоб не обрати поточні шпалери повторно
CANDIDATES=()
for w in "${WALLPAPERS[@]}"; do
    if [ "$w" != "$CURRENT_WALL" ]; then
        CANDIDATES+=("$w")
    fi
done

if [ ${#CANDIDATES[@]} -eq 0 ]; then
    CANDIDATES=("${WALLPAPERS[@]}")
fi

# Вибираємо випадкові нові шпалери
NEW_WALL="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"

# Список ефектних анімацій
TRANSITIONS=("grow" "outer" "wave" "wipe" "center" "any" "fade")
CHOSEN_TRANS="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"

# Випадкові позиції появи (для grow / outer)
POSITIONS=("center" "top" "bottom" "left" "right" "top-left" "top-right" "bottom-left" "bottom-right")
CHOSEN_POS="${POSITIONS[RANDOM % ${#POSITIONS[@]}]}"

# Випадковий кут (для wave / wipe)
CHOSEN_ANGLE=$((RANDOM % 360))

# Встановлюємо шпалери з обраною анімацією на 165 Гц
$WALL_CMD img "$NEW_WALL" \
    --transition-type "$CHOSEN_TRANS" \
    --transition-pos "$CHOSEN_POS" \
    --transition-angle "$CHOSEN_ANGLE" \
    --transition-duration 1.5 \
    --transition-fps 165 \
    --transition-bezier .54,0,.34,.99

# Запам'ятовуємо поточні
mkdir -p "$HOME/.cache"
echo "$NEW_WALL" > "$HOME/.cache/current_wallpaper"

# Сповіщення з назвою та прев'ю
WALL_NAME=$(basename "$NEW_WALL")
notify-send -i "$NEW_WALL" "🎨 Шпалери змінено" "$WALL_NAME\nЕфект: $CHOSEN_TRANS" -a "Шпалери" -t 2000
