-- Window and workspace rules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for more

-- "Smart gaps" / "No gaps when only"
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Disable Hyprland layer spring animation on the bar window to prevent popup resize wobble
hl.layer_rule({
    name  = "no-anim-hyprbar",
    match = { namespace = "^qs-hyprbar$" },
    no_anim = true,
})

-- Enable blur on the quickshell power menu / app launcher overlay only when NOT in glassmorphism mode
-- (shared namespace "quickshell-powermenu" covers both PowerMenuWindow and LauncherWindow)
-- In glassmorphism mode, global blur passes = 4 already makes the overlay too opaque.
hl.layer_rule({
    name  = "blur-powermenu",
    match = { namespace = "^quickshell-powermenu$" },
    blur  = not is_glass,
})

-- Enable blur on the quickshell wallpaper selector overlay when NOT in glassmorphism mode
-- (since glassmorphism mode increases global blur passes to 4, making it too opaque)
local is_glass = false
local f = io.open(os.getenv("HOME") .. "/.config/hypr/.glassmorphism_enabled", "r")
if f then
    is_glass = true
    f:close()
end

hl.layer_rule({
    name  = "blur-wallpaper",
    match = { namespace = "^quickshell-wallpaper$" },
    blur  = not is_glass,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Make notepad always open on float
hl.window_rule({
    name  = "float-notepad",
    match = { title = "Notepad" },

    float = true,
})

-- Make calculator always open on float
hl.window_rule({
    name  = "float-calculator",
    match = { title = "Calculator" },

    float = true,
})

-- Make system monitor always open on float
hl.window_rule({
    name  = "float-systemmonitor",
    match = { title = "System Monitor" },

    float = true,
})


