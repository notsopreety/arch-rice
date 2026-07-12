-- Look and feel settings (General, Decoration, Animations)
-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

local ok, colors = pcall(require, "colors")
if not ok then
    colors = {
        primary = "0xff33ccff",
        secondary = "0xff00ff99",
        background = "0xff111111",
        outline = "0xff595959",
    }
end

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = {colors.primary, colors.tertiary, colors.primary_container, colors.secondary}, angle = 45 },
            inactive_border = colors.outline,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = (function()
            local f = io.open(os.getenv("HOME") .. "/.config/hypr/.niri_tiling_enabled", "r")
            if f then
                f:close()
                return "scrolling"
            else
                return "dwindle"
            end
        end)(),
    },

    decoration = (function()
        local is_glass = false
        local f = io.open(os.getenv("HOME") .. "/.config/hypr/.glassmorphism_enabled", "r")
        if f then
            is_glass = true
            f:close()
        end

        return {
            rounding       = 10,
            rounding_power = 2,

            -- Change transparency of focused and unfocused windows for glassmorphism
            active_opacity   = is_glass and 0.75 or 1.0,
            inactive_opacity = is_glass and 0.65 or 1.0,

            shadow = {
                enabled      = true,
                range        = 4,
                render_power = 3,
                color        = 0xee1a1a1a,
            },

            blur = {
                enabled   = true,
                size      = is_glass and 12 or 3,
                passes    = is_glass and 4 or 1,
                vibrancy  = 0.1696,
                ignore_opacity = is_glass,
            },
        }
    end)(),

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

local is_borderangle = (function()
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/.borderangle_enabled", "r")
    if f then
        f:close()
        return true
    end
    return false
end)()

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "borderangle",   enabled = is_borderangle,  speed = 30,  bezier = "linear",       style = "loop" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.5,
        direction = "right",
        focus_fit_method = 1,
        follow_focus = true,
        follow_min_visible = 0.3,
        wrap_focus = true,
        wrap_swapcol = true,
        explicit_column_widths = "0.5, 0.667, 1.0",
    },
})

----------------
--  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})
