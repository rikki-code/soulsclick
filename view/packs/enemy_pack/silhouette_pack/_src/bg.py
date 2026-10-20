"""Backgrounds: portrait 1080x1920, ground line near y=1500. Low contrast so the enemy stays readable."""
import os
import random
from rigkit import PACK

OUT = os.path.normpath(os.path.join(PACK, "..", "..", "background_pack", "silhouette_pack"))
GY = 1500  # ground line


def arch(x, w, base, top, fill, op=1.0):
    """Pointed arch opening (negative space) through a wall block is drawn as the wall with a hole."""
    r = w / 2
    ys = top + r * 1.3
    return ('<path d="M%d %d L%d %d C%d %d %d %d %d %d C%d %d %d %d %d %d L%d %d Z" fill="%s" opacity="%s"/>'
            % (x, base, x, ys, x, ys - r * 0.9, x + r * 0.5, top + r * 0.45, x + r, top,
               x + r * 1.5, top + r * 0.45, x + w, ys - r * 0.9, x + w, ys, x + w, base, fill, op))


def wall_with_arches(x0, x1, base, top, n, fill, op, gap_fill):
    w = (x1 - x0) / n
    s = '<path d="M%d %d L%d %d L%d %d L%d %d Z" fill="%s" opacity="%s"/>' % (x0, base, x0, top, x1, top, x1, base, fill, op)
    for i in range(n):
        ax = x0 + i * w + w * 0.2
        s += arch(ax, w * 0.6, base, top + (base - top) * 0.28, gap_fill, 1.0)
    return s


def col(x, w, base, top, fill, op=1.0, broken=0):
    t = top + broken
    pts = "M%d %d L%d %d L%d %d L%d %d L%d %d L%d %d Z" % (x, base, x, t + 20, x - 6, t + 8, x + w * 0.5, t - 10 * (1 if broken else 0), x + w + 6, t + 14, x + w, base)
    return '<path d="%s" fill="%s" opacity="%s"/>' % (pts, fill, op)


def make(name, sky, horizon, far, near, ground_a, ground_b, glow, glow_pos, kind):
    random.seed(name)
    p = []
    p.append('<defs>'
             '<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
             '<linearGradient id="gnd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
             '<linearGradient id="fog" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s" stop-opacity="0"/><stop offset="0.6" stop-color="%s" stop-opacity="0.35"/><stop offset="1" stop-color="%s" stop-opacity="0"/></linearGradient>'
             '<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s" stop-opacity="0.34"/><stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>'
             '<radialGradient id="vig" cx="0.5" cy="0.55" r="0.75"><stop offset="0.45" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.6"/></radialGradient>'
             '</defs>' % (sky, horizon, ground_a, ground_b, horizon, horizon, horizon, glow, glow))
    p.append('<rect width="1080" height="%d" fill="url(#sky)"/>' % (GY + 4))
    gx, gy, gr = glow_pos
    p.append('<circle cx="%d" cy="%d" r="%d" fill="url(#glow)"/>' % (gx, gy, gr))
    if kind == "moon":
        p.append('<circle cx="%d" cy="%d" r="64" fill="%s" opacity="0.16"/>' % (gx, gy, glow))
    if kind == "ring":
        p.append('<circle cx="%d" cy="%d" r="230" fill="none" stroke="%s" stroke-width="16" opacity="0.14"/>' % (gx, gy, glow))
        p.append('<circle cx="%d" cy="%d" r="150" fill="none" stroke="%s" stroke-width="6" opacity="0.1"/>' % (gx, gy, glow))
    # far layer
    if kind == "moon":      # ruined courtyard: low wall with arches, broken towers
        p.append(wall_with_arches(-20, 1100, GY, 1050, 6, far, 1, sky))
        p.append(col(70, 90, GY, 780, far, 1, 40))
        p.append(col(900, 110, GY, 700, far, 1, 90))
        p.append('<path d="M360 %d L360 880 L400 850 L420 900 L470 870 L470 %d Z" fill="%s"/>' % (GY, GY, far))
    elif kind == "nave":    # cathedral nave: tall pointed arches
        for i, x in enumerate((-60, 250, 560, 870)):
            p.append(arch(x, 270, GY, 520, far, 1))
        p.append('<rect x="-20" y="%d" width="1120" height="60" fill="%s"/>' % (GY - 60, far))
        for x in (190, 500, 810):
            p.append(col(x, 62, GY, 560, far, 1))
    elif kind == "chains":  # kennel yard: rusted gate bars and hanging chains
        p.append('<rect x="-20" y="%d" width="1120" height="120" fill="%s"/>' % (GY - 120, far))
        for x in range(30, 1080, 110):
            p.append('<path d="M%d %d L%d 760 L%d 700 L%d 760 L%d %d Z" fill="%s"/>' % (x, GY, x, x + 12, x + 24, x + 24, GY, far))
        p.append('<rect x="-20" y="760" width="1120" height="26" fill="%s"/>' % far)
        for x in (150, 380, 640, 900):
            for k in range(16):
                p.append('<ellipse cx="%d" cy="%d" rx="%d" ry="16" fill="none" stroke="%s" stroke-width="7"/>' % (x, 20 + k * 34, 9 if k % 2 else 5, far))
    elif kind == "bell":    # belfry: tall arches with hanging bells
        for x in (-60, 300, 660):
            p.append(arch(x, 330, GY, 460, far, 1))
        for bx, by, sc in ((190, 700, 1.0), (540, 640, 1.2), (890, 720, 0.9)):
            p.append('<rect x="%d" y="%d" width="10" height="%d" fill="%s"/>' % (bx - 5, 0, by - 120 * sc, far))
            p.append(
                '<path d="M%d %d C%d %d %d %d %d %d L%d %d C%d %d %d %d %d %d Z" fill="%s"/>' % (
                bx - 24 * sc, by - 120 * sc, bx - 30 * sc, by - 60 * sc, bx - 60 * sc, by - 30 * sc, bx - 78 * sc, by,
                bx + 78 * sc, by, bx + 60 * sc, by - 30 * sc, bx + 30 * sc, by - 60 * sc, bx + 24 * sc, by - 120 * sc, far))
        p.append('<rect x="-20" y="%d" width="1120" height="60" fill="%s"/>' % (GY - 60, far))
    elif kind == "veil":    # hall of hanging drapes
        for i, x in enumerate(range(-40, 1100, 190)):
            h = 900 + (i % 3) * 120
            p.append('<path d="M%d 0 L%d 0 L%d %d Q%d %d %d %d Q%d %d %d %d L%d %d Z" fill="%s"/>' % (
                x, x + 170, x + 150, h, x + 120, h + 60, x + 90, h, x + 60, h + 70, x + 30, h, x + 10, h - 20, far))
        for x in (250, 790):
            p.append(col(x, 56, GY, 520, far, 1))
    else:                   # ring: huge shattered gate
        p.append('<path d="M-20 %d L-20 640 L140 560 L260 700 L260 %d Z" fill="%s"/>' % (GY, GY, far))
        p.append('<path d="M1100 %d L1100 600 L940 520 L840 690 L840 %d Z" fill="%s"/>' % (GY, GY, far))
        p.append(arch(300, 480, GY, 640, far, 0.0))
        p.append('<path d="M240 %d L240 800 Q540 560 840 800 L840 %d L760 %d L760 840 Q540 680 320 840 L320 %d Z" fill="%s"/>' % (GY, GY, GY, GY, far))
        for x, t in ((120, 980), (950, 940), (60, 1120)):
            p.append(col(x, 60, GY, t, far, 1, 30))
    # fog
    p.append('<rect x="0" y="%d" width="1080" height="360" fill="url(#fog)"/>' % (GY - 330))
    # near layer: side pillars, dark
    if kind == "moon":
        p.append(col(-30, 150, GY + 40, 520, near, 1, 60))
        p.append(col(960, 140, GY + 40, 640, near, 1, 40))
    elif kind in ("nave", "bell", "veil"):
        p.append(col(-30, 170, GY + 40, 380, near, 1))
        p.append(col(940, 170, GY + 40, 380, near, 1))
    elif kind == "chains":
        p.append(col(-30, 120, GY + 40, 700, near, 1, 60))
        p.append(col(970, 120, GY + 40, 660, near, 1, 40))
    else:
        p.append(col(-40, 190, GY + 40, 700, near, 1, 80))
        p.append(col(930, 190, GY + 40, 640, near, 1, 120))
    # ground
    p.append('<rect x="0" y="%d" width="1080" height="%d" fill="url(#gnd)"/>' % (GY, 1920 - GY))
    for k in range(7):  # perspective floor lines
        x = 540 + (k - 3) * 130
        p.append('<path d="M%d %d L%d 1920" stroke="%s" stroke-width="3" opacity="0.10" fill="none"/>' % (540 + (k - 3) * 40, GY, x * 1.9 - 540 * 0.9, horizon))
    for y in (1560, 1640, 1760):
        p.append('<path d="M0 %d L1080 %d" stroke="%s" stroke-width="3" opacity="0.08" fill="none"/>' % (y, y, horizon))
    p.append('<rect width="1080" height="1920" fill="url(#vig)"/>')
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">%s</svg>\n' % "".join(p)
    os.makedirs(OUT, exist_ok=True)
    open(os.path.join(OUT, name + ".svg"), "w").write(svg)
    print("bg", name, len(svg), "bytes")


def build():
    make("grunt", "#0b1114", "#1a2a2b", "#111c1e", "#06090b", "#17231f", "#05080a", "#8fe04a", (800, 520, 420), "moon")
    make("knight", "#0a0d16", "#1a2234", "#111726", "#05070c", "#141b2a", "#04060b", "#5cb8ff", (540, 700, 520), "nave")
    make("warden", "#120a0c", "#2a1416", "#1a0f12", "#080405", "#201014", "#060304", "#ff4a3d", (540, 640, 520), "ring")
    make("hound", "#120d08", "#2b1d10", "#1b130b", "#080503", "#22160c", "#060402", "#ff9a1f", (300, 600, 460), "chains")
    make("dancer", "#0e0a16", "#241a36", "#161024", "#06040b", "#1b1429", "#05030a", "#b57bff", (540, 600, 500), "veil")
    make("bulwark", "#12100a", "#2a2412", "#1a160c", "#080604", "#211c0e", "#060503", "#e3c66a", (540, 760, 500), "bell")


if __name__ == "__main__":
    build()
