-- Autostart processes
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
local programs = require("programs")

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function ()
  hl.exec_cmd(os.getenv("HOME") .. "/.config/scripts/wall.sh")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("quickshell -p ~/.config/quickshell")
  hl.exec_cmd("~/.config/scripts/battery-daemon.sh")
end)
