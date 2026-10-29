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
    echo -e "${COLOR_AQUA}⬇️  Remote installation detected! Downloading dotfiles...${COLOR_RESET}"
    TEMP_DIR=$(mktemp -d)

    # Disable git authentication prompt completely so it never asks for login
    export GIT_TERMINAL_PROMPT=0

    # Try fast git clone anonymously, fallback to direct tarball download
    if command -v git >/dev/null 2>&1 && git clone --depth 1 https://github.com/davidykmisha2015-prog/MyGruvboxMangoWMdotfile.git "$TEMP_DIR" 2>/dev/null; then
        echo -e "   ${COLOR_GREEN}✓ Cloned via Git anonymously${COLOR_RESET}"
    else
        echo -e "   ${COLOR_YELLOW}📦 Downloading archive via curl directly (zero auth)...${COLOR_RESET}"
        if curl -sSL "https://github.com/davidykmisha2015-prog/MyGruvboxMangoWMdotfile/archive/refs/heads/main.tar.gz" | tar -xz -C "$TEMP_DIR" --strip-components=1 2>/dev/null; then
            echo -e "   ${COLOR_GREEN}✓ Archive downloaded and extracted successfully${COLOR_RESET}"
        else
            echo -e "${COLOR_RED}❌ Failed to download dotfiles. Please check your internet connection.${COLOR_RESET}"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    fi

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
if [ -t 0 ]; then
    read -r -p "Do you want to proceed with the installation? (y/N): " CONFIRM
elif [ -e /dev/tty ]; then
    read -r -p "Do you want to proceed with the installation? (y/N): " CONFIRM </dev/tty
else
    CONFIRM="y"
fi

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${COLOR_RED}❌ Installation aborted by user.${COLOR_RESET}"
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    exit 0
fi

echo ""
echo -e "${COLOR_YELLOW}📦 Checking for existing configs to backup...${COLOR_RESET}"

# Backup existing configs if present
for item in mango waybar swaync rofi kitty xdg-desktop-portal-wlr xdg-desktop-portal; do
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

for app in mango waybar swaync rofi kitty xdg-desktop-portal-wlr xdg-desktop-portal; do
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

# Reload XDG Desktop Portals to apply screen sharing settings immediately
systemctl --user restart xdg-desktop-portal-wlr xdg-desktop-portal 2>/dev/null || true

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
MISSING=()

check_dep() {
    local name="$1"
    shift
    for cmd in "$@"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "   [${COLOR_GREEN}✓${COLOR_RESET}] $name is installed (${COLOR_GRAY}$cmd${COLOR_RESET})"
            return 0
        fi
    done
    echo -e "   [${COLOR_RED}✗${COLOR_RESET}] $name is ${COLOR_RED}NOT${COLOR_RESET} installed"
    MISSING+=("$name")
    return 1
}

check_dep "MangoWM" "mango" "mangowm" "mangowc"
check_dep "Waybar" "waybar"
check_dep "SwayNC" "swaync" "sway-notification-center"
check_dep "Rofi" "rofi"
check_dep "Kitty" "kitty"
check_dep "Awww/Swww (wallpapers)" "awww" "swww"
check_dep "Satty (screenshots)" "satty"
check_dep "Grim (screenshots)" "grim"
check_dep "Slurp (region selection)" "slurp"
check_dep "wl-clipboard (copy to clipboard)" "wl-copy"

# Specific assistance for screenshot tools (Win + Shift + S)
SCREENSHOT_MISSING=()
for tool in grim slurp satty wl-copy; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        SCREENSHOT_MISSING+=("$tool")
    fi
done

if [ ${#SCREENSHOT_MISSING[@]} -gt 0 ]; then
    echo ""
    echo -e "${COLOR_ORANGE}📸 Screenshot tools missing for (Win + Shift + S): ${SCREENSHOT_MISSING[*]}${COLOR_RESET}"
    
    # Offer automatic installation on Arch Linux
    if command -v pacman >/dev/null 2>&1; then
        echo -e "${COLOR_YELLOW}👉 Arch Linux detected! Would you like to install them now?${COLOR_RESET}"
        if [ -t 0 ]; then
            read -r -p "Install screenshot & clipboard tools (grim, slurp, wl-clipboard, satty)? (y/N): " INSTALL_SHOT
        elif [ -e /dev/tty ]; then
            read -r -p "Install screenshot & clipboard tools (grim, slurp, wl-clipboard, satty)? (y/N): " INSTALL_SHOT </dev/tty
        else
            INSTALL_SHOT="y"
        fi

        if [[ "$INSTALL_SHOT" =~ ^[Yy]$ ]]; then
            if command -v yay >/dev/null 2>&1; then
                yay -S --needed grim slurp wl-clipboard satty
            elif command -v paru >/dev/null 2>&1; then
                paru -S --needed grim slurp wl-clipboard satty
            else
                sudo pacman -S --needed grim slurp wl-clipboard
                if [[ " ${SCREENSHOT_MISSING[*]} " =~ " satty " ]]; then
                    echo -e "${COLOR_YELLOW}⚠️  Note: 'satty' is in AUR. Please install it via your AUR helper: yay -S satty${COLOR_RESET}"
                fi
            fi
        fi
    else
        echo -e "   ${COLOR_GRAY}Arch Linux:${COLOR_RESET} sudo pacman -S grim slurp wl-clipboard && yay -S satty"
        echo -e "   ${COLOR_GRAY}NixOS:${COLOR_RESET}      Add satty, grim, slurp, wl-clipboard to configuration.nix"
        echo -e "   ${COLOR_GRAY}Fedora:${COLOR_RESET}     sudo dnf install grim slurp wl-clipboard satty"
    fi
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo -e "${COLOR_YELLOW}⚠️  Some desktop components are missing (${MISSING[*]}).${COLOR_RESET}"
    echo "   Install them using your package manager (e.g., pacman, yay, nix, dnf, apt)."
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}✨ Installation Complete! Welcome to MangoWM Gruvbox Rice! ✨${COLOR_RESET}"
echo -e "${COLOR_GRAY}Tip: Reload MangoWM with ${COLOR_BOLD}Super + r${COLOR_RESET}${COLOR_GRAY} or log in to a new MangoWM session.${COLOR_RESET}\n"
