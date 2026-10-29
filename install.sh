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
for item in mango waybar swaync rofi kitty hypr fastfetch xdg-desktop-portal-wlr xdg-desktop-portal; do
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

for app in mango waybar swaync rofi kitty hypr fastfetch xdg-desktop-portal-wlr xdg-desktop-portal; do
    if [ -d "$SOURCE_CONFIG/$app" ]; then
        echo -e "   ${COLOR_AQUA}Installing:${COLOR_RESET} $CONFIG_TARGET/$app"
        mkdir -p "$CONFIG_TARGET/$app"
        cp -r "$SOURCE_CONFIG/$app"/* "$CONFIG_TARGET/$app/"
    fi
done

# Ensure scripts inside mango and hypr are executable
if [ -d "$CONFIG_TARGET/mango/scripts" ]; then
    chmod +x "$CONFIG_TARGET/mango/scripts/"*.sh 2>/dev/null || true
fi
if [ -d "$CONFIG_TARGET/hypr/scripts" ]; then
    chmod +x "$CONFIG_TARGET/hypr/scripts/"*.sh 2>/dev/null || true
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

# Auto-install Nerd Fonts (JetBrainsMono Nerd Font) if missing
echo ""
echo -e "${COLOR_YELLOW}🔤 Checking for JetBrainsMono Nerd Font...${COLOR_RESET}"
if command -v fc-list >/dev/null 2>&1 && fc-list : family | grep -qi "JetBrainsMono.*Nerd"; then
    echo -e "   [${COLOR_GREEN}✓${COLOR_RESET}] JetBrainsMono Nerd Font is already installed"
else
    echo -e "${COLOR_ORANGE}⬇️  JetBrainsMono Nerd Font not found. Installing automatically...${COLOR_RESET}"
    if command -v pacman >/dev/null 2>&1; then
        echo -e "   ${COLOR_AQUA}Installing ttf-jetbrains-mono-nerd via pacman...${COLOR_RESET}"
        sudo pacman -S --needed ttf-jetbrains-mono-nerd 2>/dev/null || true
    fi

    # Fallback to direct user-level download to ~/.local/share/fonts (works on ANY distro without sudo)
    if ! (command -v fc-list >/dev/null 2>&1 && fc-list : family | grep -qi "JetBrainsMono.*Nerd"); then
        FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
        echo -e "   ${COLOR_AQUA}Downloading font from GitHub release to $FONT_DIR...${COLOR_RESET}"
        mkdir -p "$FONT_DIR"
        TEMP_FONT=$(mktemp -d)
        if curl -sSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o "$TEMP_FONT/JetBrainsMono.tar.xz" 2>/dev/null; then
            tar -xf "$TEMP_FONT/JetBrainsMono.tar.xz" -C "$FONT_DIR" 2>/dev/null || true
            rm -rf "$TEMP_FONT"
            if command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
            fi
            echo -e "   [${COLOR_GREEN}✓${COLOR_RESET}] JetBrainsMono Nerd Font installed successfully!"
        else
            echo -e "   ${COLOR_RED}⚠️  Failed to download font. Please install ttf-jetbrains-mono-nerd manually.${COLOR_RESET}"
            rm -rf "$TEMP_FONT"
        fi
    else
        echo -e "   [${COLOR_GREEN}✓${COLOR_RESET}] JetBrainsMono Nerd Font installed successfully!"
    fi
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
check_dep "Hyprlock (lockscreen)" "hyprlock"
check_dep "Awww/Swww (wallpapers)" "awww" "swww"
check_dep "Satty (screenshots)" "satty"
check_dep "Grim (screenshots)" "grim"
check_dep "Slurp (region selection)" "slurp"
check_dep "wl-clipboard (clipboard)" "wl-copy"
check_dep "Playerctl (music in lockscreen)" "playerctl"
check_dep "Fastfetch (system info)" "fastfetch"

# Automated package installation support
if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo -e "${COLOR_YELLOW}⚠️  Some recommended tools are missing (${MISSING[*]}).${COLOR_RESET}"
    
    # Intelligent automatic installer for Arch Linux
    if command -v pacman >/dev/null 2>&1; then
        echo -e "${COLOR_ORANGE}👉 Arch Linux detected! Would you like to automatically install all missing tools?${COLOR_RESET}"
        if [ -t 0 ]; then
            read -r -p "Install all missing tools for Arch Linux? (y/N): " INSTALL_ALL
        elif [ -e /dev/tty ]; then
            read -r -p "Install all missing tools for Arch Linux? (y/N): " INSTALL_ALL </dev/tty
        else
            INSTALL_ALL="y"
        fi

        if [[ "$INSTALL_ALL" =~ ^[Yy]$ ]]; then
            OFFICIAL_PKGS=()
            AUR_PKGS=()

            for m in "${MISSING[@]}"; do
                case "$m" in
                    "Waybar") OFFICIAL_PKGS+=("waybar") ;;
                    "SwayNC") OFFICIAL_PKGS+=("sway-notification-center") ;;
                    "Rofi") OFFICIAL_PKGS+=("rofi-wayland") ;;
                    "Kitty") OFFICIAL_PKGS+=("kitty") ;;
                    "Hyprlock (lockscreen)") OFFICIAL_PKGS+=("hyprlock") ;;
                    "Grim (screenshots)") OFFICIAL_PKGS+=("grim") ;;
                    "Slurp (region selection)") OFFICIAL_PKGS+=("slurp") ;;
                    "wl-clipboard (clipboard)") OFFICIAL_PKGS+=("wl-clipboard") ;;
                    "Playerctl (music in lockscreen)") OFFICIAL_PKGS+=("playerctl") ;;
                    "Fastfetch (system info)") OFFICIAL_PKGS+=("fastfetch") ;;
                    "Awww/Swww (wallpapers)") AUR_PKGS+=("swww") ;;
                    "Satty (screenshots)") AUR_PKGS+=("satty") ;;
                    "MangoWM") AUR_PKGS+=("mangowm-git") ;;
                esac
            done

            # Ensure Nerd Font is always installed for icons
            OFFICIAL_PKGS+=("ttf-jetbrains-mono-nerd")

            if [ ${#OFFICIAL_PKGS[@]} -gt 0 ]; then
                echo -e "${COLOR_AQUA}📦 Installing official packages via pacman (${OFFICIAL_PKGS[*]})...${COLOR_RESET}"
                sudo pacman -S --needed "${OFFICIAL_PKGS[@]}"
            fi

            if [ ${#AUR_PKGS[@]} -gt 0 ]; then
                echo -e "${COLOR_AQUA}📦 Installing AUR packages (${AUR_PKGS[*]})...${COLOR_RESET}"
                if command -v yay >/dev/null 2>&1; then
                    yay -S --needed "${AUR_PKGS[@]}"
                elif command -v paru >/dev/null 2>&1; then
                    paru -S --needed "${AUR_PKGS[@]}"
                else
                    echo -e "${COLOR_YELLOW}⚠️  AUR helper not found. Please install manually via yay/paru: yay -S ${AUR_PKGS[*]}${COLOR_RESET}"
                fi
            fi
        fi
    else
        echo -e "   ${COLOR_GRAY}Arch Linux:${COLOR_RESET} sudo pacman -S waybar swaync rofi-wayland kitty hyprlock grim slurp wl-clipboard playerctl fastfetch ttf-jetbrains-mono-nerd && yay -S swww satty mangowm-git"
        echo -e "   ${COLOR_GRAY}NixOS:${COLOR_RESET}      Add mango, waybar, swaync, rofi, kitty, hyprlock, satty, grim, slurp, wl-clipboard, playerctl, fastfetch"
        echo -e "   ${COLOR_GRAY}Fedora:${COLOR_RESET}     sudo dnf install waybar swaync rofi-wayland kitty hyprlock grim slurp wl-clipboard playerctl fastfetch"
    fi
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}✨ Installation Complete! Welcome to MangoWM Gruvbox Rice! ✨${COLOR_RESET}"
echo -e "${COLOR_GRAY}Tip: Reload MangoWM with ${COLOR_BOLD}Super + r${COLOR_RESET}${COLOR_GRAY} or log in to a new MangoWM session.${COLOR_RESET}\n"
