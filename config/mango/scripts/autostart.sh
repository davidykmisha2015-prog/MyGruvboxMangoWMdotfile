#!/usr/bin/env bash
# ==============================================================================
#  MangoWM Autostart Environment Script
# ==============================================================================

# Update DBus and systemd activation environment for Wayland
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=mango 2>/dev/null || true
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true

# NixOS compatibility (only runs on NixOS, never on Arch Linux)
if [ -f /etc/NIXOS ]; then
    systemctl --user start nixos-fake-graphical-session.target 2>/dev/null || true
fi

# Restart portals for screen sharing and file pickers
systemctl --user restart xdg-desktop-portal-wlr xdg-desktop-portal 2>/dev/null || true

# Ensure Bluetooth is unblocked and powered on by default
rfkill unblock bluetooth 2>/dev/null || true
bluetoothctl power on 2>/dev/null || true

# Start blueman tray applet if installed
if command -v blueman-applet >/dev/null 2>&1; then
    pkill -f blueman-applet 2>/dev/null || true
    blueman-applet &
fi
