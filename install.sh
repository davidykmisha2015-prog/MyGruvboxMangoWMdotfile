#!/usr/bin/env bash
# MangoWM Gruvbox Dotfiles Installer
set -e

echo "🥭 Installing MangoWM Gruvbox Dotfiles..."

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CONFIG_DIR"

# Copy configuration folders
for app in mango waybar swaync rofi kitty; do
    if [ -d ".config/$app" ]; then
        echo " -> Installing $app config to $CONFIG_DIR/$app..."
        mkdir -p "$CONFIG_DIR/$app"
        cp -r .config/"$app"/* "$CONFIG_DIR/$app/"
    fi
done

# Ensure scripts are executable
if [ -d "$CONFIG_DIR/mango/scripts" ]; then
    chmod +x "$CONFIG_DIR/mango/scripts/"*.sh 2>/dev/null || true
fi

echo "✨ Dotfiles successfully installed!"
echo "💡 Reload MangoWM or log out and log back in to apply changes."
