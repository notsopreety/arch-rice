#!/usr/bin/env python3

import subprocess

# Get active connection name
try:
    ssid = subprocess.check_output(
        ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"],
        text=True
    ).splitlines()[0]

    # Get password
    password = subprocess.check_output(
        [
            "nmcli",
            "-s",
            "-g",
            "802-11-wireless-security.psk",
            "connection",
            "show",
            ssid,
        ],
        text=True
    ).strip()

    wifi_qr = f"WIFI:T:WPA;S:{ssid};P:{password};;"

    print(f"Network name: {ssid}")
    print(f"Password: {password}")
    print("Network type: WPA/WPA2")
    print()

    subprocess.run(
        ["qrencode", "-t", "ANSIUTF8", wifi_qr],
        check=True
    )

    # Also save PNG for QML display
    subprocess.run(
        ["qrencode", "-o", "/tmp/qr_wifi.png", wifi_qr],
        check=True, capture_output=True
    )
except Exception as e:
    print(f"Error: {e}")
