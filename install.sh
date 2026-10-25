#!/usr/bin/env bash
# ==============================================================================
#  🥭 MangoWM Gruvbox Dotfiles Installer
#  Author: David (davidykmisha2015-prog)
#  License: MIT
# ==============================================================================

set -e

# Colors for terminal styling
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_ORANGE="\033[38;2;214;93;14m"   # Gruvbox Orange
COLOR_YELLOW="\033[38;2;250;189;47m"  # Gruvbox Yellow
COLOR_GREEN="\033[38;2;184;187;38m"   # Gruvbox Green
COLOR_AQUA="\033[38;2;131;165;152m"   # Gruvbox Aqua
COLOR_GRAY="\033[38;2;168;153;132m"   # Gruvbox Gray
COLOR_RED="\033[38;2;251;73;52m"      # Gruvbox Red

echo -e "${COLOR_ORANGE}${COLOR_BOLD}"
echo "    ███╗   ███╗ █████╗ ███╗   ██╗ ██████╗  ██████╗ ██╗    ██╗███╗   ███╗"
echo "    ████╗ ████║██╔══██╗████╗  ██║██╔════╝ ██╔═══██╗██║    ██║████╗ ████║"
echo "    ██╔████╔██║███████║██╔██╗ ██║██║  ███╗██║   ██║██║ █╗ ██║██╔████╔██║"
echo "    ██║╚██╔╝██║██╔══██║██║╚██╗██║██║   ██║██║   ██║██║███╗██║██║╚██╔╝██║"
echo "    ██║ ╚═╝ ██║██║  ██║██║ ╚████║╚██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚═╝ ██║"
echo "    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝     ╚═╝"
echo -e "${COLOR_YELLOW}             🥭 Gruvbox Dark Rice Installer by Misha 🥭${COLOR_RESET}\n"

# Determine source directory (local clone or curl execution)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
TEMP_DIR=""

if [ -d "$SCRIPT_DIR/config/mango" ]; then
    SOURCE_CONFIG="$SCRIPT_DIR/config"
elif [ -d "$SCRIPT_DIR/.config/mango" ]; then
    SOURCE_CONFIG="$SCRIPT_DIR/.config"
else
    echo -e "${COLOR_AQUA}⬇️  Remote installation detected! Cloning repository...${COLOR_RESET}"
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/davidykmisha2015-prog/mangowm-dotfiles.git "$TEMP_DIR"
    if [ -d "$TEMP_DIR/config" ]; then
        SOURCE_CONFIG="$TEMP_DIR/config"
    else
        SOURCE_CONFIG="$TEMP_DIR/.config"
    fi
fi

CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.config/mangowm_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_MADE=false

echo -e "${COLOR_BOLD}Target Configuration Directory:${COLOR_RESET} ${COLOR_AQUA}$CONFIG_TARGET${COLOR_RESET}"
echo ""

# Ask user confirmation
read -r -p "Do you want to proceed with the installation? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${COLOR_RED}❌ Installation aborted by user.${COLOR_RESET}"
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    exit 0
fi

echo ""
echo -e "${COLOR_YELLOW}📦 Checking for existing configs to backup...${COLOR_RESET}"

# Backup existing configs if present
for item in mango waybar swaync rofi kitty; do
    if [ -d "$CONFIG_TARGET/$item" ]; then
        if [ "$BACKUP_MADE" = false ]; then
            mkdir -p "$BACKUP_DIR"
            BACKUP_MADE=true
        fi
        echo -e "   ${COLOR_GRAY}Backing up existing${COLOR_RESET} $item ${COLOR_GRAY}-> $BACKUP_DIR/$item${COLOR_RESET}"
        cp -r "$CONFIG_TARGET/$item" "$BACKUP_DIR/"
    fi
done

if [ "$BACKUP_MADE" = true ]; then
    echo -e "${COLOR_GREEN}✅ Existing configs safely backed up in:${COLOR_RESET} $BACKUP_DIR"
else
    echo -e "${COLOR_GRAY}No existing conflicting configs found.${COLOR_RESET}"
fi

echo ""
echo -e "${COLOR_ORANGE}🚀 Installing new dotfiles...${COLOR_RESET}"

mkdir -p "$CONFIG_TARGET"

for app in mango waybar swaync rofi kitty; do
    if [ -d "$SOURCE_CONFIG/$app" ]; then
        echo -e "   ${COLOR_AQUA}Installing:${COLOR_RESET} $CONFIG_TARGET/$app"
        mkdir -p "$CONFIG_TARGET/$app"
        cp -r "$SOURCE_CONFIG/$app"/* "$CONFIG_TARGET/$app/"
    fi
done

# Ensure scripts inside mango are executable
if [ -d "$CONFIG_TARGET/mango/scripts" ]; then
    chmod +x "$CONFIG_TARGET/mango/scripts/"*.sh 2>/dev/null || true
fi

# Install curated Gruvbox wallpapers
WALL_SRC=""
if [ -d "$SCRIPT_DIR/wallpapers" ]; then
    WALL_SRC="$SCRIPT_DIR/wallpapers"
elif [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR/wallpapers" ]; then
    WALL_SRC="$TEMP_DIR/wallpapers"
fi

if [ -n "$WALL_SRC" ]; then
    echo -e "   ${COLOR_AQUA}Installing wallpapers:${COLOR_RESET} $HOME/Pictures/wallpapers"
    mkdir -p "$HOME/Pictures/wallpapers"
    cp -r "$WALL_SRC"/* "$HOME/Pictures/wallpapers/"
fi

# Clean up temporary directory if used
[ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"

echo ""
echo -e "${COLOR_YELLOW}🔍 Checking required dependencies on your system:${COLOR_RESET}"
DEPS=("mangowm" "waybar" "swaync" "rofi" "kitty" "awww")
MISSING=()

for dep in "${DEPS[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo -e "   [${COLOR_GREEN}✓${COLOR_RESET}] $dep is installed"
    else
        echo -e "   [${COLOR_RED}✗${COLOR_RESET}] $dep is ${COLOR_RED}NOT${COLOR_RESET} installed"
        MISSING+=("$dep")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo -e "${COLOR_YELLOW}⚠️  Some tools are missing (${MISSING[*]}).${COLOR_RESET}"
    echo "   Install them using your package manager (e.g., pacman, nix, dnf, apt)."
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}✨ Installation Complete! Welcome to MangoWM Gruvbox Rice! ✨${COLOR_RESET}"
echo -e "${COLOR_GRAY}Tip: Reload MangoWM with ${COLOR_BOLD}Super + r${COLOR_RESET}${COLOR_GRAY} or log in to a new MangoWM session.${COLOR_RESET}\n"
