#!/usr/bin/env bash
# ~/bin/screens — arrange displays depending on what's plugged in
LAPTOP="DP-4"
EXT1="HDMI-0"         # left external
EXT2="DP-5"           # right external

if xrandr --query | grep -q "^$EXT1 connected"; then
    xrandr \
      --output "$EXT1"   --mode 1920x1080 --pos -1920x0    \
      --output "$EXT2"   --mode 1920x1080 --pos 1920x0 \
      --output "$LAPTOP" --mode 1920x1080 --pos 0x0 --primary
else
    xrandr --output "$LAPTOP" --auto --primary \
           --output "$EXT1" --off --output "$EXT2" --off
fi
