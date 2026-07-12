import sys
import re
import json

file_path = "/home/sawmer/.config/hypr/lua.d/keybinds.lua"
binds = []

with open(file_path, "r") as f:
    content = f.read()

def clean_desc(raw_desc):
    if "programs.terminal" in raw_desc: return "Terminal"
    if "programs.fileManager" in raw_desc: return "File Manager"
    if "programs.menu" in raw_desc: return "App Launcher"
    if "window.close" in raw_desc: return "Close Window"
    if "window.float" in raw_desc: return "Toggle Floating"
    if "window.fullscreen" in raw_desc: return "Toggle Fullscreen"
    if "hyprshutdown" in raw_desc: return "Logout Hyprland"
    if "colresize +conf" in raw_desc: return "Resize Column +"
    if "colresize -conf" in raw_desc: return "Resize Column -"
    if "colresize" in raw_desc: return "Resize Column"
    if "focus l" in raw_desc: return "Focus Column Left"
    if "focus r" in raw_desc: return "Focus Column Right"
    if "swapcol l" in raw_desc: return "Swap Column Left"
    if "swapcol r" in raw_desc: return "Swap Column Right"
    if "focus({ workspace =" in raw_desc: return "Switch Workspace"
    if "window.move({ workspace =" in raw_desc: return "Move to Workspace"
    if "toggle_special" in raw_desc: return "Toggle Scratchpad"
    if "wallpaper" in raw_desc: return "Wallpaper Picker"
    if "wallpapers" in raw_desc: return "Wallpaper Launcher Tab"
    if "overview" in raw_desc: return "Overview"
    if "performance" in raw_desc: return "Performance Monitor"
    if "workspace" in raw_desc: return "Workspace Overview"
    if "launcher" in raw_desc: return "App Launcher"
    if "clipboard" in raw_desc: return "Clipboard History"
    if "emojiboard" in raw_desc: return "Emoji Board"
    if "keybinds" in raw_desc: return "Keybinds"
    if "notepad" in raw_desc: return "Notepad"
    if "screenshot" in raw_desc: return "Screenshot"
    if "screenrecorder" in raw_desc: return "Screen Recorder"
    if "sniptool" in raw_desc: return "Sniptool"
    if "glens" in raw_desc: return "Google Lens Search"
    if "powermenu" in raw_desc: return "Power Menu"
    if "lock" in raw_desc: return "Lock Screen"
    if "quickshell" in raw_desc and "ipc" not in raw_desc: return "Dank Dash Dashboard"
    if "window.drag" in raw_desc: return "Move Window"
    if "window.resize" in raw_desc: return "Resize Window"
    if "set-volume -l 1" in raw_desc: return "Volume Up"
    if "set-volume" in raw_desc and "-" in raw_desc: return "Volume Down"
    if "set-mute @DEFAULT_AUDIO_SINK@" in raw_desc: return "Mute Audio"
    if "set-mute @DEFAULT_AUDIO_SOURCE@" in raw_desc: return "Mute Microphone"
    if "brightnessctl" in raw_desc and "+" in raw_desc: return "Brightness Up"
    if "brightnessctl" in raw_desc and "-" in raw_desc: return "Brightness Down"
    if "playerctl next" in raw_desc: return "Media Next"
    if "playerctl previous" in raw_desc: return "Media Prev"
    if "playerctl play-pause" in raw_desc: return "Media Play/Pause"
    if raw_desc.startswith("function"): return "Custom Lua Function"
    
    d = raw_desc.replace('hl.dsp.exec_cmd(', '').replace('hl.dsp.', '')
    d = re.sub(r'\)$', '', d)
    return d.strip(' \'"')

for line in content.split('\n'):
    line = line.strip()
    if line.startswith('--') or 'hl.bind' not in line:
        continue
    
    # Check if this is the loop var line
    if '.. key' in line:
        continue # We unroll this below
        
    m = re.search(r'hl\.bind\((.*?),\s*(.*?)(?:,\s*\{.*?\})?\)', line)
    if m:
        keys = m.group(1).replace('mainMod .. "', 'SUPER').replace('"', '').replace(' .. ', '').strip()
        keys = re.sub(r'\s*\+\s*', ' + ', keys)
        desc = clean_desc(m.group(2).strip())
        
        cat = "System"
        if "Window" in desc or "Column" in desc or "Float" in desc or "Scratchpad" in desc:
            cat = "Window"
        elif "Workspace" in desc:
            cat = "Workspace"
        elif "Quickshell" in desc or "Dashboard" in desc or "Wallpaper" in desc or "Clipboard" in desc or "Emoji" in desc:
            cat = "Quickshell"
            
        binds.append({"keys": keys, "desc": desc, "cat": cat})

# Manual unroll of the loop that we skipped
for i in range(1, 11):
    k = i % 10
    binds.append({"keys": f"SUPER + {k}", "desc": f"Switch Workspace", "cat": "Workspace"})
    binds.append({"keys": f"SUPER + SHIFT + {k}", "desc": f"Move to Workspace", "cat": "Workspace"})

gesture_pattern = re.compile(r'hl\.gesture\(\s*\{(.*?)\}\s*\)', re.DOTALL)
for match in gesture_pattern.finditer(content):
    body = match.group(1)
    fingers = ""
    direction = ""
    action = ""
    for line in body.split('\n'):
        line = line.strip()
        if line.startswith('fingers'):
            fingers = line.split('=')[1].strip().replace(',', '')
        elif line.startswith('direction'):
            direction = line.split('=')[1].strip().replace('"', '').replace(',', '')
        elif line.startswith('action'):
            action = line.split('=')[1].strip().replace(',', '')
    
    desc = clean_desc(action)
    binds.append({
        "keys": f"{fingers}-Finger {direction.capitalize()}",
        "desc": desc,
        "cat": "Gesture"
    })

print(json.dumps(binds))
