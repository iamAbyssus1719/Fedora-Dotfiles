local bg = "#1d2021"         -- Gruvbox bg0_dark
local fg = "#ebdbb2"         -- Gruvbox fg

local dark_gray = "#282828"  -- Gruvbox bg
local light_gray = "#a89984" -- Gruvbox fg4

return {
    background = bg,
    foreground = fg,
    cursor_bg = "#928374",    -- Gruvbox gray
    cursor_fg = bg,
    cursor_border = "#928374",
    selection_fg = bg,
    selection_bg = fg,
    scrollbar_thumb = fg,
    split = dark_gray,
    
    -- Colores Normales (ANSI)
    ansi = {
        "#282828", -- black (bg)
        "#cc241d", -- red
        "#98971a", -- green
        "#d79921", -- yellow
        "#458588", -- blue
        "#b16286", -- magenta
        "#689d6a", -- cyan
        "#a89984", -- white (fg4)
    },
    
    -- Colores Brillantes (Brights)
    brights = {
        "#928374", -- bright black (gray)
        "#fb4934", -- bright red
        "#b8bb26", -- bright green
        "#fabd2f", -- bright yellow
        "#83a598", -- bright blue
        "#d3869b", -- bright magenta
        "#8ec07c", -- bright cyan
        "#ebdbb2", -- bright white (fg)
    },
}