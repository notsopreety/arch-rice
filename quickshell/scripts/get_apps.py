#!/usr/bin/env python3
import json
import gi
gi.require_version('Gio', '2.0')
gi.require_version('Gtk', '3.0')
from gi.repository import Gio, Gtk
import os

def ensure_desktop_entries():
    apps_dir = os.path.expanduser("~/.local/share/applications")
    try:
        os.makedirs(apps_dir, exist_ok=True)
    except Exception:
        return
        
    entries = {
        "quickshell-calc.desktop": """[Desktop Entry]
Name=Calculator (Quickshell)
Comment=Quickshell Calculator Application
Exec=quickshell ipc call quickshell run "calculator"
Icon=accessories-calculator
Terminal=false
Type=Application
Categories=Utility;Calculator;System;
""",
        "quickshell-notepad.desktop": """[Desktop Entry]
Name=Notepad (Quickshell)
Comment=Quickshell Notepad Text Editor
Exec=quickshell ipc call quickshell run "notepad"
Icon=accessories-text-editor
Terminal=false
Type=Application
Categories=Utility;TextEditor;
""",
        "quickshell-sysmon.desktop": """[Desktop Entry]
Name=System Monitor (Quickshell)
Comment=Quickshell Desktop System Monitor
Exec=quickshell ipc call quickshell run "systemmonitor"
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Utility;Monitor;
""",
        "quickshell-screentime.desktop": """[Desktop Entry]
Name=Screen Time (Quickshell)
Comment=Quickshell Digital Wellbeing & Screen Time Analytics
Exec=quickshell ipc call quickshell run "screentime"
Icon=preferences-system-time
Terminal=false
Type=Application
Categories=Utility;System;Clock;
"""
    }

    for filename, content in entries.items():
        filepath = os.path.join(apps_dir, filename)
        if not os.path.exists(filepath):
            try:
                with open(filepath, "w") as f:
                    f.write(content)
            except Exception:
                pass

def get_apps():
    apps = Gio.AppInfo.get_all()
    theme = Gtk.IconTheme.get_default()
    app_list = []
    seen = set()

    preferred = ['kitty', 'brave', 'firefox', 'dolphin', 'code', 'discord', 'spotify', 'steam', 'thunar']

    def get_score(app_name, app_cmd):
        name_lower = app_name.lower()
        cmd_lower = app_cmd.lower()
        for i, p in enumerate(preferred):
            if p in name_lower or p in cmd_lower:
                return i
        return 999

    def clean_cmd(raw_cmd):
        if not raw_cmd:
            return ""
        import re
        return re.sub(r'%[uUfFdDnNickvm]', '', raw_cmd).strip()

    for app in apps:
        if not app.should_show():
            continue

        name = app.get_display_name()
        if name in seen:
            continue

        app_id = app.get_id() or ""

        icon = app.get_icon()
        icon_path = ""
        if icon:
            if hasattr(icon, 'get_names'):
                for n in icon.get_names():
                    icon_info = theme.lookup_icon(n, 48, 0)
                    if icon_info:
                        icon_path = icon_info.get_filename()
                        if icon_path: break
            elif hasattr(icon, 'to_string'):
                icon_str = icon.to_string()
                if icon_str.startswith('/'):
                    icon_path = icon_str
                else:
                    icon_info = theme.lookup_icon(icon_str, 48, 0)
                    if icon_info:
                        icon_path = icon_info.get_filename()

        exec_cmd = app.get_commandline() or app.get_executable()
        categories = app.get_categories() if hasattr(app, 'get_categories') else ""
        needs_terminal = app.get_boolean('Terminal') if hasattr(app, 'get_boolean') else False

        if exec_cmd:
            cmd_clean = clean_cmd(exec_cmd)
            icon_uri = f"file://{icon_path}" if icon_path else ""
            app_list.append({
                "name": name,
                "icon": icon_uri,
                "cmd": cmd_clean,
                "id": app_id,
                "terminal": needs_terminal,
                "categories": categories or "",
                "score": get_score(name, cmd_clean)
            })
            seen.add(name)

    # Quickshell custom applications are now loaded dynamically from their generated .desktop files.

    app_list.sort(key=lambda x: x['name'].lower())
    for app in app_list:
        if 'score' in app:
            del app['score']
    return app_list

if __name__ == "__main__":
    ensure_desktop_entries()
    print(json.dumps(get_apps()))
