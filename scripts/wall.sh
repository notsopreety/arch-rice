#!/usr/bin/env bash

set -euo pipefail

# ==============================
# CONFIG
# ==============================

WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
CACHE_DIR="${HOME}/.cache/awww-wal"
CACHE_FILE="${CACHE_DIR}/current"

# ==============================
# LOAD WALLPAPERS
# ==============================

load_wallpapers() {
    mapfile -d '' WALLPAPERS < <(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
        -print0 | sort -z
    )

    if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
        echo "No wallpapers found in $WALLPAPER_DIR" >&2
        exit 1
    fi
}

# ==============================
# CURRENT INDEX
# ==============================

get_current_index() {
    local current=""

    if [[ -f "$CACHE_FILE" ]]; then
        current="$(<"$CACHE_FILE")"
    else
        current="${WALLPAPERS[0]}"
    fi

    for i in "${!WALLPAPERS[@]}"; do
        [[ "${WALLPAPERS[$i]}" == "$current" ]] && echo "$i" && return
    done

    echo "0"
}

# ==============================
# IMAGE HANDLER
# ==============================

handle_image() {
    local arg="${1:-}"

    case "$arg" in
        "")
            if [[ -f "$CACHE_FILE" ]]; then
                cat "$CACHE_FILE"
            else
                printf '%s\n' "${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
            fi
            ;;

        next)
            local i
            i=$(get_current_index)
            printf '%s\n' "${WALLPAPERS[(i + 1) % ${#WALLPAPERS[@]}]}"
            ;;

        prev)
            local i
            i=$(get_current_index)
            printf '%s\n' "${WALLPAPERS[(i - 1 + ${#WALLPAPERS[@]}) % ${#WALLPAPERS[@]}]}"
            ;;

        rand|random)
            printf '%s\n' "${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
            ;;

        *)
            if [[ -f "$arg" ]]; then
                printf '%s\n' "$arg"
            else
                echo "Invalid image: $arg" >&2
                exit 1
            fi
            ;;
    esac
}

# ==============================
# DAEMON
# ==============================

start_daemon() {
    if ! pgrep -x "awww-daemon" > /dev/null; then
        (awww-daemon > /dev/null 2>&1 &)
        sleep 0.2
    fi
}

# ==============================
# APPLY WALLPAPER
# ==============================

apply_wallpaper() {
    local img="$1"

    if ! command -v awww &>/dev/null; then
        echo "awww not installed" >&2
        exit 1
    fi

    # Set wallpaper using awww with transitions
    awww img "$img" \
        --transition-type random \
        --transition-duration 2 \
        --transition-fps 60 \
        > /dev/null 2>&1
        
    mkdir -p "$CACHE_DIR"
    printf '%s\n' "$img" > "$CACHE_FILE"
    
    # Save a static copy for other configurations
    cp "$img" "${CACHE_DIR}/wall.jpg" 2>/dev/null || true

    # Matugen Color Palette Generation
    if command -v matugen &>/dev/null; then
        echo "🎨 Running matugen to generate color palettes..."
        # Runs non-interactively using the dominant color
        matugen image "$img" --source-color-index 0 >/dev/null 2>&1 || true
    fi

    # Reload Hyprland configurations
    if pgrep -x "Hyprland" > /dev/null; then
        echo "🔄 Reloading Hyprland..."
        hyprctl reload >/dev/null 2>&1 || true
    fi

    # Send system notification
    if command -v notify-send &>/dev/null; then
        notify-send -r 1012 -a "Wallpaper" -t 2000 -i "$img" "Wallpaper Changed" "Applied: $(basename "$img")" || true
    fi

    echo "✓ $(basename "$img") applied"
}

# ==============================
# HELP
# ==============================

show_help() {
cat <<EOF
Wallpaper Script

USAGE:
  wall.sh [-i IMAGE]

OPTIONS:
  -i   next | prev | rand | /path/to/image

DEFAULT:
  last used or random wallpaper
EOF
}

# ==============================
# MAIN
# ==============================

main() {
    local img_arg=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i) img_arg="$2"; shift 2 ;;
            -i=*) img_arg="${1#*=}"; shift ;;
            -h|--help) show_help; exit 0 ;;
            *)
                if [[ -z "$img_arg" ]]; then
                    img_arg="$1"
                    shift
                else
                    echo "Unknown argument: $1" >&2
                    exit 1
                fi
                ;;
        esac
    done

    load_wallpapers

    local img
    img=$(handle_image "$img_arg")

    start_daemon
    apply_wallpaper "$img"
}

main "$@"
