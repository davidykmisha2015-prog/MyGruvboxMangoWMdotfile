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

# Helper for interactive user prompt (supporting stdin, pipe, and curl)
ask_user() {
    local prompt="$1"
    local default="${2:-n}"
    local reply=""
    if [ -t 0 ]; then
        read -r -p "$prompt" reply
    elif [ -e /dev/tty ]; then
        read -r -p "$prompt" reply </dev/tty
    else
        reply="$default"
    fi
    echo "${reply:-$default}"
}

# Detect running Linux distribution
detect_distro() {
    local id="unknown"
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        id="${ID:-unknown}"
        if [ "$id" = "unknown" ] && [ -n "$ID_LIKE" ]; then
            id="$ID_LIKE"
        fi
    fi

    if [ "$id" = "unknown" ]; then
        if command -v nixos-rebuild >/dev/null 2>&1 || [ -d /etc/nixos ]; then
            id="nixos"
        elif command -v pacman >/dev/null 2>&1; then
            id="arch"
        elif command -v dnf >/dev/null 2>&1; then
            id="fedora"
        elif command -v apt-get >/dev/null 2>&1; then
            id="debian"
        elif command -v zypper >/dev/null 2>&1; then
            id="opensuse"
        elif command -v xbps-install >/dev/null 2>&1; then
            id="void"
        fi
    fi
    echo "$id"
}

get_distro_name() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ -n "$PRETTY_NAME" ]; then
            echo "$PRETTY_NAME"
            return
        elif [ -n "$NAME" ]; then
            echo "$NAME"
            return
        fi
    fi
    echo "Unknown Linux"
}

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
CONFIRM=$(ask_user "Do you want to proceed with the installation? (y/N): " "n")

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
check_dep "Bluetooth Manager" "blueman-manager" "overskride"
check_dep "Playerctl (music in lockscreen)" "playerctl"
check_dep "Fastfetch (system info)" "fastfetch"

# Automated package installation support
if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo -e "${COLOR_YELLOW}⚠️  Some recommended tools are missing: ${COLOR_ORANGE}${MISSING[*]}${COLOR_RESET}"
    
    DISTRO_ID=$(detect_distro)
    DISTRO_NAME=$(get_distro_name)
    echo -e "   ${COLOR_BOLD}Detected system:${COLOR_RESET} ${COLOR_AQUA}$DISTRO_NAME ($DISTRO_ID)${COLOR_RESET}"
    echo ""
    
    INSTALL_DEPS=$(ask_user "Would you like to install missing dependencies automatically? (Y/n): " "y")
    if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]]; then
        case "$DISTRO_ID" in
            nixos)
                echo ""
                echo -e "${COLOR_AQUA}❄️  Виявлено NixOS ($DISTRO_NAME)!${COLOR_RESET}"
                echo -e "${COLOR_YELLOW}${COLOR_BOLD}Друже, вибач, але на NixOS цей скрипт нічого встановити не зможе! 😅${COLOR_RESET}"
                echo -e "${COLOR_GRAY}У NixOS пакети не встановлюються через класичний пакетний менеджер, тут усе налаштовується декларативно.${COLOR_RESET}"
                echo ""
                echo -e "${COLOR_ORANGE}📋 Ось готова інструкція, що додати до твого ${COLOR_BOLD}/etc/nixos/configuration.nix${COLOR_RESET} (або flake):"
                echo -e "${COLOR_AQUA}──────────────────────────────────────────────────────────────────────${COLOR_RESET}"
                cat << 'EOF'
  # 1. Системні пакети оточення MangoWM:
  environment.systemPackages = with pkgs; [
    # Панелі та сповіщення
    waybar
    swaynotificationcenter
    rofi-wayland
    kitty
    hyprlock
    swww              # або awww для шпалер
    fastfetch

    # Скріншоти та буфер обміну
    satty
    grim
    slurp
    wl-clipboard

    # Керування медіа та звуком
    playerctl
    pavucontrol

    # Менеджер Bluetooth
    blueman
  ];

  # 2. Налаштування Bluetooth (щоб працював з коробки):
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # 3. Шрифти Nerd Fonts (для іконок Waybar):
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
EOF
                echo -e "${COLOR_AQUA}──────────────────────────────────────────────────────────────────────${COLOR_RESET}"
                echo -e "Після додавання у конфіг збережи файл та виконай:"
                echo -e "  ${COLOR_BOLD}${COLOR_GREEN}sudo nixos-rebuild switch${COLOR_RESET}\n"
                ;;
            arch|manjaro|endeavouros|cachyos|artix|garuda)
                echo ""
                echo -e "${COLOR_AQUA}📦 Arch Linux detected ($DISTRO_NAME)! Installing packages...${COLOR_RESET}"
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
                        "Bluetooth Manager") OFFICIAL_PKGS+=("bluez" "bluez-utils" "blueman") ;;
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
                    sudo systemctl enable --now bluetooth 2>/dev/null || true
                    rfkill unblock bluetooth 2>/dev/null || true
                fi

                if [ ${#AUR_PKGS[@]} -gt 0 ]; then
                    echo -e "${COLOR_AQUA}📦 Installing AUR packages (${AUR_PKGS[*]})...${COLOR_RESET}"
                    if command -v yay >/dev/null 2>&1; then
                        yay -S --needed "${AUR_PKGS[@]}"
                    elif command -v paru >/dev/null 2>&1; then
                        paru -S --needed "${AUR_PKGS[@]}"
                    else
                        echo -e "${COLOR_YELLOW}⚠️  AUR helper not found. Please install manually: yay -S ${AUR_PKGS[*]}${COLOR_RESET}"
                    fi
                fi
                ;;
            fedora|nobara|rhel|centos)
                echo ""
                echo -e "${COLOR_AQUA}📦 Fedora detected ($DISTRO_NAME)! Installing packages...${COLOR_RESET}"
                FEDORA_PKGS=()
                for m in "${MISSING[@]}"; do
                    case "$m" in
                        "Waybar") FEDORA_PKGS+=("waybar") ;;
                        "SwayNC") FEDORA_PKGS+=("sway-notification-center") ;;
                        "Rofi") FEDORA_PKGS+=("rofi-wayland") ;;
                        "Kitty") FEDORA_PKGS+=("kitty") ;;
                        "Hyprlock (lockscreen)") FEDORA_PKGS+=("hyprlock") ;;
                        "Grim (screenshots)") FEDORA_PKGS+=("grim") ;;
                        "Slurp (region selection)") FEDORA_PKGS+=("slurp") ;;
                        "wl-clipboard (clipboard)") FEDORA_PKGS+=("wl-clipboard") ;;
                        "Bluetooth Manager") FEDORA_PKGS+=("bluez" "blueman") ;;
                        "Playerctl (music in lockscreen)") FEDORA_PKGS+=("playerctl") ;;
                        "Fastfetch (system info)") FEDORA_PKGS+=("fastfetch") ;;
                    esac
                done
                if [ ${#FEDORA_PKGS[@]} -gt 0 ]; then
                    echo -e "${COLOR_AQUA}📦 Installing packages via dnf (${FEDORA_PKGS[*]})...${COLOR_RESET}"
                    sudo dnf install -y "${FEDORA_PKGS[@]}"
                    sudo systemctl enable --now bluetooth 2>/dev/null || true
                fi
                ;;
            ubuntu|debian|pop|linuxmint|elementary|zorin|kali)
                echo ""
                echo -e "${COLOR_AQUA}📦 Debian/Ubuntu detected ($DISTRO_NAME)! Installing packages...${COLOR_RESET}"
                DEB_PKGS=()
                for m in "${MISSING[@]}"; do
                    case "$m" in
                        "Waybar") DEB_PKGS+=("waybar") ;;
                        "Rofi") DEB_PKGS+=("rofi") ;;
                        "Kitty") DEB_PKGS+=("kitty") ;;
                        "Grim (screenshots)") DEB_PKGS+=("grim") ;;
                        "Slurp (region selection)") DEB_PKGS+=("slurp") ;;
                        "wl-clipboard (clipboard)") DEB_PKGS+=("wl-clipboard") ;;
                        "Bluetooth Manager") DEB_PKGS+=("bluez" "blueman") ;;
                        "Playerctl (music in lockscreen)") DEB_PKGS+=("playerctl") ;;
                        "Fastfetch (system info)") DEB_PKGS+=("fastfetch") ;;
                    esac
                done
                if [ ${#DEB_PKGS[@]} -gt 0 ]; then
                    echo -e "${COLOR_AQUA}📦 Installing packages via apt (${DEB_PKGS[*]})...${COLOR_RESET}"
                    sudo apt update && sudo apt install -y "${DEB_PKGS[@]}"
                    sudo systemctl enable --now bluetooth 2>/dev/null || true
                fi
                echo -e "${COLOR_YELLOW}ℹ️  Note: Some packages (MangoWM, SwayNC, Hyprlock) may need to be compiled from source on Debian/Ubuntu.${COLOR_RESET}"
                ;;
            *)
                echo ""
                echo -e "${COLOR_YELLOW}⚠️  Automatic package installation is not available for $DISTRO_NAME ($DISTRO_ID).${COLOR_RESET}"
                echo -e "   Please install the missing packages manually using your package manager:"
                echo -e "   ${COLOR_BOLD}${MISSING[*]}${COLOR_RESET}"
                ;;
        esac
    else
        echo -e "   ${COLOR_GRAY}Skipped dependency installation.${COLOR_RESET}"
    fi
else
    echo ""
    echo -e "${COLOR_GREEN}✅ All recommended dependencies are already installed!${COLOR_RESET}"
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}✨ Installation Complete! Welcome to MangoWM Gruvbox Rice! ✨${COLOR_RESET}"
echo -e "${COLOR_GRAY}Tip: Reload MangoWM with ${COLOR_BOLD}Super + r${COLOR_RESET}${COLOR_GRAY} or log in to a new MangoWM session.${COLOR_RESET}\n"
