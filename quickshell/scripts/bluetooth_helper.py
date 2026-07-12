#!/usr/bin/env python3
import sys
import os
import json
import subprocess
import threading
import time
import re

# Keep track of known devices
devices = {}
# Thread lock for device dict updates
devices_lock = threading.Lock()

def debug_log(msg):
    # Print to stderr for debugging
    print(f"DEBUG: {msg}", file=sys.stderr, flush=True)

def parse_device_info(line):
    """
    Parses lines from bluetoothctl output like:
    [NEW] Device 58:66:D2:C7:9B:97 Mivi Commando Q9
    [CHG] Device 58:66:D2:C7:9B:97 Connected: yes
    Device 58:66:D2:C7:9B:97 Paired: yes
    Device 58:66:D2:C7:9B:97 RSSI: -65
    """
    # Regex patterns
    new_pattern = re.compile(r'^\[NEW\]\s+Device\s+([0-9A-Fa-f:]{17})\s+(.*)$')
    chg_pattern = re.compile(r'^\[CHG\]\s+Device\s+([0-9A-Fa-f:]{17})\s+(\S+):\s*(.*)$')
    info_pattern = re.compile(r'^\s*Device\s+([0-9A-Fa-f:]{17})\s+(\S+):\s*(.*)$')
    
    mac = None
    updates = {}
    
    m = new_pattern.match(line)
    if m:
        mac = m.group(1)
        name = m.group(2).strip()
        updates['address'] = mac
        if name and not name.startswith("Device"):
            updates['name'] = name
            updates['alias'] = name
    else:
        m = chg_pattern.match(line)
        if m:
            mac = m.group(1)
            key = m.group(2).strip().replace(":", "")
            val = m.group(3).strip()
            updates['address'] = mac
            if key == "Connected":
                updates['connected'] = (val.lower() == "yes")
            elif key == "Paired":
                updates['paired'] = (val.lower() == "yes")
            elif key == "Blocked":
                updates['blocked'] = (val.lower() == "yes")
            elif key == "Trusted":
                updates['trusted'] = (val.lower() == "yes")
            elif key == "Alias":
                updates['alias'] = val
            elif key == "Name":
                updates['name'] = val
            elif key == "RSSI":
                try:
                    updates['rssi'] = int(val)
                except ValueError:
                    pass
            elif key == "Icon":
                updates['icon'] = val
            elif key == "Battery Percentage" or key == "Battery":
                try:
                    if "(" in val:
                        val = val.split("(")[1].replace(")", "").strip()
                    updates['battery'] = int(val)
                    updates['batteryAvailable'] = True
                except ValueError:
                    pass
        else:
            m = info_pattern.match(line)
            if m:
                mac = m.group(1)
                key = m.group(2).strip().replace(":", "")
                val = m.group(3).strip()
                updates['address'] = mac
                if key == "Connected":
                    updates['connected'] = (val.lower() == "yes")
                elif key == "Paired":
                    updates['paired'] = (val.lower() == "yes")
                elif key == "Alias":
                    updates['alias'] = val
                elif key == "Name":
                    updates['name'] = val
                elif key == "RSSI":
                    try:
                        updates['rssi'] = int(val)
                    except ValueError:
                        pass
                elif key == "Icon":
                    updates['icon'] = val
                elif key == "Battery Percentage" or key == "Battery":
                    try:
                        if "(" in val:
                            val = val.split("(")[1].replace(")", "").strip()
                        updates['battery'] = int(val)
                        updates['batteryAvailable'] = True
                    except ValueError:
                        pass

    return mac, updates

def get_initial_devices():
    """Run bluetoothctl devices and info to populate starting list."""
    try:
        # Get list of devices
        out = subprocess.check_output(["bluetoothctl", "devices"], text=True)
        for line in out.splitlines():
            # Device 58:66:D2:C7:9B:97 Mivi Commando Q9
            parts = line.split(maxsplit=2)
            if len(parts) >= 3 and parts[0] == "Device":
                mac = parts[1]
                name = parts[2]
                with devices_lock:
                    devices[mac] = {
                        'address': mac,
                        'name': name,
                        'alias': name,
                        'connected': False,
                        'paired': False,
                        'trusted': False,
                        'rssi': 0,
                        'icon': 'bluetooth'
                    }
        
        # Populate details for known devices (especially paired/connected state)
        # To make it fast, we can scan info in background or read specific details
        # bluetoothctl info doesn't take too long for a few devices.
        for mac in list(devices.keys()):
            try:
                info_out = subprocess.check_output(["bluetoothctl", "info", mac], text=True, timeout=1.0)
                updates = {}
                for line in info_out.splitlines():
                    #   Name: Mivi Commando Q9
                    #   Alias: Mivi Commando Q9
                    #   Paired: yes
                    #   Connected: yes
                    line_strip = line.strip()
                    if ":" in line_strip:
                        k, v = line_strip.split(":", 1)
                        k = k.strip()
                        v = v.strip()
                        if k == "Name":
                            updates['name'] = v
                        elif k == "Alias":
                            updates['alias'] = v
                        elif k == "Paired":
                            updates['paired'] = (v.lower() == "yes")
                        elif k == "Connected":
                            updates['connected'] = (v.lower() == "yes")
                        elif k == "Trusted":
                            updates['trusted'] = (v.lower() == "yes")
                        elif k == "Icon":
                            updates['icon'] = v
                        elif k == "Battery Percentage" or k == "Battery":
                            try:
                                if "(" in v:
                                    v = v.split("(")[1].replace(")", "").strip()
                                updates['battery'] = int(v)
                                updates['batteryAvailable'] = True
                            except ValueError:
                                pass
                
                with devices_lock:
                    if mac in devices:
                        devices[mac].update(updates)
            except Exception:
                pass
    except Exception as e:
        debug_log(f"Error getting initial devices: {e}")

def broadcast_devices():
    """Prints the device list as JSON to stdout."""
    with devices_lock:
        device_list = list(devices.values())
    print(json.dumps(device_list), flush=True)

def monitor_bluetoothctl():
    """Runs bluetoothctl as a subprocess and monitors events in real-time."""
    get_initial_devices()
    broadcast_devices()
    
    # Run bluetoothctl in a persistent interactive sub-process
    proc = subprocess.Popen(
        ["bluetoothctl"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    
    # Thread to handle writing commands to bluetoothctl stdin
    def handle_commands():
        for line in sys.stdin:
            cmd = line.strip()
            if not cmd:
                continue
            
            # Custom commands parsed from QML
            # e.g., "scan on", "connect 58:66:D2:C7:9B:97"
            debug_log(f"Received command: {cmd}")
            if cmd == "scan on":
                proc.stdin.write("scan on\n")
            elif cmd == "scan off":
                proc.stdin.write("scan off\n")
            elif cmd.startswith("connect "):
                mac = cmd.split(maxsplit=1)[1]
                proc.stdin.write(f"connect {mac}\n")
            elif cmd.startswith("disconnect "):
                mac = cmd.split(maxsplit=1)[1]
                proc.stdin.write(f"disconnect {mac}\n")
            elif cmd.startswith("pair "):
                mac = cmd.split(maxsplit=1)[1]
                proc.stdin.write(f"pair {mac}\n")
            elif cmd.startswith("remove "):
                mac = cmd.split(maxsplit=1)[1]
                proc.stdin.write(f"remove {mac}\n")
            elif cmd.startswith("trust "):
                mac = cmd.split(maxsplit=1)[1]
                proc.stdin.write(f"trust {mac}\n")
            elif cmd.startswith("untrust "):
                mac = cmd.split(maxsplit=1)[1]
                proc.stdin.write(f"untrust {mac}\n")
            proc.stdin.flush()
            
    cmd_thread = threading.Thread(target=handle_commands, daemon=True)
    cmd_thread.start()
    
    # Read output line by line
    last_broadcast_time = time.time()
    for line in proc.stdout:
        line = line.strip()
        if not line:
            continue
        
        mac, updates = parse_device_info(line)
        if mac:
            with devices_lock:
                if mac not in devices:
                    devices[mac] = {
                        'address': mac,
                        'name': '',
                        'alias': '',
                        'connected': False,
                        'paired': False,
                        'trusted': False,
                        'rssi': 0,
                        'icon': 'bluetooth'
                    }
                devices[mac].update(updates)
            
            # Rate limit broadcasts to avoid spamming UI (max 10 broadcasts per second)
            now = time.time()
            if now - last_broadcast_time > 0.1:
                broadcast_devices()
                last_broadcast_time = now

if __name__ == "__main__":
    try:
        monitor_bluetoothctl()
    except KeyboardInterrupt:
        sys.exit(0)
