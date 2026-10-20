import importlib.util, json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
B = os.path.dirname(HERE)
ROOT = os.path.normpath(os.path.join(B, "..", "..", ".."))
PK = os.path.join(ROOT, "view", "packs")
sys.path.insert(0, HERE)
import logo as L


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m

RP = load("rig_preview", os.path.join(ROOT, "tools", "rig_preview.py"))
PB = load("player_build", os.path.join(PK, "player_pack", "silhouette_pack", "_src", "build.py"))
PLAYER = os.path.join(PK, "player_pack", "silhouette_pack")
PB.PACK = PLAYER


def uniq(markup, prefix):
    markup = re.sub(r'id="([^"]+)"', lambda g: 'id="%s%s"' % (prefix, g.group(1)), markup)
    return re.sub(r"url\(#([^)]+)\)", lambda g: "url(#%s%s)" % (prefix, g.group(1)), markup)


def bg(name, prefix):
    return RP.read_svg_inner(os.path.join(PK, "background_pack", "silhouette_pack", name + ".svg"), prefix)


def enemy(name, pose, prefix):
    rig = RP.load_rig(os.path.join(PK, "enemy_pack", "silhouette_pack", name))
    return RP.compose_pose_group(rig, pose, prefix)


def hands(pose, shield, weapon, prefix):
    rig = json.load(open(os.path.join(PLAYER, "hands", "rig.json")))
    gear = json.load(open(os.path.join(PLAYER, "gear.json")))
    return uniq(PB.compose(rig, gear, pose, shield, weapon), prefix)


def build(W, H, layers, out):
    """layers: list of raw svg strings (already positioned)."""
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n<defs><clipPath id="fr"><rect width="%d" height="%d"/></clipPath></defs>\n<g clip-path="url(#fr)">\n%s\n</g>\n</svg>\n' % (
        W, H, W, H, W, H, "\n".join(layers))
    open(out, "w").write(svg)


def tf(inner, x, y, s, rot=0):
    return '<g transform="translate(%.1f %.1f) scale(%.4f)%s">%s</g>' % (x, y, s, (' rotate(%s)' % rot if rot else ""), inner)


def glow(cx, cy, r, color, op, uid):
    return ('<defs><radialGradient id="%s" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s" stop-opacity="%s"/><stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient></defs>'
            '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="url(#%s)"/>' % (uid, color, op, color, cx, cy, r, uid))


def vignette(W, H, uid="vg", op=0.7):
    return ('<defs><radialGradient id="%s" cx="0.5" cy="0.5" r="0.75"><stop offset="0.4" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="%s"/></radialGradient></defs>'
            '<rect width="%d" height="%d" fill="url(#%s)"/>' % (uid, op, W, H, uid))


def fade(x, y, w, h, vertical_dir, op, uid, color="#05070a"):
    """linear fade: vertical_dir 'down' = opaque at top -> clear at bottom, 'up' reverse"""
    y1, y2 = ("0", "1") if vertical_dir == "down" else ("1", "0")
    return ('<defs><linearGradient id="%s" x1="0" y1="%s" x2="0" y2="%s"><stop offset="0" stop-color="%s" stop-opacity="%s"/><stop offset="1" stop-color="%s" stop-opacity="0"/></linearGradient></defs>'
            '<rect x="%d" y="%d" width="%d" height="%d" fill="url(#%s)"/>' % (uid, y1, y2, color, op, color, x, y, w, h, uid))


def logo_at(lang, x, y, s, uid):
    return tf(L.logo_group(lang, uid=uid), x, y, s)
