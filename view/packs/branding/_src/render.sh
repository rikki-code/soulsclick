#!/bin/sh
# usage: render.sh in.svg out.png [scale]
cd /Users/vladimirafanasev/dev/ggames/soulsclicker
/Users/vladimirafanasev/dev/godot/bin/godot.macos.editor.arm64 --headless --path . -s tools/svg_to_png.gd -- "$@" 2>&1 | grep -i "error" 
