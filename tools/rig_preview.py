#!/usr/bin/env python3
"""Compose a rig.json enemy into SVG poses and rasterize them with Godot (same ThorVG as the game).

Usage:
  tools/rig_preview.py <enemy_dir> [pose ...] [--out DIR] [--scale S] [--no-bg] [--no-png] [--lint]
  tools/rig_preview.py --icons <icon_dir> [--no-png]     # lint every *.svg + contact sheet (128 px grid, 64 px strip)

  <enemy_dir>   folder with rig.json and the part SVGs, e.g.
                view/packs/enemy_pack/silhouette_pack/grunt
  pose ...      pose ids to render, or `sheet` (all poses side by side in one image on the enemy's
                background). No pose = every pose as its own PNG plus the sheet.
  --out DIR     default: <pack>/_previews/<enemy_id>/
  --scale S     raster scale (default 1.0 for a pose, 0.5 per cell for the sheet)
  --no-bg       transparent single poses (sheet always has a background)
  --lint        only check the SVGs (ThorVG rules, size budget) and that every pose keeps its ink
                inside the canvas (12 px margin); a normal run does this too

Transform model (same as the game's EnemyRig): a part's pivot (in its own SVG pixels) sits at
`at + move` in the parent's pixels (root: canvas pixels), rotated by `rot` degrees (clockwise,
y down) around the pivot. Parts are drawn flat, sorted by `z` as an ABSOLUTE draw order across the whole rig
(ties: order in the `parts` list). The game must not sum z along the parent chain.
"""
import json
import math
import os
import re
import subprocess
import sys

GODOT = os.environ.get("GODOT", "/Users/vladimirafanasev/dev/godot/bin/godot.macos.editor.arm64")
PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
POSE_ORDER = ["idle", "windup_quick", "strike_quick", "windup_heavy", "strike_heavy", "windup_feint",
              "windup_combo", "strike_combo", "recover", "staggered", "hurt", "death"]
MAX_SVG_BYTES = 30 * 1024
FORBIDDEN = [r"<filter", r"<text", r"<tspan", r"<image", r"<style", r"\bclass=", r"href=", r"<script",
             r"<foreignObject", r"feGaussianBlur", r"filter="]
# Background crop in bg pixels that stands behind the 1024 enemy canvas (portrait 1080x1920).
BG_CROP = (28, 560, 1024, 1024)


# ---------- affine helpers: (a, b, c, d, e, f) like SVG matrix() ----------
def mat_mul(m, n):
    a, b, c, d, e, f = m
    A, B, C, D, E, F = n
    return (a * A + c * B, b * A + d * B, a * C + c * D, b * C + d * D, a * E + c * F + e, b * E + d * F + f)


def mat_translate(x, y):
    return (1, 0, 0, 1, x, y)


def mat_rotate(deg):
    r = math.radians(deg)
    return (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0)


def mat_apply(m, p):
    return (m[0] * p[0] + m[2] * p[1] + m[4], m[1] * p[0] + m[3] * p[1] + m[5])


def mat_str(m):
    return "matrix(%s)" % " ".join("%.4f" % v for v in m)


# ---------- rig ----------
def load_rig(enemy_dir):
    with open(os.path.join(enemy_dir, "rig.json")) as f:
        rig = json.load(f)
    rig["_dir"] = enemy_dir
    rig["_id"] = os.path.basename(os.path.normpath(enemy_dir))
    rig["_parts"] = {p["id"]: p for p in rig["parts"]}
    return rig


def part_local(rig, part, pose):
    """Matrix mapping the part's own pixels into its parent's pixels, for a pose dict."""
    p = rig["_parts"][part]
    d = pose.get(part, {})
    mv = d.get("move", [0, 0])
    return mat_mul(mat_mul(mat_translate(p["at"][0] + mv[0], p["at"][1] + mv[1]), mat_rotate(d.get("rot", 0))),
                   mat_translate(-p["pivot"][0], -p["pivot"][1]))


def part_world(rig, part, pose):
    m = part_local(rig, part, pose)
    parent = rig["_parts"][part]["parent"]
    if parent:
        m = mat_mul(part_world(rig, parent, pose), m)
    return m


def pivot_world(rig, part, pose):
    """Canvas position of a part's pivot in a pose."""
    return mat_apply(part_world(rig, part, pose), rig["_parts"][part]["pivot"])


# ---------- svg composition ----------
def read_svg_inner(path, prefix):
    with open(path) as f:
        text = f.read()
    text = re.sub(r"<\?xml[^>]*\?>", "", text)
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    m = re.search(r"<svg[^>]*>(.*)</svg>", text, flags=re.S)
    if not m:
        raise SystemExit("not an svg: %s" % path)
    inner = m.group(1)
    # unique ids per placed instance
    inner = re.sub(r'id="([^"]+)"', lambda g: 'id="%s%s"' % (prefix, g.group(1)), inner)
    inner = re.sub(r"url\(#([^)]+)\)", lambda g: "url(#%s%s)" % (prefix, g.group(1)), inner)
    return inner


def svg_size(path):
    with open(path) as f:
        head = f.read(2000)
    w = re.search(r'\bwidth="([\d.]+)', head)
    h = re.search(r'\bheight="([\d.]+)', head)
    return (float(w.group(1)), float(h.group(1))) if w and h else (1024.0, 1024.0)


def compose_pose_group(rig, pose_id, prefix=""):
    pose = rig["poses"].get(pose_id, rig["poses"].get("idle", {}))
    out = []
    order = sorted(range(len(rig["parts"])), key=lambda i: (rig["parts"][i]["z"], i))
    for i in order:
        p = rig["parts"][i]
        inner = read_svg_inner(os.path.join(rig["_dir"], p["file"]), "%s%s_" % (prefix, p["id"]))
        out.append('<g id="%spart_%s" transform="%s">%s</g>' % (prefix, p["id"], mat_str(part_world(rig, p["id"], pose)), inner))
    return "\n".join(out)


def canvas_size(rig):
    return rig.get("canvas", [1024, 1024])


def find_background(rig):
    pack = os.path.dirname(os.path.normpath(rig["_dir"]))
    pack_name = os.path.basename(pack)
    path = os.path.join(pack, "..", "..", "background_pack", pack_name, rig["_id"] + ".svg")
    return os.path.normpath(path) if os.path.exists(path) else None


def background_group(rig, prefix, x, y, size):
    """Background crop placed at (x, y) in a size x size cell, clipped to the cell."""
    bg = find_background(rig)
    if not bg:
        return '<rect x="%d" y="%d" width="%d" height="%d" fill="#1a1f29"/>' % (x, y, size, size)
    s = size / BG_CROP[2]
    inner = read_svg_inner(bg, prefix + "bg_")
    cid = prefix + "clip"
    return ('<clipPath id="%s"><rect x="%d" y="%d" width="%d" height="%d"/></clipPath>'
            '<g clip-path="url(#%s)"><g transform="translate(%.3f,%.3f) scale(%.5f)">%s</g></g>'
            % (cid, x, y, size, size, cid, x - BG_CROP[0] * s, y - BG_CROP[1] * s, s, inner))


def single_svg(rig, pose_id, with_bg=True):
    w, h = canvas_size(rig)
    parts = []
    if with_bg:
        parts.append(background_group(rig, "bg_", 0, 0, w))
    parts.append(compose_pose_group(rig, pose_id, "s_"))
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n%s\n</svg>\n'
            % (w, h, w, h, "\n".join(parts)))


def sheet_svg(rig, pose_ids, cols=4):
    w, h = canvas_size(rig)
    rows = (len(pose_ids) + cols - 1) // cols
    body = []
    for i, pid in enumerate(pose_ids):
        x, y = (i % cols) * w, (i // cols) * h
        prefix = "c%d_" % i
        body.append('<clipPath id="%scell"><rect x="%d" y="%d" width="%d" height="%d"/></clipPath>'
                    '<g clip-path="url(#%scell)">%s<g transform="translate(%d,%d)">%s</g></g>' % (
                        prefix, x, y, w, h, prefix, background_group(rig, prefix, x, y, w), x, y,
                        compose_pose_group(rig, pid, prefix)))
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n%s\n</svg>\n'
            % (w * cols, h * rows, w * cols, h * rows, "\n".join(body)))


# ---------- lint ----------
def png_alpha_bbox(path):
    """(x0, y0, x1, y1, w, h) of non-transparent pixels in an 8-bit RGBA PNG (pure python)."""
    import struct
    import zlib
    data = open(path, "rb").read()
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(data):
        ln, typ = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + ln]
        if typ == b"IHDR":
            w, h = struct.unpack(">II", body[:8])
        elif typ == b"IDAT":
            idat += body
        pos += 12 + ln
    raw = zlib.decompress(idat)
    stride = w * 4
    prev = bytearray(stride)
    x0, y0, x1, y1 = w, h, -1, -1
    i = 0
    for y in range(h):
        f = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for k in range(stride):
            a = line[k - 4] if k >= 4 else 0
            b = prev[k]
            c = prev[k - 4] if k >= 4 else 0
            if f == 1:
                line[k] = (line[k] + a) & 255
            elif f == 2:
                line[k] = (line[k] + b) & 255
            elif f == 3:
                line[k] = (line[k] + (a + b) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[k] = (line[k] + pr) & 255
        prev = line
        row = line[3::4]
        if any(row):
            xs = [x for x, v in enumerate(row) if v > 8]
            if xs:
                x0, x1 = min(x0, xs[0]), max(x1, xs[-1])
                y0, y1 = min(y0, y), max(y1, y)
    return x0, y0, x1, y1, w, h


def bounds_check(rig, margin=12):
    """Render every pose transparent at 1/4 scale and warn when ink comes within `margin` px of the canvas edge."""
    tmp = os.path.join(PROJECT, "view/packs/enemy_pack/silhouette_pack/_previews/.bounds")
    os.makedirs(tmp, exist_ok=True)
    jobs = []
    for pid in rig["poses"]:
        path = os.path.join(tmp, pid + ".svg")
        open(path, "w").write(single_svg(rig, pid, False))
        jobs.append((path, path[:-4] + ".png", 0.25))
    if not rasterize(jobs, quiet=True):
        print("WARN bounds check could not rasterize")
        return
    for svg, png, _ in jobs:
        x0, y0, x1, y1, w, h = png_alpha_bbox(png)
        m = margin / 4
        if x1 < 0:
            continue
        if x0 < m or y0 < m or x1 > w - 1 - m or y1 > h - 1 - m:
            print("WARN pose %s leaves canvas margin (ink bbox %d,%d..%d,%d of %d)" % (
                os.path.basename(svg)[:-4], x0 * 4, y0 * 4, x1 * 4, y1 * 4, w * 4))
        os.remove(svg)
        os.remove(png)
    os.rmdir(tmp)


def lint(rig):
    ok = True
    for p in rig["parts"]:
        path = os.path.join(rig["_dir"], p["file"])
        if not os.path.exists(path):
            print("ERROR missing file %s" % path)
            ok = False
            continue
        data = open(path).read()
        size = len(data.encode())
        if size > MAX_SVG_BYTES:
            print("ERROR %s is %d bytes (budget %d)" % (p["file"], size, MAX_SVG_BYTES))
            ok = False
        for pat in FORBIDDEN:
            if re.search(pat, data):
                print("ERROR %s uses forbidden construct %s" % (p["file"], pat))
                ok = False
        w, h = svg_size(path)
        if not (0 <= p["pivot"][0] <= w and 0 <= p["pivot"][1] <= h):
            print("NOTE %s pivot %s outside its %dx%d image" % (p["file"], p["pivot"], w, h))
        if p["parent"] and p["parent"] not in rig["_parts"]:
            print("ERROR %s has unknown parent %s" % (p["id"], p["parent"]))
            ok = False
    for g in rig.get("glow_parts", []):
        if g not in rig["_parts"]:
            print("ERROR glow part %s is not a part" % g)
            ok = False
    for pid, pose in rig["poses"].items():
        for part in pose:
            if part not in rig["_parts"]:
                print("ERROR pose %s names unknown part %s" % (pid, part))
                ok = False
    missing = [p for p in POSE_ORDER if p not in rig["poses"]]
    if missing:
        print("NOTE missing poses (fall back to idle): %s" % ", ".join(missing))
    bounds_check(rig)
    print("lint %s: %s" % (rig["_id"], "ok" if ok else "FAILED"))
    return ok


# ---------- main ----------
def rasterize(jobs, quiet=False):
    list_path = os.path.join(PROJECT, "view/packs/enemy_pack/silhouette_pack/_previews/.jobs.txt")
    os.makedirs(os.path.dirname(list_path), exist_ok=True)
    with open(list_path, "w") as f:
        for svg, png, scale in jobs:
            f.write("%s\t%s\t%s\n" % (svg, png, scale))
    r = subprocess.run([GODOT, "--headless", "--path", PROJECT, "-s", "tools/svg_to_png.gd", "--", "--list", list_path],
                       capture_output=True, text=True)
    for line in (r.stdout + r.stderr).splitlines():
        if (line.startswith("wrote") and not quiet) or "ERROR" in line or "error" in line.lower():
            print(line)
    os.remove(list_path)
    return r.returncode == 0


ICON_MAX_BYTES = 12 * 1024
ICON_COLS = 8
# silhouette, inset, rim, rim-light, plate, plate edge, void; anything else counts as an accent color
ICON_NEUTRALS = {"07090c", "10141b", "56657e", "9fb0cc", "1a212c", "2f3947", "000000"}


def lint_icons(icon_dir):
    """Icon rules: 256x256, forbidden constructs, size budget, exactly ONE color outside the neutral palette (the accent)."""
    ok = True
    files = sorted(f for f in os.listdir(icon_dir) if f.endswith(".svg"))
    for f in files:
        data = open(os.path.join(icon_dir, f)).read()
        if 'width="256" height="256"' not in data or 'viewBox="0 0 256 256"' not in data:
            print("ERROR %s is not 256x256" % f)
            ok = False
        if len(data.encode()) > ICON_MAX_BYTES:
            print("ERROR %s is %d bytes (budget %d)" % (f, len(data.encode()), ICON_MAX_BYTES))
            ok = False
        for pat in FORBIDDEN:
            if re.search(pat, data):
                print("ERROR %s uses forbidden construct %s" % (f, pat))
                ok = False
        sat = {h.lower() for h in re.findall(r"#([0-9a-fA-F]{6})", data)} - ICON_NEUTRALS
        if len(sat) != 1:
            print("ERROR %s has %d accent colors %s (want exactly 1)" % (f, len(sat), sorted(sat)))
            ok = False
        m = re.findall(r'stroke-width="([0-9.]+)"', data)
        thin = [w for w in m if float(w) < 3]
        if thin:
            print("NOTE %s has hairline strokes %s (unreadable at 64 px)" % (f, sorted(set(thin))))
    print("lint icons (%d files): %s" % (len(files), "ok" if ok else "FAILED"))
    return ok, files


def icon_sheet(icon_dir, files):
    n = len(files)
    rows = (n + ICON_COLS - 1) // ICON_COLS
    w = ICON_COLS * 136 + 8
    strip_y = rows * 136 + 24
    h = strip_y + ((n + 15) // 16) * 68 + 16
    g = ['<rect width="%d" height="%d" fill="#0b0e13"/>' % (w, h)]
    for i, f in enumerate(files):
        inner = read_svg_inner(os.path.join(icon_dir, f), "i%d_" % i)
        x, y = 8 + (i % ICON_COLS) * 136, 8 + (i // ICON_COLS) * 136
        g.append('<g transform="translate(%d %d) scale(0.5)">%s</g>' % (x, y, inner))
        x, y = 8 + (i % 16) * 68, strip_y + (i // 16) * 68
        g.append('<g transform="translate(%d %d) scale(0.25)">%s</g>' % (x, y, inner.replace('id="i%d_' % i, 'id="j%d_' % i)))
    return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % (w, h, w, h, "".join(g))


def main_icons(argv):
    icon_dir = os.path.abspath(argv[1])
    ok, files = lint_icons(icon_dir)
    if "--no-png" in argv or not files:
        return 0 if ok else 1
    out = os.path.join(os.path.dirname(icon_dir), "_previews")
    os.makedirs(out, exist_ok=True)
    svg_path = os.path.join(out, os.path.basename(icon_dir) + "_sheet.svg")
    open(svg_path, "w").write(icon_sheet(icon_dir, files))
    print("sheet order (row-major, %d columns): %s" % (ICON_COLS, ", ".join(f[:-4] for f in files)))
    if not rasterize([(svg_path, svg_path[:-4] + ".png", 1.0)]):
        print("rasterize FAILED")
        return 1
    return 0 if ok else 1


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    if argv[0] == "--icons":
        return main_icons(argv)
    enemy_dir = os.path.abspath(argv[0])
    poses, out_dir, scale, bg, png, only_lint = [], None, None, True, True, False
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--out":
            out_dir = os.path.abspath(argv[i + 1]); i += 1
        elif a == "--scale":
            scale = float(argv[i + 1]); i += 1
        elif a == "--no-bg":
            bg = False
        elif a == "--no-png":
            png = False
        elif a == "--lint":
            only_lint = True
        else:
            poses.append(a)
        i += 1
    rig = load_rig(enemy_dir)
    ok = lint(rig)
    if only_lint:
        return 0 if ok else 1
    if out_dir is None:
        out_dir = os.path.join(os.path.dirname(enemy_dir), "_previews", rig["_id"])
    os.makedirs(out_dir, exist_ok=True)
    if not poses:
        poses = list(rig["poses"].keys()) + ["sheet"]
    jobs = []
    for pid in poses:
        if pid == "sheet":
            ids = [p for p in POSE_ORDER if p in rig["poses"]] + [p for p in rig["poses"] if p not in POSE_ORDER]
            svg = sheet_svg(rig, ids)
            name, sc = "sheet", scale or 0.5
            print("sheet order (row-major, 4 columns): " + ", ".join(ids))
        else:
            if pid not in rig["poses"]:
                print("unknown pose %s" % pid)
                continue
            svg, name, sc = single_svg(rig, pid, bg), pid, scale or 1.0
        svg_path = os.path.join(out_dir, name + ".svg")
        with open(svg_path, "w") as f:
            f.write(svg)
        jobs.append((svg_path, os.path.join(out_dir, name + ".png"), sc))
    if png and not rasterize(jobs):
        print("rasterize FAILED")
        return 1
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
