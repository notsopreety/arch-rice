-- Keybindings configuration
-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more

local programs = require("programs")
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(programs.terminal))
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + F", function()
    local w = hl.get_active_window()
    local m = hl.get_active_monitor()
    if not w or not m then return end
    
    local scaled_width = m.width / m.scale
    local fraction = w.size.x / scaled_width
    
    if fraction > 0.85 then
        -- Currently maximized, resize to 0.5 (half width)
        hl.dispatch(hl.dsp.layout("colresize 0.5"))
    else
        -- Not maximized, resize to 1.0 (full width)
        hl.dispatch(hl.dsp.layout("colresize 1.0"))
    end
end)
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))

local function file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f) return true else return false end
end
local is_horizontal_ws = file_exists(os.getenv("HOME") .. "/.config/hypr/.workspace_horizontal_enabled")
local is_niri_enabled = file_exists(os.getenv("HOME") .. "/.config/hypr/.niri_tiling_enabled")

local function bind_focus(dir)
    return is_niri_enabled and hl.dsp.layout("focus " .. dir) or hl.dsp.exec_cmd("hyprctl dispatch movefocus " .. dir)
end

local function bind_swap(dir)
    if is_niri_enabled then
        if dir == "l" or dir == "r" then
            return hl.dsp.layout("swapcol " .. dir)
        else
            return hl.dsp.layout("swapwindow " .. dir)
        end
    else
        return hl.dsp.exec_cmd("hyprctl dispatch movewindow " .. dir)
    end
end

if is_horizontal_ws then
    -- Horizontal Workspaces, Vertical Windows
    hl.bind(mainMod .. " + up",   bind_focus("u"))
    hl.bind(mainMod .. " + down", bind_focus("d"))
    hl.bind(mainMod .. " + SHIFT + up",   bind_swap("u"))
    hl.bind(mainMod .. " + SHIFT + down", bind_swap("d"))

    hl.bind(mainMod .. " + left",    hl.dsp.focus({ workspace = "-1" }))
    hl.bind(mainMod .. " + right",   hl.dsp.focus({ workspace = "+1" }))
    hl.bind(mainMod .. " + SHIFT + left",    hl.dsp.window.move({ workspace = "-1" }))
    hl.bind(mainMod .. " + SHIFT + right",   hl.dsp.window.move({ workspace = "+1" }))
    
    if not is_niri_enabled then
        hl.bind(mainMod .. " + Page_Up",    bind_focus("u"))
        hl.bind(mainMod .. " + Page_Down",  bind_focus("d"))
        hl.bind(mainMod .. " + SHIFT + Page_Up",    bind_swap("u"))
        hl.bind(mainMod .. " + SHIFT + Page_Down",  bind_swap("d"))
        
        hl.bind(mainMod .. " + Home",    hl.dsp.focus({ workspace = "-1" }))
        hl.bind(mainMod .. " + End",     hl.dsp.focus({ workspace = "+1" }))
        hl.bind(mainMod .. " + SHIFT + Home",    hl.dsp.window.move({ workspace = "-1" }))
        hl.bind(mainMod .. " + SHIFT + End",     hl.dsp.window.move({ workspace = "+1" }))
    end
else
    -- Vertical Workspaces, Horizontal Windows
    hl.bind(mainMod .. " + left",  bind_focus("l"))
    hl.bind(mainMod .. " + right", bind_focus("r"))
    hl.bind(mainMod .. " + SHIFT + left",  bind_swap("l"))
    hl.bind(mainMod .. " + SHIFT + right", bind_swap("r"))

    hl.bind(mainMod .. " + up",    hl.dsp.focus({ workspace = "-1" }))
    hl.bind(mainMod .. " + down",  hl.dsp.focus({ workspace = "+1" }))
    hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ workspace = "-1" }))
    hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ workspace = "+1" }))
    
    if not is_niri_enabled then
        hl.bind(mainMod .. " + Home",  bind_focus("l"))
        hl.bind(mainMod .. " + End",   bind_focus("r"))
        hl.bind(mainMod .. " + SHIFT + Home",  bind_swap("l"))
        hl.bind(mainMod .. " + SHIFT + End",   bind_swap("r"))
        
        hl.bind(mainMod .. " + Page_Up",    hl.dsp.focus({ workspace = "-1" }))
        hl.bind(mainMod .. " + Page_Down",  hl.dsp.focus({ workspace = "+1" }))
        hl.bind(mainMod .. " + SHIFT + Page_Up",    hl.dsp.window.move({ workspace = "-1" }))
        hl.bind(mainMod .. " + SHIFT + Page_Down",  hl.dsp.window.move({ workspace = "+1" }))
    end
end

-- Niri-style Column Resizing
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -conf"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
-- hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scrolle
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Touchpad Gestures
-- 3-Finger swipe Left/Right: navigate columns (Niri-style)
hl.gesture({
    fingers = 3,
    direction = "left",
    action = function()
        hl.dispatch(hl.dsp.layout("focus r"))
    end
})
hl.gesture({
    fingers = 3,
    direction = "right",
    action = function()
        hl.dispatch(hl.dsp.layout("focus l"))
    end
})

-- 3-Finger Pinch to toggle window expansion (Niri maximize column)
hl.gesture({
    fingers = 3,
    direction = "pinchout",
    action = "fullscreen"
})
hl.gesture({
    fingers = 3,
    direction = "pinchin",
    action = "fullscreen"
})

-- 4-Finger swipe up to open Quickshell workspace overview
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.exec_cmd("quickshell ipc call quickshell run workspace"))
    end
})

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Lock screen keybind
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("quickshell ipc call quickshell run lock"))

-- Power menu (toggleable)
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("quickshell ipc call quickshell run powermenu"))


hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("quickshell ipc call quickshell run workspace"))

-- Material Launcher (SUPER + Space)
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc call quickshell run launcher"))
-- hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("quickshell ipc call quickshell run launcher"))

hl.bind("Print", hl.dsp.exec_cmd("quickshell ipc call quickshell run sniptool"))
hl.bind("SHIFT" .. " + Print", hl.dsp.exec_cmd("quickshell ipc call quickshell run screenshot"))
hl.bind("CONTROL" .. " + SHIFT" .. " + Print", hl.dsp.exec_cmd("quickshell ipc call quickshell run glens"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("quickshell ipc call quickshell run screenrecorder"))

hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("quickshell ipc call quickshell run clipboard"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("quickshell ipc call quickshell run emojiboard"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("quickshell ipc call quickshell run keybinds"))

hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("quickshell ipc call quickshell run settings"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("quickshell ipc call quickshell run controlcenter"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("quickshell ipc call quickshell run notification"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("quickshell ipc call quickshell run performance"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("quickshell ipc call quickshell run systemmonitor"))

-- Quickshell Wallpaper Picker (toggleable)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("quickshell ipc call quickshell run wallpaper"))
hl.bind(mainMod .. " + SHIFT+ W", hl.dsp.exec_cmd("quickshell ipc call quickshell run wallpapers"))

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("quickshell ipc call quickshell run sidebar"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("quickshell ipc call quickshell run notepad"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("quickshell ipc call quickshell run overview"))