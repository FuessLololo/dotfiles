#!/usr/bin/env bash
# Arrange displays depending on what's plugged in (KDE Plasma / Wayland: kscreen-doctor).
# X11/xrandr version: screen-layout.bash.x11-bak
set -euo pipefail
LAPTOP="eDP-1"
EXT1="HDMI-A-1"   # left external
EXT2="DP-3"       # right external (4K)

connected() {
    kscreen-doctor -j | jq -e --arg n "$1" '.outputs[] | select(.name == $n and .connected)' >/dev/null
}

if connected "$EXT1"; then
    args=(
        "output.$EXT1.enable"   "output.$EXT1.mode.1920x1080@60"   "output.$EXT1.scale.1"   "output.$EXT1.position.0,0"
        "output.$LAPTOP.enable" "output.$LAPTOP.mode.1920x1080@60" "output.$LAPTOP.scale.1" "output.$LAPTOP.position.1920,0"
        "output.$LAPTOP.priority.1"
    )
    if connected "$EXT2"; then
        # Native 4K at 2.0 -> 2259x1271 logical, placed right of the laptop.
        args+=("output.$EXT2.enable" "output.$EXT2.mode.3840x2160@60" "output.$EXT2.scale.2.0" "output.$EXT2.position.3840,0")
    fi
else
    args=("output.$LAPTOP.enable" "output.$LAPTOP.position.0,0" "output.$LAPTOP.priority.1")
    for o in "$EXT1" "$EXT2"; do
        connected "$o" && args+=("output.$o.disable")
    done
fi

kscreen-doctor "${args[@]}"
