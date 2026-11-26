-- Hyprland 0.57+ config. Hyprland 0.57 dropped the hyprlang format, so this
-- file replaces hyprland.conf. Wiki: https://wiki.hypr.land/configuring/

require("colors") -- border colours, written by scripts/update_colors.py

local hypr = os.getenv("HOME") .. "/.config/hypr"
local scripts = hypr .. "/scripts"

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- setup_monitors.py runs on every config load, like the old `exec` keyword.
hl.exec_cmd("python3 " .. scripts .. "/setup_monitors.py")

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "thunar"
local menu        = "rofi -show drun -modi drun,run -show-icons"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm finalize")
    -- Dark scheme for GTK, libadwaita, Firefox and Electron popups.
    hl.exec_cmd(scripts .. "/apply_dark_theme.sh")
    hl.exec_cmd("nm-applet")
    -- Quickshell draws the bar and owns notifications. It follows monitor changes itself.
    hl.exec_cmd("qs")
    hl.exec_cmd("hypridle & hyprlock &")
    hl.exec_cmd(scripts .. "/wallpaper.sh")
    hl.exec_cmd(scripts .. "/startup_apps.sh")
    hl.exec_cmd("sleep 30 && python3 " .. scripts .. "/sync_workspaces.py 1")
    -- Solaar applies the Logitech mouse settings and runs the button rules.
    hl.exec_cmd("solaar --window=hide")
    -- Kando is the pie menu. This is the upstream build with its own Electron.
    -- The kando-bin package uses the system Electron, which needs a newer glibc.
    -- The Wayland hint applies to Kando only, so other Electron apps keep their behaviour.
    hl.exec_cmd("env ELECTRON_OZONE_PLATFORM_HINT=auto ~/.local/opt/kando-2.3.1/Kando-linux-x64/kando")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "12")
hl.env("HYPRCURSOR_SIZE", "10")

-- The VA-API driver depends on the GPU, and these dots run on two machines.
-- Kiwork-Arch has only an NVIDIA RTX 4060. The Intel machine has no NVIDIA
-- GPU, and there the nvidia values sent libva to a driver that did not load,
-- so video decode fell back to the CPU. The NVIDIA kernel driver creates
-- /proc/driver/nvidia/version, so the file picks the right set.
local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

if file_exists("/proc/driver/nvidia/version") then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
else
    hl.env("LIBVA_DRIVER_NAME", "iHD")
end
hl.env("GSK_RENDERER", "ngl")
-- Qt apps take their palette from GTK3, so they get the Chrysaki gtk.css colors.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 5,
        border_size = 2,
        -- Border colours come from colors.lua.
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 2,
        active_opacity   = 0.9,
        inactive_opacity = 0.85,

        shadow = {
            enabled        = true,
            range          = 20,
            render_power   = 3,
            color          = "rgba(00000055)",
            color_inactive = "rgba(00000033)",
            offset         = { 0, 2 },
            scale          = 1.0,
        },

        blur = {
            enabled            = true,
            size               = 8,
            passes             = 3,
            ignore_opacity     = true,
            new_optimizations  = true,
            xray               = false,
            noise              = 0.02,
            contrast           = 1.0,
            brightness         = 1.0,
            vibrancy           = 0.3,
            vibrancy_darkness  = 0.2,
            popups             = true,
            popups_ignorealpha = 0.2,
        },

        dim_inactive = true,
        dim_strength = 0.10,
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = true },
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

---------------
---- INPUT ----
---------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-- MX Master 4 through the Logi Bolt receiver. Solaar sets the DPI.
hl.device({ name = "logitech-usb-receiver-mouse", sensitivity = 0, accel_profile = "flat" })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

local function key(combo)
    return mainMod .. " + " .. combo
end

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

local function spawn(app)
    return exec("python3 " .. scripts .. "/smart_spawn.py " .. app)
end

hl.bind(key("Return"),      spawn(terminal))
hl.bind(key("W"),           hl.dsp.window.close())
hl.bind(key("M"),           exec("~/dots/rofi/scripts/powermenu.sh"))
hl.bind(key("F"),           exec(fileManager))
hl.bind(key("V"),           hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("space"),       exec(menu))
hl.bind(key("P"),           hl.dsp.window.pseudo())
hl.bind(key("J"),           hl.dsp.layout("togglesplit"))
hl.bind(key("B"),           spawn("firefox"))
hl.bind(key("SHIFT + B"),   exec("~/dots/rofi/scripts/firefox_profiles.sh --rofi"))
hl.bind(key("C"),           spawn("code"))
hl.bind(key("O"),           exec("code ~/dev/obKidian"))
hl.bind(key("L"),           exec(scripts .. "/lock.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(key("left"),  hl.dsp.focus({ direction = "left" }))
hl.bind(key("right"), hl.dsp.focus({ direction = "right" }))
hl.bind(key("up"),    hl.dsp.focus({ direction = "up" }))
hl.bind(key("down"),  hl.dsp.focus({ direction = "down" }))

-- mainMod + [0-9] switches the workspace group on every monitor.
-- mainMod + SHIFT + [0-9] moves the active window to a workspace.
for i = 1, 10 do
    local k = tostring(i % 10)
    hl.bind(key(k),             exec("python3 " .. scripts .. "/sync_workspaces.py " .. i))
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i, follow = true }))
end

-- Move window to next/prev monitor group (workspace +/- 10)
hl.bind(key("SHIFT + Right"), exec("python3 " .. scripts .. "/move_window.py right"))
hl.bind(key("SHIFT + Left"),  exec("python3 " .. scripts .. "/move_window.py left"))

-- Scratchpad
hl.bind(key("SHIFT + Up"),   hl.dsp.window.move({ workspace = "special:scratchpad", follow = true }))
hl.bind(key("SHIFT + Down"), exec("python3 " .. scripts .. "/move_window.py scratchpad_out"))
hl.bind(key("S"),            hl.dsp.workspace.toggle_special("scratchpad"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Screenshots
hl.bind("Print",                exec("hyprshot -m output -o ~/pictures/screenshots"))
hl.bind("CTRL + Print",         exec("hyprshot -m output --clipboard-only"))
hl.bind(key("E"),               exec("hyprshot -m window -m active --clipboard-only"))
hl.bind(key("SHIFT + S"),       exec("hyprshot -m region --clipboard-only"))
hl.bind(key("CTRL + SHIFT + S"), exec("hyprshot -m region -o ~/pictures/screenshots"))

-- Screen annotation (gromit-mpx). SUPER+A enters the "annotate" submap, which
-- scopes Ctrl+Z, Ctrl+Y and Delete to drawing. Outside the submap those keys
-- stay untouched.
local annotate = scripts .. "/annotate.sh"
hl.bind(key("A"), exec(annotate))

hl.define_submap("annotate", function()
    hl.bind("CTRL + Z",         exec("gromit-mpx --undo"))
    hl.bind("CTRL + Y",         exec("gromit-mpx --redo"))
    hl.bind("CTRL + SHIFT + Z", exec("gromit-mpx --redo"))
    hl.bind("Delete",           exec("gromit-mpx --clear"))
    hl.bind("CTRL + H",         exec("gromit-mpx --visibility"))
    -- SUPER+A toggles back off. It clears strokes and keeps the daemon warm.
    -- Escape is the force close: it wipes strokes and kills the daemon.
    hl.bind(key("A"),           exec(annotate))
    hl.bind("Escape",           exec(annotate .. " quit"))
end)

-- Volume and brightness keys (old bindel: locked and repeating)
local lr = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), lr)
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), lr)
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), lr)
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), lr)
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl s 10%+"), lr)
hl.bind("XF86MonBrightnessDown", exec("brightnessctl s 10%-"), lr)
hl.bind(key("F7"),               exec("brightnessctl s 10%-"), lr)
hl.bind(key("F8"),               exec("brightnessctl s 10%+"), lr)

-- Media keys (old bindl: locked). Requires playerctl.
local l = { locked = true }
hl.bind("XF86AudioNext",  exec("playerctl next"), l)
hl.bind("XF86AudioPause", exec("playerctl play-pause"), l)
hl.bind("XF86AudioPlay",  exec("playerctl play-pause"), l)
hl.bind("XF86AudioPrev",  exec("playerctl previous"), l)

hl.bind(key("Delete"),    exec("playerctl previous"))
hl.bind(key("Page_Down"), exec("playerctl next"))
hl.bind(key("Page_Up"),   exec("playerctl play-pause"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Ignore maximize requests from apps.
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name = "pavucontrol-float",
    match = { class = "(pavucontrol|org.pulseaudio.pavucontrol)" },
    float = true,
    size = { 600, 400 },
    center = true,
    opacity = "0.9 0.9",
    animation = "popin",
})

-- WhatsApp: the snap wrapper breaks PID tracking, so a window rule places it.
hl.window_rule({
    name = "whatsapp-ws",
    match = { class = "^(whatsapp-desktop-client)$" },
    workspace = "10 silent",
})

-- Gromit-MPX annotation overlay. The rule matches on title as well as class,
-- because gromit dialogs share the class and must stay clickable. no_focus is
-- not set: the XWayland overlay needs pointer events to draw.
hl.window_rule({
    name = "gromit-annotation-overlay",
    match = { class = "^([Gg]romit-mpx)$", title = "^(gromit-mpx)$" },
    no_blur = true,
    no_anim = true,
    float = true,
    pin = true,
    opacity = "1.0 override",
})

hl.window_rule({
    name = "firefox-opacity",
    match = { class = "^(firefox)$" },
    opacity = "1.0 override",
})

-- Ghostty stays fully opaque. Forced transparency with global blur bled the
-- blurred backdrop through glyph edges and softened all text.
hl.window_rule({
    name = "ghostty-opacity",
    match = { class = "^(com\\.mitchellh\\.ghostty)$" },
    opacity = "1.0 override 1.0 override",
})

-- Thunar and the GTK file dialog stay fully opaque, so file names stay
-- readable over a busy wallpaper.
hl.window_rule({
    name = "files-opacity",
    match = { class = "^(thunar|xdg-desktop-portal-gtk)$" },
    opacity = "1.0 override 1.0 override",
})

-- OrKi: dim_inactive made the pixel-art scene darken and brighten with focus.
hl.window_rule({
    name = "orki-no-dim",
    match = { class = "^(OrKi)$" },
    no_dim = true,
})

-- usaKi bubble. It must stay above fullscreen windows, so it is pinned from
-- the moment it maps. The app sets its own size and position.
hl.window_rule({
    name = "usaki-bubble",
    match = { class = "^usaki$" },
    float = true,
    pin = true,
    no_initial_focus = true,
    border_size = 0,
    no_shadow = true,
    rounding = 0,
    no_blur = true,
    no_dim = true,
    no_anim = true,
    opacity = "1.0 override 1.0 override 1.0 override",
})

-- Kando pie menu: one transparent full-screen window.
-- Rule source: https://kando.menu/installation-on-linux/
hl.window_rule({
    name = "kando",
    match = { class = "menu.kando.Kando", title = "Kando Menu" },
    no_blur = true,
    opaque = true,
    move = { 0, 0 },
    rounding = 0,
    size = { "monitor_w", "monitor_h" },
    border_size = 0,
    no_anim = true,
    float = true,
    pin = true,
})

-- File picker (the GTK portal dialog)
hl.window_rule({
    name = "filepicker-float",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
    size = { "monitor_w * 0.6", "monitor_h * 0.7" },
    center = true,
    animation = "popin",
})

-- Blur behind the Quickshell bar, its panes and rofi.
for _, ns in ipairs({
    "qs-bar",
    "qs-pane",
    "qs-toast",
    "qs-notify-list",
    "rofi",
}) do
    hl.layer_rule({
        name = ns .. "-blur",
        match = { namespace = ns },
        blur = true,
        ignore_alpha = 0,
    })
end
