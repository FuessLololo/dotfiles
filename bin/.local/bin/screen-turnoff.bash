#!/usr/bin/env bash
# Turn all monitors off now (Plasma Wayland). Any key or mouse move wakes them.
# X11 version was: xset dpms force off
exec kscreen-doctor --dpms off
