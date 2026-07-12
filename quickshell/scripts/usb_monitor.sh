#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# usb_monitor.sh — Detects USB/external storage hotplug events
# and outputs accurate device info as JSON.
#
# Usage:
#   ./usb_monitor.sh          — Run in monitor mode (stream events)
#   ./usb_monitor.sh --list   — List currently connected USB storage
#   ./usb_monitor.sh --info /dev/sda1 — Info for a specific device
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

human_size() {
    local bytes="$1"
    if [[ -z "$bytes" || "$bytes" == "0" ]]; then
        echo "Unknown"
        return
    fi
    numfmt --to=iec --suffix=B --format="%.1f" "$bytes" 2>/dev/null || echo "${bytes}B"
}

# ── Gather device info for non-block USB devices (Smartphones, MTP) ──

get_usb_device_info() {
    local dev="$1"     # e.g. /dev/bus/usb/002/003
    local event="$2"   # "add" or "remove"

    local udev_info
    udev_info=$(udevadm info --query=all --name="$dev" 2>/dev/null || true)
    if [[ -z "$udev_info" ]]; then
        return
    fi

    # Check DEVTYPE
    local devtype
    devtype=$(echo "$udev_info" | grep -oP 'DEVTYPE=\K.*' || echo "")
    if [[ "$devtype" != "usb_device" ]]; then
        return # Skip endpoints/interfaces
    fi

    local id_vendor id_model id_serial id_vendor_db id_model_db devpath
    id_vendor=$(echo "$udev_info" | grep -oP 'ID_VENDOR=\K.*' || echo "")
    id_model=$(echo "$udev_info" | grep -oP 'ID_MODEL=\K.*' || echo "")
    id_serial=$(echo "$udev_info" | grep -oP 'ID_SERIAL_SHORT=\K.*' || echo "")
    id_vendor_db=$(echo "$udev_info" | grep -oP 'ID_VENDOR_FROM_DATABASE=\K.*' || echo "")
    id_model_db=$(echo "$udev_info" | grep -oP 'ID_MODEL_FROM_DATABASE=\K.*' || echo "")
    devpath=$(echo "$udev_info" | grep -oP 'DEVPATH=\K.*' || echo "")

    # Skip USB storage devices at raw USB level; they will be handled by the block subsystem
    local id_usb_interfaces
    id_usb_interfaces=$(echo "$udev_info" | grep -oP 'ID_USB_INTERFACES=\K.*' || echo "")
    if [[ "$id_usb_interfaces" =~ :08 ]]; then
        return
    fi

    # Skip internal hubs and host controllers
    local combined
    combined=$(echo "$id_vendor $id_model $id_vendor_db $id_model_db" | tr '[:upper:]' '[:lower:]')
    if [[ "$combined" =~ "hub" || "$combined" =~ "host controller" || "$combined" =~ "xhci" || "$combined" =~ "ehci" || "$combined" =~ "root hub" ]]; then
        return
    fi

    # Deduce if it's a smartphone
    local dev_type="USB Device"
    local vendor="${id_vendor_db:-$id_vendor}"
    local model="${id_model_db:-$id_model}"

    local lower_vendor
    lower_vendor=$(echo "$vendor" | tr '[:upper:]' '[:lower:]')
    local lower_model
    lower_model=$(echo "$model" | tr '[:upper:]' '[:lower:]')

    # Phone brands matching
    if [[ "$lower_vendor" =~ "samsung" || "$lower_vendor" =~ "apple" || "$lower_vendor" =~ "google" || "$lower_vendor" =~ "oneplus" || "$lower_vendor" =~ "xiaomi" || "$lower_vendor" =~ "huawei" || "$lower_vendor" =~ "motorola" || "$lower_vendor" =~ "oppo" || "$lower_vendor" =~ "realme" || "$lower_vendor" =~ "sony" || "$lower_vendor" =~ "lg" || "$lower_vendor" =~ "htc" || "$lower_vendor" =~ "nokia" || "$lower_vendor" =~ "redmi" || "$lower_model" =~ "android" || "$lower_model" =~ "iphone" || "$lower_model" =~ "ipad" ]]; then
        dev_type="Smartphone"
    fi

    # Clean vendor/model names
    vendor="${vendor//_/ }"
    model="${model//_/ }"

    local display_name="${model:-$vendor}"
    if [[ -z "$display_name" ]]; then
        display_name="USB Device"
    fi

    echo "{\"event\":\"$(json_escape "$event")\",\"device\":\"$(json_escape "$dev")\",\"devpath\":\"$(json_escape "$devpath")\",\"displayName\":\"$(json_escape "$display_name")\",\"deviceType\":\"$(json_escape "$dev_type")\",\"vendor\":\"$(json_escape "$vendor")\",\"model\":\"$(json_escape "$model")\",\"serial\":\"$(json_escape "$id_serial")\",\"bus\":\"usb\",\"filesystem\":\"MTP\",\"label\":\"\",\"uuid\":\"\",\"sizeBytes\":0,\"sizeHuman\":\"\",\"mountpoint\":\"\",\"usedBytes\":0,\"availableBytes\":0,\"usePercent\":0,\"removable\":true,\"partitionScheme\":\"\",\"partitionNumber\":\"\",\"timestamp\":\"$(date -Iseconds)\"}"
}

# ── Gather device info for a single block device node ────────────

get_device_info() {
    local dev="$1"     # e.g. /dev/sda1
    local event="$2"   # "add" or "remove" or "info"

    # Basic existence check (for add/info)
    if [[ "$event" != "remove" && ! -b "$dev" ]]; then
        return
    fi

    local devname
    devname=$(basename "$dev")

    # ── udevadm info ──
    local udev_info=""
    if [[ "$event" != "remove" ]]; then
        udev_info=$(udevadm info --query=all --name="$dev" 2>/dev/null || true)
    fi

    local id_vendor id_model id_serial id_fs_type id_fs_label id_fs_uuid
    local id_bus id_usb_driver id_part_entry_scheme id_part_entry_number devpath
    local removable=""

    id_vendor=$(echo "$udev_info"   | grep -oP 'ID_VENDOR=\K.*' || echo "")
    id_model=$(echo "$udev_info"    | grep -oP 'ID_MODEL=\K.*' || echo "")
    id_serial=$(echo "$udev_info"   | grep -oP 'ID_SERIAL_SHORT=\K.*' || echo "")
    id_fs_type=$(echo "$udev_info"  | grep -oP 'ID_FS_TYPE=\K.*' || echo "")
    id_fs_label=$(echo "$udev_info" | grep -oP 'ID_FS_LABEL=\K.*' || echo "")
    id_fs_uuid=$(echo "$udev_info"  | grep -oP 'ID_FS_UUID=\K.*' || echo "")
    id_bus=$(echo "$udev_info"      | grep -oP 'ID_BUS=\K.*' || echo "")
    id_usb_driver=$(echo "$udev_info" | grep -oP 'ID_USB_DRIVER=\K.*' || echo "")
    id_part_entry_scheme=$(echo "$udev_info" | grep -oP 'ID_PART_ENTRY_SCHEME=\K.*' || echo "")
    id_part_entry_number=$(echo "$udev_info" | grep -oP 'ID_PART_ENTRY_NUMBER=\K.*' || echo "")
    devpath=$(echo "$udev_info" | grep -oP 'DEVPATH=\K.*' || echo "")

    # Friendly vendor/model names (replace underscores)
    id_vendor="${id_vendor//_/ }"
    id_model="${id_model//_/ }"

    # ── Check removable ──
    local parent_dev
    parent_dev=$(echo "$devname" | sed 's/[0-9]*$//')
    if [[ -f "/sys/block/$parent_dev/removable" ]]; then
        removable=$(cat "/sys/block/$parent_dev/removable" 2>/dev/null || echo "0")
    fi

    # ── lsblk info ──
    local size="" fstype="" mountpoint="" label="" parttype="" hotplug=""
    if [[ "$event" != "remove" ]]; then
        local lsblk_json
        lsblk_json=$(lsblk -Jbnpo NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,PARTTYPE,HOTPLUG "$dev" 2>/dev/null || echo "")
        if [[ -n "$lsblk_json" ]]; then
            size=$(echo "$lsblk_json"       | grep -oP '"size"\s*:\s*\K[0-9]+' | head -1 || echo "")
            fstype=$(echo "$lsblk_json"     | grep -oP '"fstype"\s*:\s*"\K[^"]*' | head -1 || echo "")
            mountpoint=$(echo "$lsblk_json" | grep -oP '"mountpoint"\s*:\s*"\K[^"]*' | head -1 || echo "")
            label=$(echo "$lsblk_json"      | grep -oP '"label"\s*:\s*"\K[^"]*' | head -1 || echo "")
            hotplug=$(echo "$lsblk_json"    | grep -oP '"hotplug"\s*:\s*\K[a-z]+' | head -1 || echo "")
        fi
    fi

    # Prefer lsblk values but fall back to udevadm
    [[ -z "$fstype" ]] && fstype="$id_fs_type"
    [[ -z "$label" ]]  && label="$id_fs_label"

    # ── Usage stats (only if mounted) ──
    local used="" available="" use_percent=""
    if [[ -n "$mountpoint" && -d "$mountpoint" ]]; then
        local df_line
        df_line=$(df -B1 "$mountpoint" 2>/dev/null | tail -1)
        used=$(echo "$df_line"      | awk '{print $3}')
        available=$(echo "$df_line" | awk '{print $4}')
        use_percent=$(echo "$df_line" | awk '{print $5}' | tr -d '%')
    fi

    # ── Device type heuristic ──
    # ── Transport type from lsblk ──
    local tran=""
    tran=$(lsblk -ndo TRAN "$dev" 2>/dev/null || echo "")
    # For partitions, tran may be empty — check parent
    if [[ -z "$tran" ]]; then
        tran=$(lsblk -ndo TRAN "/dev/$parent_dev" 2>/dev/null || echo "")
    fi

    local dev_type="Unknown"
    if [[ "$id_bus" == "usb" ]]; then
        if [[ "$id_usb_driver" == "uas" || "$id_usb_driver" == "usb-storage" ]]; then
            if [[ "$removable" == "1" ]]; then
                dev_type="USB Flash Drive"
            else
                dev_type="USB External Drive"
            fi
        else
            dev_type="USB Device"
        fi
    elif [[ "$tran" == "mmc" || "$id_bus" == "mmc" ]]; then
        dev_type="SD / MMC Card"
    elif [[ -n "$hotplug" && "$hotplug" == "true" ]]; then
        dev_type="Removable Device"
    elif [[ "$removable" == "1" ]]; then
        dev_type="Removable Device"
    fi

    # Brand-specific overrides
    if echo "$id_vendor $id_model $label" | grep -qi "sandisk"; then
        if [[ "$tran" == "mmc" ]]; then
            dev_type="SanDisk SD Card"
        else
            dev_type="SanDisk USB Drive"
        fi
    fi

    # ── Friendly display name ──
    local display_name=""
    if [[ -n "$label" ]]; then
        display_name="$label"
    elif [[ -n "$id_model" ]]; then
        display_name="$id_model"
    else
        display_name="$devname"
    fi

    local size_human
    size_human=$(human_size "${size:-0}")

    # ── Build JSON ──
    echo "{\"event\":\"$(json_escape "$event")\",\"device\":\"$(json_escape "$dev")\",\"devpath\":\"$(json_escape "$devpath")\",\"displayName\":\"$(json_escape "$display_name")\",\"deviceType\":\"$(json_escape "$dev_type")\",\"vendor\":\"$(json_escape "$id_vendor")\",\"model\":\"$(json_escape "$id_model")\",\"serial\":\"$(json_escape "$id_serial")\",\"bus\":\"$(json_escape "$id_bus")\",\"filesystem\":\"$(json_escape "$fstype")\",\"label\":\"$(json_escape "$label")\",\"uuid\":\"$(json_escape "$id_fs_uuid")\",\"sizeBytes\":${size:-0},\"sizeHuman\":\"$(json_escape "$size_human")\",\"mountpoint\":\"$(json_escape "$mountpoint")\",\"usedBytes\":${used:-0},\"availableBytes\":${available:-0},\"usePercent\":${use_percent:-0},\"removable\":$([ "$removable" = "1" ] && echo "true" || echo "false"),\"partitionScheme\":\"$(json_escape "$id_part_entry_scheme")\",\"partitionNumber\":\"$(json_escape "$id_part_entry_number")\",\"timestamp\":\"$(date -Iseconds)\"}"
}

# ── Mode: --list ─────────────────────────────────────────────────

list_usb_devices() {
    local found=0
    echo "["
    # Find all block devices on the USB bus
    for dev in /dev/sd* /dev/mmcblk*p* /dev/nvme*n*p*; do
        [[ -b "$dev" ]] || continue
        local udev_bus
        udev_bus=$(udevadm info --query=property --name="$dev" 2>/dev/null | grep -oP 'ID_BUS=\K.*' || echo "")
        local is_hotplug
        is_hotplug=$(lsblk -ndo HOTPLUG "$dev" 2>/dev/null || echo "")

        local dev_tran
        dev_tran=$(lsblk -ndo TRAN "$dev" 2>/dev/null || echo "")
        # For partitions, check parent transport
        if [[ -z "$dev_tran" ]]; then
            local pdev
            pdev=$(echo "$(basename "$dev")" | sed 's/p[0-9]*$//' | sed 's/[0-9]*$//')
            dev_tran=$(lsblk -ndo TRAN "/dev/$pdev" 2>/dev/null || echo "")
        fi

        if [[ "$udev_bus" == "usb" || "$dev_tran" == "usb" || "$dev_tran" == "mmc" || "$is_hotplug" == "1" ]]; then
            # Skip internal NVMe and zram
            if [[ "$dev" == /dev/nvme* || "$dev" == /dev/zram* ]]; then
                continue
            fi
            # Skip parent disk nodes (e.g. /dev/sda) when partitions exist
            local partcount
            partcount=$(lsblk -npo NAME "$dev" 2>/dev/null | wc -l)
            if [[ "$partcount" -gt 1 ]]; then
                continue
            fi
            # Is it a partition? (has a number at the end like sda1)
            if [[ ! "$dev" =~ [0-9]$ ]]; then
                # It's a whole disk — check if it has partitions
                local parts
                parts=$(lsblk -npo NAME "$dev" 2>/dev/null | tail -n +2)
                if [[ -n "$parts" ]]; then
                    continue  # Skip, we'll catch the partitions instead
                fi
            fi

            if [[ $found -gt 0 ]]; then
                echo ","
            fi
            get_device_info "$dev" "info"
            found=$((found + 1))
        fi
    done
    echo "]"
}

# ── Mode: --info <device> ────────────────────────────────────────

single_info() {
    local dev="$1"
    if [[ ! -b "$dev" ]]; then
        echo "{\"error\": \"Device $dev not found\"}"
        exit 1
    fi
    get_device_info "$dev" "info"
}

# ── Mode: --eject <device> ───────────────────────────────────────

eject_device() {
    local dev="$1"
    if [[ ! -b "$dev" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Device $dev not found\"}"
        exit 1
    fi

    # Determine if it's a partition or disk
    local parent_dev
    if [[ "$dev" =~ p[0-9]+$ || "$dev" =~ [0-9]$ ]]; then
        # It's a partition (e.g. sda1 or mmcblk0p1)
        # Get parent disk name
        parent_dev=$(echo "$(basename "$dev")" | sed 's/p[0-9]*$//' | sed 's/[0-9]*$//')
        parent_dev="/dev/$parent_dev"
    else
        parent_dev="$dev"
    fi

    # 1. Unmount all partitions belonging to this parent disk
    local unmount_success=true
    local parts
    parts=$(lsblk -pnlo NAME,MOUNTPOINT "$parent_dev" 2>/dev/null | awk '$2 != "" {print $1}')
    for part in $parts; do
        if ! udisksctl unmount -b "$part" 2>/dev/null; then
            # Fallback to standard umount
            if ! umount "$part" 2>/dev/null; then
                unmount_success=false
            fi
        fi
    done

    if [ "$unmount_success" = false ]; then
        echo "{\"status\":\"error\",\"message\":\"Failed to unmount partition(s). Some files might be in use.\"}"
        exit 1
    fi

    # 2. Power off the device if it's on USB bus
    local is_usb
    is_usb=$(udevadm info --query=property --name="$parent_dev" 2>/dev/null | grep -oP 'ID_BUS=\K.*' || echo "")
    if [[ "$is_usb" == "usb" ]]; then
        if ! udisksctl power-off -b "$parent_dev" 2>/dev/null; then
            # Fallback success message even if power-off fails but unmount succeeded
            echo "{\"status\":\"success\",\"message\":\"Device unmounted. Safe to remove (power-off not supported).\"}"
            exit 0
        fi
    else
        # MMC cards or other devices just unmount
        echo "{\"status\":\"success\",\"message\":\"Device unmounted. Safe to remove.\"}"
        exit 0
    fi

    echo "{\"status\":\"success\",\"message\":\"Device safely ejected and powered off.\"}"
}

# ── Mode: monitor (default) ─────────────────────────────────────

monitor_events() {
    # Brief delay to let udev settle after a device appears
    local SETTLE_DELAY=0.2

    stdbuf -oL udevadm monitor --subsystem-match=block --subsystem-match=usb --udev --property 2>/dev/null | while read -r line; do
        # Match add/remove events for partition/disk nodes or USB devices
        if echo "$line" | grep -qE "^UDEV.*add.*\((block|usb)\)$"; then
            local subs
            subs=$(echo "$line" | grep -oP '\(\K[a-z]+(?=\)$)')

            # Wait for udev to finish setting up the device
            sleep "$SETTLE_DELAY"

            # Extract device path from the next DEVNAME= line
            local devname=""
            while read -r prop_line; do
                if [[ "$prop_line" == DEVNAME=* ]]; then
                    devname="${prop_line#DEVNAME=}"
                    break
                fi
                [[ -z "$prop_line" ]] && break
            done

            if [[ -n "$devname" ]]; then
                if [[ "$subs" == "block" ]]; then
                    if [[ -b "$devname" ]]; then
                        # Report USB, MMC, or hotplug devices
                        local udev_bus
                        udev_bus=$(udevadm info --query=property --name="$devname" 2>/dev/null | grep -oP 'ID_BUS=\K.*' || echo "")
                        
                        local dev_tran
                        dev_tran=$(lsblk -ndo TRAN "$devname" 2>/dev/null || echo "")
                        if [[ -z "$dev_tran" ]]; then
                            local pdev
                            pdev=$(echo "$(basename "$devname")" | sed 's/p[0-9]*$//' | sed 's/[0-9]*$//')
                            dev_tran=$(lsblk -ndo TRAN "/dev/$pdev" 2>/dev/null || echo "")
                        fi
                        
                        local is_hotplug
                        is_hotplug=$(lsblk -ndo HOTPLUG "$devname" 2>/dev/null || echo "")

                        if [[ "$udev_bus" == "usb" || "$dev_tran" == "usb" || "$dev_tran" == "mmc" || "$is_hotplug" == "1" ]]; then
                            # Skip internal NVMe and zram
                            if [[ "$devname" != /dev/nvme* && "$devname" != /dev/zram* ]]; then
                                # Skip parent disk nodes (e.g. /dev/sda) when partitions exist
                                if [[ ! "$devname" =~ [0-9]$ ]]; then
                                    local parts
                                    parts=$(lsblk -npo NAME "$devname" 2>/dev/null | tail -n +2)
                                    if [[ -n "$parts" ]]; then
                                        continue
                                    fi
                                fi
                                get_device_info "$devname" "add"
                            fi
                        fi
                    fi
                elif [[ "$subs" == "usb" ]]; then
                    get_usb_device_info "$devname" "add"
                fi
            fi

        elif echo "$line" | grep -qE "^UDEV.*remove.*\((block|usb)\)$"; then
            local subs
            subs=$(echo "$line" | grep -oP '\(\K[a-z]+(?=\)$)')

            local devname=""
            while read -r prop_line; do
                if [[ "$prop_line" == DEVNAME=* ]]; then
                    devname="${prop_line#DEVNAME=}"
                    break
                fi
                [[ -z "$prop_line" ]] && break
            done

            if [[ -n "$devname" ]]; then
                if [[ "$subs" == "block" ]]; then
                    # Skip NVMe and zram on removal to avoid noise
                    if [[ "$devname" != /dev/nvme* && "$devname" != /dev/zram* ]]; then
                        echo "{\"event\":\"remove\",\"device\":\"$(json_escape "$devname")\",\"timestamp\":\"$(date -Iseconds)\"}"
                    fi
                elif [[ "$subs" == "usb" ]]; then
                    # Skip internal root hubs (ends with /001)
                    if [[ ! "$devname" =~ /001$ ]]; then
                        echo "{\"event\":\"remove\",\"device\":\"$(json_escape "$devname")\",\"timestamp\":\"$(date -Iseconds)\"}"
                    fi
                fi
            fi
        fi
    done
}

# ── Main ─────────────────────────────────────────────────────────

case "${1:-}" in
    --list)
        list_usb_devices
        ;;
    --info)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: $0 --info /dev/sdX1" >&2
            exit 1
        fi
        single_info "$2"
        ;;
    --eject)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: $0 --eject /dev/sdX1" >&2
            exit 1
        fi
        eject_device "$2"
        ;;
    --help|-h)
        cat <<EOF
USB Device Monitor for Arch Linux

Usage:
  $(basename "$0")              Monitor for USB plug/unplug events (streams JSON)
  $(basename "$0") --list       List all currently connected USB storage devices
  $(basename "$0") --info DEV   Show info for a specific device (e.g. /dev/sda1)
  $(basename "$0") --eject DEV  Safely unmount and eject / power off an external device (e.g. /dev/sda1)
  $(basename "$0") --help       Show this help message

Output: JSON objects with device details including vendor, model, filesystem,
        size, mount point, usage statistics, and device type classification.
EOF
        ;;
    *)
        monitor_events
        ;;
esac
