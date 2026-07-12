import json
import os
import sys
import time

CACHE_FILE = "/tmp/quickshell-sysinfo-cache.json"

def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except:
            pass
    return {}

def save_cache(cache):
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(cache, f)
    except:
        pass

def get_processes(cache, new_cache, time_diff):
    processes = []
    try:
        clk_tck = os.sysconf(os.sysconf_names['SC_CLK_TCK'])
    except:
        clk_tck = 100

    try:
        page_size = os.sysconf(os.sysconf_names['SC_PAGE_SIZE']) // 1024
    except:
        page_size = 4

    prev_procs = cache.get("proc_ticks", {})
    new_procs = {}

    uid_cache = {}
    import pwd
    def get_username(uid):
        if uid not in uid_cache:
            try:
                uid_cache[uid] = pwd.getpwuid(uid).pw_name
            except:
                uid_cache[uid] = str(uid)
        return uid_cache[uid]

    pids = [x for x in os.listdir("/proc") if x.isdigit()]
    
    for pid_str in pids:
        try:
            pid = int(pid_str)
            with open(f"/proc/{pid}/stat", "r") as f:
                stat_line = f.read().strip()
            
            lpar_idx = stat_line.find('(')
            rpar_idx = stat_line.rfind(')')
            if lpar_idx == -1 or rpar_idx == -1: continue
            
            comm = stat_line[lpar_idx + 1 : rpar_idx]
            rest = stat_line[rpar_idx + 2 :].split()
            if len(rest) < 22: continue
            
            utime = int(rest[11])
            stime = int(rest[12])
            total_ticks = utime + stime
            
            new_procs[pid_str] = total_ticks
            
            cpu_usage = 0.0
            if pid_str in prev_procs and time_diff > 0:
                ticks_diff = total_ticks - prev_procs[pid_str]
                if ticks_diff >= 0:
                    cpu_usage = ((ticks_diff / clk_tck) / time_diff * 100.0) / (os.cpu_count() or 1)
            
            with open(f"/proc/{pid}/statm", "r") as f:
                statm_line = f.read()
            rss_pages = int(statm_line.split()[1])
            memory_kb = rss_pages * page_size
            
            try:
                with open(f"/proc/{pid}/cmdline", "r") as f:
                    cmdline = f.read().replace("\0", " ").replace("\n", " ").replace("\r", " ").replace("\t", " ").strip()
                full_cmd = cmdline if cmdline else comm
            except:
                full_cmd = comm
                
            try:
                uid = os.stat(f"/proc/{pid}").st_uid
                username = get_username(uid)
            except:
                username = "root"

            processes.append({
                "pid": pid,
                "command": comm,
                "fullCommand": full_cmd,
                "cpu": round(cpu_usage, 2),
                "memoryKB": memory_kb,
                "username": username
            })
        except:
            continue

    new_cache["proc_ticks"] = new_procs
    return processes

def get_cpu(cache, new_cache):
    model = "Unknown"
    threads = 1
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "model name" in line:
                    model = line.split(":", 1)[1].strip()
                    break
        threads = os.cpu_count() or 1
    except:
        pass

    cpu_usage = 0.0
    core_usages = []
    try:
        with open("/proc/stat") as f:
            lines = f.readlines()
            
        parts = [float(x) for x in lines[0].split()[1:5]]
        idle = parts[3]
        total = sum(parts)
        if "cpu_total" in cache and "cpu_idle" in cache:
            total_diff = total - cache["cpu_total"]
            idle_diff = idle - cache["cpu_idle"]
            if total_diff > 0:
                cpu_usage = (1.0 - (idle_diff / total_diff)) * 100
        new_cache["cpu_total"] = total
        new_cache["cpu_idle"] = idle
        
        prev_cores = cache.get("cpu_cores_ticks", {})
        new_cores = {}
        
        # Read core temperatures dynamically from coretemp driver if available
        core_temps = {}
        pkg_temp = 0.0
        try:
            hwmon_path = None
            # Find the actual hwmon directory under coretemp.0
            if os.path.exists("/sys/devices/platform/coretemp.0/hwmon"):
                for hw in os.listdir("/sys/devices/platform/coretemp.0/hwmon"):
                    if hw.startswith("hwmon"):
                        hwmon_path = f"/sys/devices/platform/coretemp.0/hwmon/{hw}"
                        break
            if not hwmon_path and os.path.exists("/sys/devices/platform/coretemp.0"):
                hwmon_path = "/sys/devices/platform/coretemp.0"
                
            if hwmon_path:
                for f_name in os.listdir(hwmon_path):
                    if f_name.startswith("temp") and f_name.endswith("_label"):
                        label = open(f"{hwmon_path}/{f_name}").read().strip()
                        input_path = f"{hwmon_path}/{f_name.replace('_label', '_input')}"
                        if os.path.exists(input_path):
                            temp_val = int(open(input_path).read().strip()) / 1000.0
                            if label.startswith("Core"):
                                core_id = label.split()[1]
                                core_temps[core_id] = temp_val
                            elif label.startswith("Package") or "pkg" in label.lower():
                                pkg_temp = temp_val
        except:
            pass

        # Parse /proc/cpuinfo to map processor index to physical core id
        proc_to_core = {}
        try:
            current_proc = None
            with open("/proc/cpuinfo") as f:
                for line in f:
                    if line.startswith("processor"):
                        current_proc = line.split(":")[1].strip()
                    elif line.startswith("core id") and current_proc is not None:
                        proc_to_core[current_proc] = line.split(":")[1].strip()
        except:
            pass

        # Also fallback overall package temp if not fetched from hwmon
        if pkg_temp == 0.0:
            try:
                found_pkg_temp = False
                for zone in sorted(os.listdir("/sys/class/thermal")):
                    if zone.startswith("thermal_zone"):
                        t_path = f"/sys/class/thermal/{zone}/type"
                        if os.path.exists(t_path):
                            t_type = open(t_path).read().strip().lower()
                            if "pkg_temp" in t_type or t_type == "tcpu" or "coretemp" in t_type:
                                val_path = f"/sys/class/thermal/{zone}/temp"
                                if os.path.exists(val_path):
                                    pkg_temp = float(open(val_path).read().strip()) / 1000.0
                                    found_pkg_temp = True
                                    break
                if not found_pkg_temp:
                    for path in ["/sys/class/thermal/thermal_zone8/temp", "/sys/class/thermal/thermal_zone6/temp", "/sys/class/thermal/thermal_zone0/temp"]:
                        if os.path.exists(path):
                            pkg_temp = float(open(path).read().strip()) / 1000.0
                            break
            except:
                pass

        core_index = 0
        for line in lines[1:]:
            tokens = line.split()
            if not tokens or not tokens[0].startswith("cpu") or tokens[0] == "cpu":
                continue
            core_name = tokens[0]
            core_parts = [float(x) for x in tokens[1:5]]
            c_idle = core_parts[3]
            c_total = sum(core_parts)
            
            new_cores[core_name] = {"total": c_total, "idle": c_idle}
            
            c_usage = 0.0
            if core_name in prev_cores:
                c_tdiff = c_total - prev_cores[core_name]["total"]
                c_idiff = c_idle - prev_cores[core_name]["idle"]
                if c_tdiff > 0:
                    c_usage = (1.0 - (c_idiff / c_tdiff)) * 100
            
            # Map core index to core temps. On modern hybrid CPUs, E-cores and HT threads need physical mapping.
            core_id_str = str(core_index)
            actual_core_id = proc_to_core.get(core_id_str)
            c_temp = None
            if actual_core_id:
                c_temp = core_temps.get(actual_core_id)
            if c_temp is None:
                c_temp = core_temps.get(core_id_str, core_temps.get(str(core_index // 2), pkg_temp))
            
            core_usages.append({
                "index": core_index,
                "usage": round(c_usage, 1),
                "temp": c_temp
            })
            core_index += 1
            
        new_cache["cpu_cores_ticks"] = new_cores
    except:
        pass

    temp = pkg_temp

    freq = "0.0 GHz"
    try:
        if os.path.exists("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"):
            with open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq") as f:
                khz = float(f.read().strip())
                freq = f"{khz / 1000000.0:.2f} GHz"
    except:
        pass

    gov = "Unknown"
    try:
        if os.path.exists("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"):
            with open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor") as f:
                gov = f.read().strip()
    except:
        pass

    import platform
    arch = platform.machine()

    return {
        "usage": cpu_usage,
        "temperature": temp,
        "model": model,
        "count": threads,
        "cores": core_usages,
        "frequency": freq,
        "governor": gov,
        "architecture": arch
    }

def get_gpu():
    gpus = []
    try:
        import subprocess
        out = subprocess.check_output(["lspci", "-vmm"]).decode("utf-8")
        current_device = {}
        for line in out.splitlines():
            if not line.strip():
                if current_device:
                    dev_class = current_device.get("Class", "").lower()
                    if "vga" in dev_class or "3d" in dev_class or "display" in dev_class:
                        vendor = current_device.get("Vendor", "")
                        device_name = current_device.get("Device", "")
                        slot = current_device.get("Slot", "")
                        
                        is_dgpu = True
                        name_lower = device_name.lower()
                        vendor_lower = vendor.lower()
                        
                        if "intel" in vendor_lower:
                            if not "arc" in name_lower:
                                is_dgpu = False
                        elif "amd" in vendor_lower:
                            if "integrated" in name_lower or "apus" in name_lower or "graphics" in name_lower and not any(x in name_lower for x in ["rx ", "xt ", "pro "]):
                                is_dgpu = False
                        
                        temp = 0.0
                        try:
                            found_temp = False
                            for card in os.listdir("/sys/class/drm"):
                                if card.startswith("card") and not "-" in card:
                                    hwmon_path = f"/sys/class/drm/{card}/device/hwmon"
                                    if os.path.exists(hwmon_path):
                                        for hw in os.listdir(hwmon_path):
                                            t_file = f"{hwmon_path}/{hw}/temp1_input"
                                            if os.path.exists(t_file):
                                                temp = int(open(t_file).read().strip()) / 1000.0
                                                found_temp = True
                                                break
                                    if found_temp:
                                        break
                        except:
                            pass
                        
                        if temp == 0.0:
                            # For integrated GPUs, read CPU package temperature as they share the same die
                            if not is_dgpu:
                                try:
                                    hwmon_path = None
                                    if os.path.exists("/sys/devices/platform/coretemp.0/hwmon"):
                                        for hw in os.listdir("/sys/devices/platform/coretemp.0/hwmon"):
                                            if hw.startswith("hwmon"):
                                                hwmon_path = f"/sys/devices/platform/coretemp.0/hwmon/{hw}"
                                                break
                                    if not hwmon_path and os.path.exists("/sys/devices/platform/coretemp.0"):
                                        hwmon_path = "/sys/devices/platform/coretemp.0"
                                    if hwmon_path:
                                        for f_name in os.listdir(hwmon_path):
                                            if f_name.startswith("temp") and f_name.endswith("_label"):
                                                label = open(f"{hwmon_path}/{f_name}").read().strip()
                                                if label.startswith("Package") or "pkg" in label.lower():
                                                    input_path = f"{hwmon_path}/{f_name.replace('_label', '_input')}"
                                                    if os.path.exists(input_path):
                                                        temp = int(open(input_path).read().strip()) / 1000.0
                                                        break
                                except:
                                    pass

                        if temp == 0.0:
                            for path in ["/sys/class/thermal/thermal_zone8/temp", "/sys/class/thermal/thermal_zone6/temp", "/sys/class/thermal/thermal_zone0/temp", "/sys/class/thermal/thermal_zone1/temp", "/sys/class/thermal/thermal_zone2/temp"]:
                                if os.path.exists(path):
                                    temp = float(open(path).read().strip()) / 1000.0
                                    break
                        
                        usage = 0.0
                        if "intel" in vendor_lower:
                            try:
                                for card in os.listdir("/sys/class/drm"):
                                    if card.startswith("card") and not "-" in card:
                                        cur_paths = [
                                            f"/sys/class/drm/{card}/gt_cur_freq_mhz",
                                            f"/sys/class/drm/{card}/device/drm/{card}/gt_cur_freq_mhz",
                                            f"/sys/class/drm/{card}/device/gt_cur_freq_mhz"
                                        ]
                                        max_paths = [
                                            f"/sys/class/drm/{card}/gt_max_freq_mhz",
                                            f"/sys/class/drm/{card}/device/drm/{card}/gt_max_freq_mhz",
                                            f"/sys/class/drm/{card}/device/gt_max_freq_mhz"
                                        ]
                                        cur_f, max_f = 0.0, 0.0
                                        for p in cur_paths:
                                            if os.path.exists(p):
                                                cur_f = float(open(p).read().strip())
                                                break
                                        for p in max_paths:
                                            if os.path.exists(p):
                                                max_f = float(open(p).read().strip())
                                                break
                                        if max_f > 0:
                                            usage = (cur_f / max_f) * 100.0
                                            break
                            except:
                                pass
                        elif "nvidia" in vendor_lower:
                            try:
                                nv_out = subprocess.check_output(["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]).decode("utf-8")
                                usage = float(nv_out.strip())
                            except:
                                pass
                        elif "amd" in vendor_lower:
                            try:
                                for card in os.listdir("/sys/class/drm"):
                                    if card.startswith("card") and not "-" in card:
                                        busy_path = f"/sys/class/drm/{card}/device/gpu_busy_percent"
                                        if os.path.exists(busy_path):
                                            usage = float(open(busy_path).read().strip())
                                            break
                            except:
                                pass

                        gpus.append({
                            "displayName": device_name,
                            "name": device_name,
                            "vendor": vendor,
                            "temperature": temp,
                            "usage": round(usage, 1),
                            "pciId": slot,
                            "isDedicated": is_dgpu,
                            "typeLabel": "Dedicated (dGPU)" if is_dgpu else "Integrated (iGPU)",
                            "driver": current_device.get("Driver", "System GPU driver")
                        })
                current_device = {}
            else:
                parts = line.split(":", 1)
                if len(parts) == 2:
                    current_device[parts[0].strip()] = parts[1].strip()
    except Exception as e:
        pass
    return gpus

def main():
    cache = load_cache()
    new_cache = {}
    now = time.time()
    new_cache["timestamp"] = now
    
    time_diff = now - cache.get("timestamp", 0) if "timestamp" in cache else 0
    if time_diff <= 0:
        time_diff = 1.0

    if "proc_ticks" in cache:
        new_cache["proc_ticks"] = cache["proc_ticks"]

    # --- CPU ---
    cpu_data = get_cpu(cache, new_cache)

    # --- Memory ---
    mem_total, mem_free, mem_available, mem_buffers, mem_cached = 0, 0, 0, 0, 0
    swap_total, swap_free = 0, 0
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split()
                if not parts: continue
                key = parts[0]
                val = int(parts[1]) * 1024
                if key == "MemTotal:": mem_total = val
                elif key == "MemFree:": mem_free = val
                elif key == "MemAvailable:": mem_available = val
                elif key == "Buffers:": mem_buffers = val
                elif key == "Cached:": mem_cached = val
                elif key == "SwapTotal:": swap_total = val
                elif key == "SwapFree:": swap_free = val
    except:
        pass
    mem_used = mem_total - mem_available if mem_available else mem_total - mem_free - mem_buffers - mem_cached
    mem_used_percent = (mem_used / mem_total) * 100 if mem_total > 0 else 0

    # --- Network ---
    network_interfaces = []
    total_rx = 0
    total_tx = 0
    try:
        with open("/proc/net/dev") as f:
            lines = f.readlines()
            for line in lines[2:]:
                parts = line.split()
                if not parts: continue
                name = parts[0].strip(":")
                if name == "lo": continue
                rx = int(parts[1])
                tx = int(parts[9])
                total_rx += rx
                total_tx += tx
    except:
        pass

    new_cache["net_rx"] = total_rx
    new_cache["net_tx"] = total_tx

    network_interfaces.append({
        "name": "total",
        "rx": total_rx,
        "tx": total_tx
    })

    # --- Disk ---
    disk_data = []
    total_read_sectors = 0
    total_write_sectors = 0
    try:
        with open("/proc/diskstats") as f:
            for line in f:
                parts = line.split()
                if not parts: continue
                name = parts[2]
                if not (name.startswith("sd") or name.startswith("nvme") or name.startswith("vd")) or (name[-1].isdigit() and not name.startswith("nvme")):
                    continue
                if name.startswith("nvme") and "p" in name:
                    continue
                read_sectors = int(parts[5])
                write_sectors = int(parts[9])
                total_read_sectors += read_sectors
                total_write_sectors += write_sectors
    except:
        pass

    new_cache["disk_read"] = total_read_sectors
    new_cache["disk_write"] = total_write_sectors

    disk_data.append({
        "name": "total",
        "read": total_read_sectors,
        "write": total_write_sectors
    })

    # --- System ---
    loadavg = ""
    processes_count = 0
    threads_count = 0
    boottime = ""
    try:
        with open("/proc/loadavg") as f:
            loadavg = f.read().split()[0]
    except:
        pass
    try:
        pids = [x for x in os.listdir("/proc") if x.isdigit()]
        processes_count = len(pids)
        with open("/proc/stat") as f:
            for line in f:
                if line.startswith("btime"):
                    btime = int(line.split()[1])
                    boottime = time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(btime))
    except:
        pass

    # --- Disk Mounts ---
    mounts = []
    try:
        import subprocess
        out = subprocess.check_output(["df", "-B1"]).decode("utf-8")
        lines = out.strip().split("\n")
        for line in lines[1:]:
            parts = line.split()
            if len(parts) >= 6:
                mount = parts[5]
                total = int(parts[1])
                used = int(parts[2])
                percent = parts[4]
                mounts.append({
                    "mount": mount,
                    "mountpoint": mount,
                    "percent_used": float(percent.strip("%")),
                    "total_bytes": total,
                    "used_bytes": used
                })
    except:
        pass

    # --- GPU ---
    gpus = get_gpu()

    # --- Processes ---
    processes = []
    include_proc = len(sys.argv) > 1 and "processes" in sys.argv[1]
    if include_proc:
        processes = get_processes(cache, new_cache, time_diff)

    save_cache(new_cache)

    data = {
        "cpu": cpu_data,
        "memory": {
            "usedPercent": mem_used_percent,
            "total": mem_total,
            "used": mem_used,
            "available": mem_available,
            "free": mem_free,
            "cached": mem_cached,
            "buffers": mem_buffers,
            "swaptotal": swap_total,
            "swapfree": swap_free
        },
        "network": network_interfaces,
        "disk": disk_data,
        "system": {"loadavg": loadavg, "processes": processes_count, "threads": threads_count, "boottime": boottime},
        "diskmounts": mounts,
        "gpu": {"gpus": gpus}
    }
    if include_proc:
        data["processes"] = processes

    print(json.dumps(data))

if __name__ == "__main__":
    main()
