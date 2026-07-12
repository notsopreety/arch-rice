-- Main Hyprland Lua Configuration Entry File
-- Refer to the Hyprland wiki for details: https://wiki.hypr.land/

-- Add our configuration directory to Lua's search path
local config_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = package.path .. ";" .. config_dir .. "/lua.d/?.lua"

-- Require our configuration modules
require("programs")
require("monitors")
require("autostart")
require("env")
require("permissions")
require("look_and_feel")
require("input")
require("keybinds")
require("rules")
