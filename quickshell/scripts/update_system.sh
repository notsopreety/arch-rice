#!/usr/bin/env bash

# System Update Script for Quickshell
# Auto-detects available package managers, counts updates in JSON, and updates them with a beautiful UI.

# Color definitions (Material You 3 style)
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[38;2;46;204;113m"
BLUE="\033[38;2;84;160;255m"
YELLOW="\033[38;2;255;190;118m"
RED="\033[38;2;255;71;87m"
GREY="\033[38;2;149;175;192m"

# Detection helper
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# ── CHECK MODE ──
if [[ "$1" == "--check" ]]; then
    pac_count=0
    aur_count=0
    flat_count=0
    snap_count=0

    # 1. pacman (via checkupdates)
    if has_cmd checkupdates; then
        pac_count=$(checkupdates 2>/dev/null | wc -l || echo '0')
    fi

    # 2. AUR (yay or paru)
    if has_cmd yay; then
        aur_count=$(yay -Qua 2>/dev/null | wc -l || echo '0')
    elif has_cmd paru; then
        aur_count=$(paru -Qua 2>/dev/null | wc -l || echo '0')
    fi

    # 3. Flatpak
    if has_cmd flatpak; then
        # Subtract header line if updates exist
        flat_list=$(flatpak list --updates 2>/dev/null)
        if [[ -n "$flat_list" ]]; then
            flat_count=$(echo "$flat_list" | wc -l || echo '0')
        fi
    fi

    # 4. Snap
    if has_cmd snap; then
        snap_count=$(snap refresh --list 2>/dev/null | tail -n +2 | wc -l || echo '0')
    fi

    total=$((pac_count + aur_count + flat_count + snap_count))

    # Output clean JSON
    echo "{\"total\": $total, \"pacman\": $pac_count, \"aur\": $aur_count, \"flatpak\": $flat_count, \"snap\": $snap_count}"
    exit 0
fi

# ── UPDATE MODE ──
clear
echo -e "${BLUE}${BOLD}╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${BLUE}${BOLD}║             SYSTEM UPDATE OVERHAUL                ║${RESET}"
echo -e "${BLUE}${BOLD}╚═══════════════════════════════════════════════════╝${RESET}"
echo ""

# Pacman / AUR
if has_cmd yay; then
    echo -e "${GREEN}${BOLD}[1/3] Updating Arch System + AUR (yay)...${RESET}"
    yay -Syu
elif has_cmd paru; then
    echo -e "${GREEN}${BOLD}[1/3] Updating Arch System + AUR (paru)...${RESET}"
    paru -Syu
elif has_cmd pacman; then
    echo -e "${GREEN}${BOLD}[1/3] Updating Arch System (pacman)...${RESET}"
    sudo pacman -Syu
else
    echo -e "${GREY}[1/3] No pacman/AUR helper found. Skipping.${RESET}"
fi

echo ""

# Flatpak
if has_cmd flatpak; then
    echo -e "${YELLOW}${BOLD}[2/3] Updating Flatpaks...${RESET}"
    flatpak update
else
    echo -e "${GREY}[2/3] Flatpak not installed. Skipping.${RESET}"
fi

echo ""

# Snap
if has_cmd snap; then
    echo -e "${RED}${BOLD}[3/3] Updating Snaps...${RESET}"
    sudo snap refresh
else
    echo -e "${GREY}[3/3] Snap not installed. Skipping.${RESET}"
fi

echo ""
echo -e "${GREEN}${BOLD}✔ System update finished successfully!${RESET}"
echo -e "${GREY}Press any key to close this terminal...${RESET}"
read -n 1
