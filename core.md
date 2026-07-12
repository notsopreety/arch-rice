# Packages & Dependencies

## Window Manager & Compositor

| Package | Commands | Used In |
|---------|----------|---------|
| `hyprland` | `hyprctl`, `hypridle`, `hyprshutdown` | hypr/, scripts/, quickshell/ |
| `hyprpicker` | `hyprpicker -a` | quickshell/services/ |
| `hyprsunset` | `hyprsunset -t` | quickshell/services/ |

## Desktop Shell

| Package | Commands | Used In |
|---------|----------|---------|
| `quickshell` (AUR) | `quickshell ipc call ...` | hypr/, quickshell/ |

## System / Base

| Package | Commands | Used In |
|---------|----------|---------|
| `systemd` | `loginctl`, `systemctl`, `systemd-inhibit`, `timedatectl`, `udevadm` | hypr/, quickshell/ |
| `polkit` | `pkexec` | quickshell/ |
| `sudo` | `sudo` | quickshell/scripts/ |
| `util-linux` | `lsblk`, `umount`, `rfkill`, `lscpu` | quickshell/ |
| `coreutils` | `mkdir`, `cp`, `rm`, `mv`, `cat`, `ls`, `touch`, `sleep`, `numfmt`, `stdbuf`, `tee`, `paste`, `df`, `head`, `tail`, `date`, `sort` | scripts/, quickshell/ |
| `procps-ng` | `ps`, `free`, `top`, `uptime`, `kill`, `pgrep`, `pkill` | quickshell/ |
| `findutils` | `find` | scripts/, quickshell/ |
| `gawk` | `awk` | quickshell/ |
| `grep` | `grep` | quickshell/ |
| `sed` | `sed` | quickshell/ |
| `which` | `which` | quickshell/services/ |
| `psmisc` | `killall` | matugen/ |

## Shell & Terminal

| Package | Commands | Used In |
|---------|----------|---------|
| `kitty` | `kitty` | hypr/, quickshell/ |
| `fish` | `fish` | kitty/ |
| `bash` | `bash` | scripts/, quickshell/ |
| `gtk3` | `gtk-launch` | quickshell/widgets/ |

## Display & Graphics

| Package | Commands | Used In |
|---------|----------|---------|
| `awww` (AUR) | `awww-daemon`, `awww img` | scripts/, hypr/ |
| `matugen` (AUR) | `matugen image` | matugen/, scripts/, hypr/ |
| `imagemagick` | `magick` | quickshell/core/, quickshell/widgets/ |
| `grim` | `grim` | quickshell/services/, quickshell/widgets/ |
| `slurp` | `slurp` | quickshell/services/ |
| `wf-recorder` (AUR) | `wf-recorder` | quickshell/services/ |
| `brightnessctl` | `brightnessctl` | hypr/, quickshell/ |
| `jq` | `jq` | quickshell/ |

## Audio

| Package | Commands | Used In |
|---------|----------|---------|
| `wireplumber` | `wpctl` | hypr/, quickshell/ |
| `pipewire-pulse` | `paplay`, `pw-play`, `pactl` | scripts/, quickshell/ |
| `playerctl` | `playerctl` | hypr/, quickshell/ |
| `mpv` | `mpv` | quickshell/services/ |
| `pavucontrol` or `pipewire` | `pactl` | quickshell/services/ |
| `cava` | `cava` | cava/, quickshell/services/ |

## Network

| Package | Commands | Used In |
|---------|----------|---------|
| `networkmanager` | `nmcli` | quickshell/ |
| `bluez` / `bluez-utils` | `bluetoothctl` | quickshell/ |
| `blueman` | `blueman-manager` | quickshell/widgets/ |
| `curl` | `curl` | quickshell/services/ |

## Desktop & Applications

| Package | Commands | Used In |
|---------|----------|---------|
| `dolphin` | `dolphin` | hypr/ |
| `rofi` | `rofi -show drun` | hypr/ |
| `cliphist` | `cliphist` | hypr/, quickshell/ |
| `wl-clipboard` | `wl-paste`, `wl-copy` | hypr/, quickshell/ |
| `xdg-utils` | `xdg-open` | quickshell/ |
| `libnotify` | `notify-send` | scripts/, quickshell/ |

## Multimedia

| Package | Commands | Used In |
|---------|----------|---------|
| `ffmpeg` | `ffmpeg` | quickshell/widgets/, quickshell/assets/ |
| `qrencode` | `qrencode` | quickshell/scripts/ |
| `pciutils` | `lspci` | quickshell/scripts/ |

## Development & Scripting

| Package | Commands | Used In |
|---------|----------|---------|
| `python` | `python3` | quickshell/ |
| `python-gobject` (PyGObject) | `gi.repository` | quickshell/scripts/ |
| `glib2` | `Gio` | quickshell/scripts/ |

## Package Management

| Package | Commands | Used In |
|---------|----------|---------|
| `pacman` | `pacman` | quickshell/scripts/ |
| `pacman-contrib` | `checkupdates` | quickshell/scripts/ |
| `yay` (AUR) | `yay` | quickshell/scripts/ |
| `paru` (AUR) | `paru` | quickshell/scripts/ |
| `flatpak` | `flatpak` | quickshell/scripts/ |
| `snapd` | `snap` | quickshell/scripts/ |

## Power & Hardware

| Package | Commands | Used In |
|---------|----------|---------|
| `upower` | `upower` | scripts/, hypr/, quickshell/ |
| `power-profiles-daemon` | `powerprofilesctl` | quickshell/services/ |

## Storage

| Package | Commands | Used In |
|---------|----------|---------|
| `udisks2` | `udisksctl` | quickshell/scripts/ |

## Optional / Used Conditionally

| Package | Commands | Used In |
|---------|----------|---------|
| `nvidia-utils` | `nvidia-smi` | quickshell/services/, quickshell/scripts/ |
| `radeontop` (AUR) | `radeontop` | quickshell/services/ |
| `tesseract` | `tesseract` | quickshell/services/ |
| `xdg-desktop-portal-hyprland` | — | hypr/lua.d/permissions.lua (commented) |
| `hyprlock` | `hyprlock` | Config option `useHyprlock` (disabled) |
| `satty` (AUR) | `satty` | Config option `useSatty` (disabled) |
| `hyprland-idle-inhibitor` | — | quickshell/services/ (optional check) |
| `wayland-idle-inhibitor` | — | quickshell/services/ (optional check) |
| `plasma-browser-integration` | `plasma-browser-integration-host` | quickshell/services/ (optional check) |
