#!/usr/bin/env python3
import socket
import os
import json
import time
import signal
import sys
from datetime import datetime, date

CACHE_DIR = os.path.expanduser("~/.cache/screentime")
os.makedirs(CACHE_DIR, exist_ok=True)

# State
data = {}
current_app = None
start_time = time.time()
is_paused = False
last_save_time = time.time()

def get_today_file():
    today = date.today().isoformat()
    return os.path.join(CACHE_DIR, f"{today}.json")

def load_data():
    global data
    filepath = get_today_file()
    if os.path.exists(filepath):
        try:
            with open(filepath, "r") as f:
                data = json.load(f)
        except Exception:
            data = {}
    else:
        data = {}

def save_data():
    filepath = get_today_file()
    tmp_path = filepath + ".tmp"
    try:
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=4)
        os.replace(tmp_path, filepath)
    except Exception as e:
        print(f"Error saving data: {e}")

def add_time_to_app(app, duration):
    if not app or duration <= 0:
        return
    if app not in data:
        data[app] = {"time": 0, "opens": 0}
    data[app]["time"] += duration

def switch_app(new_app):
    global current_app, start_time, is_paused
    now = time.time()
    
    if not is_paused and current_app:
        duration = now - start_time
        add_time_to_app(current_app, duration)
    
    current_app = new_app
    start_time = now

def record_open(app):
    if not app:
        return
    if app not in data:
        data[app] = {"time": 0, "opens": 0}
    data[app]["opens"] += 1

def handle_event(event_line):
    global is_paused, start_time, last_save_time
    
    parts = event_line.split(">>")
    if len(parts) < 2:
        return
    
    event = parts[0]
    payload = ">>".join(parts[1:])
    
    if event == "activewindow":
        if "," in payload:
            app_class = payload.split(",", 1)[0].strip()
        else:
            app_class = payload.strip()
        
        if app_class:
            switch_app(app_class)
            
    elif event == "openwindow":
        p = payload.split(",", 3)
        if len(p) >= 3:
            app_class = p[2].strip()
            if app_class:
                record_open(app_class)
                
    elif event == "dpms":
        status = payload.strip()
        if status == "0" or status == "false":
            if not is_paused:
                now = time.time()
                if current_app:
                    add_time_to_app(current_app, now - start_time)
                is_paused = True
        elif status == "1" or status == "true":
            if is_paused:
                is_paused = False
                start_time = time.time()

def cleanup(signum, frame):
    if not is_paused and current_app:
        add_time_to_app(current_app, time.time() - start_time)
    save_data()
    exit(0)

def force_save(signum, frame):
    global start_time
    if not is_paused and current_app:
        add_time_to_app(current_app, time.time() - start_time)
        start_time = time.time()
    save_data()

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--flush":
        # Simply send the signal to the running daemon and exit
        os.system("pkill -SIGUSR1 -f screentime_daemon.py")
        print("Flush signal sent to running daemon.")
        exit(0)

    global last_save_time, start_time, current_app
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGUSR1, force_save)
    
    load_data()
    
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        print("Error: HYPRLAND_INSTANCE_SIGNATURE not found.")
        exit(1)
        
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    socket_path = os.path.join(xdg_runtime, "hypr", signature, ".socket2.sock")
    
    while True:
        if not os.path.exists(socket_path):
            print(f"Waiting for socket at {socket_path}...")
            time.sleep(5)
            continue
            
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(socket_path)
            s.settimeout(1.0)
            print("Connected to Hyprland IPC!")
        except Exception as e:
            print(f"Connection failed: {e}")
            time.sleep(5)
            continue
            
        buffer = ""
        while True:
            try:
                chunk = s.recv(4096).decode("utf-8")
                if not chunk:
                    print("Connection closed, reconnecting...")
                    break # Break inner loop to reconnect
                buffer += chunk
                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    try:
                        handle_event(line.strip())
                    except Exception as ev_err:
                        print(f"Event error: {ev_err}")
            except socket.timeout:
                pass
            except Exception as e:
                print(f"Socket error: {e}")
                time.sleep(1)
                break # Break inner loop to reconnect
                
            now = time.time()
            if now - last_save_time > 300:
                if not is_paused and current_app:
                    add_time_to_app(current_app, now - start_time)
                    start_time = now
                
                current_date = date.today().isoformat()
                if not get_today_file().endswith(f"{current_date}.json"):
                    save_data()
                    load_data()
                    
                save_data()
                last_save_time = now

        # Inner loop broken, clean up socket and retry
        s.close()
        time.sleep(3)

if __name__ == "__main__":
    main()
