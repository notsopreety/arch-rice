#!/usr/bin/env bash

SOUNDS_DIR="$HOME/.config/scripts/battery-state"
NOTIFY_FILE="/tmp/battery-daemon-state"
CAP_FILE="/tmp/battery-daemon-cap"
mkdir -p /tmp/battery-daemon

BATTERY=$(upower -e | grep -E 'BAT|battery' | head -1)
[[ -z "$BATTERY" ]] && { echo "No battery found"; exit 1; }

emit() {
    local raw capacity status time time_raw val unit h m mins charging icon
    local prev_state prev_cap

    raw=$(upower -i "$BATTERY" 2>/dev/null)
    capacity=$(echo "$raw" | awk '/percentage:/{gsub(/%/,"",$2); print int($2)}')
    capacity=${capacity:-0}
    status=$(echo "$raw" | awk '/state:/{print $2}')

    time="---"
    time_raw=$(echo "$raw" | awk '/time to (empty|full):/{print $4, $5}')
    if [[ -n "$time_raw" ]]; then
        val=$(echo "$time_raw" | awk '{print $1}')
        unit=$(echo "$time_raw" | awk '{print $2}')
        if [[ "$unit" == hours* ]]; then
            h=$(echo "$val" | awk '{print int($1)}')
            m=$(echo "$val" | awk '{printf "%d", ($1 - int($1)) * 60}')
            time=$(printf "%d:%02d" "$h" "$m")
        elif [[ "$unit" == minutes* ]]; then
            mins=$(echo "$val" | awk '{print int($1)}')
            time=$(printf "0:%02d" "$mins")
        fi
    fi

    charging=false
    [[ "$status" == "charging" || "$status" == "fully-charged" || "$status" == "pending-charge" ]] && charging=true

    if $charging; then
        if   (( capacity >= 85 )); then icon="ABOVE85_CHG"
        elif (( capacity >= 70 )); then icon="HIGH_CHG"
        elif (( capacity >= 50 )); then icon="MED_CHG"
        elif (( capacity >= 40 )); then icon="HALF_CHG"
        elif (( capacity >= 20 )); then icon="BELOW_HALF_CHG"
        elif (( capacity >= 10 )); then icon="LOW_CHG"
        else                           icon="VERY_LOW_CHG"
        fi
    else
        if   (( capacity >= 85 )); then icon="ABOVE85"
        elif (( capacity >= 70 )); then icon="HIGH"
        elif (( capacity >= 50 )); then icon="MED"
        elif (( capacity >= 40 )); then icon="HALF"
        elif (( capacity >= 20 )); then icon="BELOW_HALF"
        elif (( capacity >= 10 )); then icon="LOW"
        else                           icon="VERY_LOW"
        fi
    fi

    prev_state=$(cat "$NOTIFY_FILE" 2>/dev/null || echo "NONE")
    prev_cap=$(cat "$CAP_FILE" 2>/dev/null || echo "-1")
    echo "$capacity" > "$CAP_FILE"

    if $charging; then
        if [[ "$prev_state" != "CHG" && "$prev_state" != "FULL" ]]; then
            notify-send -r 1001 -a "Battery" "Battery Charging" "Battery at ${capacity}% — Charging started"
            paplay "$SOUNDS_DIR/connect.mp3" 2>/dev/null &
            echo "CHG" > "$NOTIFY_FILE"
        fi
        if [[ "$capacity" -eq 100 && "$prev_cap" -lt 100 ]]; then
            notify-send -r 1001 -a "Battery" "Battery Full" "Battery at 100% — Fully charged"
            paplay "$SOUNDS_DIR/full.mp3" 2>/dev/null &
            echo "FULL" > "$NOTIFY_FILE"
        fi
    else
        if [[ "$prev_state" == "CHG" || "$prev_state" == "FULL" ]]; then
            notify-send -r 1001 -a "Battery" "Battery Disconnected" "Charger disconnected"
            paplay "$SOUNDS_DIR/disconnect.mp3" 2>/dev/null &
            echo "NONE" > "$NOTIFY_FILE"
        fi
        if [[ "$capacity" -le 5 ]]; then
            if [[ "$prev_cap" -gt 5 ]]; then
                notify-send -r 1001 -a "Battery" -u critical "Battery Critical" "Battery at ${capacity}% — Very low!"
                paplay "$SOUNDS_DIR/down.mp3" 2>/dev/null &
            fi
        elif [[ "$capacity" -le 20 ]]; then
            if [[ "$prev_cap" -gt 20 ]]; then
                notify-send -r 1001 -a "Battery" -u critical "Battery Low" "Battery at ${capacity}% — Consider charging"
                paplay "$SOUNDS_DIR/low.mp3" 2>/dev/null &
            fi
        fi
    fi

    printf '{"capacity":%d,"time":"%s","icon":"%s","status":"%s"}\n' \
        "$capacity" "$time" "$icon" "$status"
}

emit

while IFS= read -r line; do
    if echo "$line" | grep -qi "battery"; then
        sleep 1
        emit
    fi
done < <(upower --monitor 2>/dev/null)
