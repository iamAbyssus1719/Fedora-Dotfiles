#!/bin/bash
# Alterna la opacidad de las ventanas (Hyprland 0.55+ / Lua)
# El estado se guarda en un archivo porque ya no se lee con "hyprctl getoption".

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr_opacity_reduced"

if [ -f "$STATE_FILE" ]; then
    # Estaba reducida -> volver a normal
    hyprctl eval 'hl.config({ decoration = { active_opacity = 1.0, inactive_opacity = 1.0 } })'
    rm -f "$STATE_FILE"
else
    hyprctl eval 'hl.config({ decoration = { active_opacity = 0.95, inactive_opacity = 0.80 } })'
    touch "$STATE_FILE"
fi