#!/usr/bin/env python3

import os
import subprocess
import tempfile

# Make sure the QR PNG we create is never group/world readable
os.umask(0o077)


def qr_output_path():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    if runtime_dir:
        return os.path.join(runtime_dir, "quickshell-qr_wifi.png")
    # No runtime dir: use a unique mkstemp path instead of a predictable /tmp name
    fd, path = tempfile.mkstemp(prefix="quickshell-qr_wifi-", suffix=".png")
    os.close(fd)
    return path


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

    # Also save PNG for QML display (path is printed for the widget to read)
    qr_path = qr_output_path()
    subprocess.run(
        ["qrencode", "-o", qr_path, wifi_qr],
        check=True, capture_output=True
    )
    os.chmod(qr_path, 0o600)
    print(f"QR path: {qr_path}")
except Exception as e:
    print(f"Error: {e}")
