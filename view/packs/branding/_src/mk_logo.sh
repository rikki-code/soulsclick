#!/bin/sh
B=/Users/vladimirafanasev/dev/ggames/soulsclicker/view/packs/branding
cd $B/_src
python3 - <<'PY'
import logo
for l in ('en','ru'):
    open('../logo_%s.svg'%l,'w').write(logo.logo_svg(l))
    open('../_previews/logo_%s_dark.svg'%l,'w').write('<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="500"><rect width="1600" height="500" fill="#141922"/>%s</svg>'%logo.logo_group(l))
PY
for l in en ru; do ./render.sh $B/logo_$l.svg $B/logo_$l.png; ./render.sh $B/_previews/logo_${l}_dark.svg $B/_previews/logo_${l}_dark.png; done
