#!/bin/bash
# Alterna la ventana activa entre flotante y mosaico (Hyprland 0.55+ / Lua)

INFO=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$INFO" | jq -r '.floating')
WINDOW_CLASS=$(echo "$INFO" | jq -r '.class')

# Alternar flotante/mosaico
hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'

# Si estaba en mosaico, ahora es flotante: ajustar tamaño y centrar
if [ "$IS_FLOATING" = "false" ]; then
    sleep 0.05

    case $WINDOW_CLASS in
        "cava")    W=900;  H=100 ;;
        "wezterm") W=550;  H=300 ;;
        "Thunar")  W=1000; H=650 ;;
        *)         W=800;  H=500 ;;
    esac

    hyprctl dispatch "hl.dsp.window.resize({ x = $W, y = $H, relative = false })"
    hyprctl dispatch 'hl.dsp.window.center()'
fi