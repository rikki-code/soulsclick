"""Realm backgrounds 2-4 (normal + boss). 1080x1920, ground line y=1500, low contrast, centre kept calm for the enemy.
Run: python3 realms.py   (writes ../realm_<n>.svg, ../realm_<n>_boss.svg; realm 1 = copies of knight / warden)"""
import math
import os
import random
import shutil

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
GY = 1500
f = lambda v: ("%.1f" % v).rstrip("0").rstrip(".")


def P(d, fill, op=1.0, stroke=None, sw=0, extra=""):
    s = '<path d="%s" fill="%s"' % (d, fill if not stroke else "none")
    if stroke:
        s = '<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round"' % (d, stroke, f(sw))
    return s + ' opacity="%s"%s/>' % (f(op), extra)


def R(x, y, w, h, fill, op=1.0):
    return '<rect x="%s" y="%s" width="%s" height="%s" fill="%s" opacity="%s"/>' % (f(x), f(y), f(w), f(h), fill, f(op))


def C(x, y, r, fill, op=1.0):
    return '<circle cx="%s" cy="%s" r="%s" fill="%s" opacity="%s"/>' % (f(x), f(y), f(r), fill, f(op))


def E(x, y, rx, ry, fill, op=1.0, stroke=None, sw=0, rot=0):
    t = ' transform="rotate(%s %s %s)"' % (f(rot), f(x), f(y)) if rot else ""
    if stroke:
        return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="%s" stroke-width="%s" opacity="%s"%s/>' % (f(x), f(y), f(rx), f(ry), stroke, f(sw), f(op), t)
    return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="%s"%s/>' % (f(x), f(y), f(rx), f(ry), fill, f(op), t)


def pointed(x0, x1, base, top, fill, op=1.0):
    """Pointed arch silhouette (solid) between x0..x1, apex at top."""
    w = x1 - x0
    sh = top + w * 0.55
    return P("M%s %s L%s %s Q%s %s %s %s Q%s %s %s %s L%s %s Z" % (
        f(x0), f(base), f(x0), f(sh), f(x0), f(top + w * 0.2), f((x0 + x1) / 2), f(top),
        f(x1), f(top + w * 0.2), f(x1), f(sh), f(x1), f(base)), fill, op)


def frame(sky0, sky1, glow, gpos, gr, gop, gnd0, gnd1, fog, grid, vig=0.6):
    d = ('<defs>'
         '<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
         '<linearGradient id="gnd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
         '<linearGradient id="fog" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s" stop-opacity="0"/><stop offset="0.6" stop-color="%s" stop-opacity="0.35"/><stop offset="1" stop-color="%s" stop-opacity="0"/></linearGradient>'
         '<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s" stop-opacity="%s"/><stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>'
         '<radialGradient id="vig" cx="0.5" cy="0.55" r="0.75"><stop offset="0.45" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="%s"/></radialGradient>'
         '</defs>') % (sky0, sky1, gnd0, gnd1, fog, fog, fog, glow, gop, glow, vig)
    head = d + '<rect width="1080" height="1504" fill="url(#sky)"/>'
    head += '<circle cx="%s" cy="%s" r="%s" fill="url(#glow)"/>' % (gpos[0], gpos[1], gr)
    return head


def tail(grid, extra_ground=""):
    s = '<rect x="0" y="1170" width="1080" height="360" fill="url(#fog)"/>'
    return s


def ground(grid):
    s = '<rect x="0" y="1500" width="1080" height="420" fill="url(#gnd)"/>'
    for x in range(420, 700, 40):
        s += '<path d="M%d 1500 L%d 1920" stroke="%s" stroke-width="3" opacity="0.10" fill="none"/>' % (x, 540 + (x - 540) * 5.0, grid)
    for y in (1560, 1640, 1760):
        s += '<path d="M0 %d L1080 %d" stroke="%s" stroke-width="3" opacity="0.08" fill="none"/>' % (y, y, grid)
    return s


def vig():
    return '<rect width="1080" height="1920" fill="url(#vig)"/>'


def wrap(body):
    return '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">%s</svg>' % body


def chain(x, y0, y1, link, col, op, sw=5):
    """Hanging chain of alternating links (front view / edge view)."""
    s = P("M%s %s L%s %s" % (f(x), f(y0), f(x), f(y1)), col, op, stroke=col, sw=sw * 0.6)
    y, k = y0 + link * 0.5, 0
    while y < y1 - link:
        s += E(x, y, link * 0.28 if k % 2 == 0 else link * 0.1, link * 0.55, col, op, stroke=col, sw=sw)
        y += link * 0.9
        k += 1
    return s


# ------------------------------------------------------------------ realm 2: Drowned Crypt
def water(y0, col, ripple, seed, op=0.55):
    random.seed(seed)
    s = '<defs><linearGradient id="wat" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s" stop-opacity="0.0"/><stop offset="0.25" stop-color="%s" stop-opacity="%s"/><stop offset="1" stop-color="%s" stop-opacity="%s"/></linearGradient></defs>' % (col, col, f(op), col, f(op * 0.7))
    s += '<rect x="0" y="%d" width="1080" height="%d" fill="url(#wat)"/>' % (y0, GY - y0)
    for _ in range(26):
        y = random.uniform(y0 + 14, GY - 8)
        w = random.uniform(50, 190)
        x = random.uniform(-20, 1060)
        s += P("M%s %s L%s %s" % (f(x), f(y), f(x + w), f(y)), ripple, random.uniform(0.07, 0.16), stroke=ripple, sw=3)
    return s


def realm2():
    b = frame("#060f15", "#12303a", "#4fd0c0", (540, 700), 520, 0.28, "#0e2229", "#03080b", "#12303a", "#12303a")
    # far wall with flooded arches
    b += R(-10, 520, 1100, 980, "#0c1d25")
    for i in range(4):
        x0 = 30 + i * 262
        b += pointed(x0, x0 + 220, GY, 640, "#050d12")
        b += pointed(x0 + 26, x0 + 194, GY, 700, "#0f2c35", 0.55)
    b += R(-10, 520, 1100, 18, "#112832")
    b += water(1330, "#2c7f86", "#7fe0d4", "r2")
    for x in (150, 1000):
        b += chain(x, 0, 900 if x < 500 else 760, 36, "#09151b", 0.9)
    b += chain(60, 0, 520, 34, "#071016", 1.0, 6) + chain(1030, 0, 640, 34, "#071016", 1.0, 6)
    b += tail("#12303a")
    for x, w in ((-30, 170), (940, 170)):
        b += P("M%d 1540 L%d 380 L%d 366 L%d 380 L%d 1540 Z" % (x, x, x + 12, x + w - 12, x + w), "#03080b")
    b += ground("#12303a")
    b += vig()
    return wrap(b)


def anchor(cx, y0, col, op):
    s = E(cx, y0 + 30, 26, 30, col, op, stroke=col, sw=12)
    s += P("M%s %s L%s %s" % (f(cx), f(y0 + 60), f(cx), f(y0 + 330)), col, op, stroke=col, sw=16)
    s += P("M%s %s L%s %s" % (f(cx - 60), f(y0 + 110), f(cx + 60), f(y0 + 110)), col, op, stroke=col, sw=14)
    s += P("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s" % (
        f(cx), f(y0 + 330), f(cx - 120), f(y0 + 330), f(cx - 130), f(y0 + 250),
        f(cx), f(y0 + 330), f(cx + 120), f(y0 + 330), f(cx + 130), f(y0 + 250)), col, op, stroke=col, sw=16)
    return s


def realm2_boss():
    b = frame("#04090d", "#0e2830", "#4fd0c0", (540, 760), 600, 0.34, "#0c1e25", "#020608", "#0e2830", "#0e2830", 0.7)
    b += R(-10, 380, 1100, 1120, "#0a1a21")
    # drowned gate
    b += pointed(130, 950, GY, 300, "#050d12")
    b += pointed(190, 890, GY, 380, "#10343c", 0.6)
    for x in range(260, 840, 70):
        b += P("M%d 1000 L%d 1400" % (x, x), "#050d12", 0.55, stroke="#050d12", sw=10)
    b += P("M130 1000 L950 1000", "#050d12", 0.5, stroke="#050d12", sw=10)
    b += anchor(540, 40, "#071117", 0.9)
    b += water(1310, "#2c7f86", "#7fe0d4", "r2b", 0.6)
    b += chain(70, 0, 800, 44, "#050d11", 1.0, 7) + chain(1010, 0, 720, 44, "#050d11", 1.0, 7)
    b += chain(210, 0, 500, 30, "#08141a", 0.9) + chain(870, 0, 560, 30, "#08141a", 0.9)
    b += tail("#0e2830")
    for x, w in ((-30, 190), (920, 190)):
        b += P("M%d 1540 L%d 300 L%d 284 L%d 300 L%d 1540 Z" % (x, x, x + 14, x + w - 14, x + w), "#020608")
    b += ground("#0e2830")
    b += vig()
    return wrap(b)


# ------------------------------------------------------------------ realm 3: Bone Cathedral
def candle(x, y, h, op=1.0, glow=True):
    s = R(x - 6, y - h, 12, h, "#7a6e56", op * 0.8)
    s += E(x, y - h - 14, 5, 11, "#f0c070", op * 0.7)
    if glow:
        s += C(x, y - h - 14, 34, "#f0b050", op * 0.07)
    return s


def candelabra(x, y, tiers, op=1.0):
    s = P("M%s %s L%s %s" % (f(x), f(y), f(x), f(y - 220)), "#2a251c", op, stroke="#2a251c", sw=12)
    s += P("M%s %s L%s %s" % (f(x - 40), f(y), f(x + 40), f(y)), "#2a251c", op, stroke="#2a251c", sw=14)
    for i in range(tiers):
        yy = y - 120 - i * 50
        s += P("M%s %s L%s %s" % (f(x - 50), f(yy), f(x + 50), f(yy)), "#2a251c", op, stroke="#2a251c", sw=8)
        for dx in (-44, 0, 44):
            s += candle(x + dx, yy - 4, 26 + (i * 7 + dx) % 10, op)
    return s


def bone_pillar(x, w, top, fill, hi, op=1.0):
    s = R(x, top, w, GY - top + 40, fill, op)
    for i in range(1, 4):
        xx = x + w * i / 4
        s += P("M%s %s L%s %s" % (f(xx), f(top + 20), f(xx), f(GY)), hi, 0.25 * op, stroke=hi, sw=3)
    for y in range(top + 40, GY - 40, 90):  # vertebra-like bands
        s += E(x + w / 2, y, w * 0.6, 9, hi, 0.12 * op)
    s += E(x + w / 2, top, w * 0.7, 14, fill, op)
    return s


def ribs(x0, x1, spring, apex, col, op, sw):
    mx = (x0 + x1) / 2
    s = P("M%s %s Q%s %s %s %s Q%s %s %s %s" % (f(x0), f(spring), f(x0), f(apex + (spring - apex) * 0.25), f(mx), f(apex), f(x1), f(apex + (spring - apex) * 0.25), f(x1), f(spring)), col, op, stroke=col, sw=sw)
    # diagonal ribs crossing at the boss
    s += P("M%s %s Q%s %s %s %s" % (f(x0), f(spring), f(mx - (x1 - x0) * 0.1), f(apex - 40), f(x1), f(spring)), col, op * 0.7, stroke=col, sw=sw * 0.7)
    return s


def realm3():
    b = frame("#0d0b09", "#2a251c", "#e8d8b0", (540, 640), 520, 0.2, "#201c15", "#060504", "#2a251c", "#2a251c")
    xs = [-60, 330, 750, 1140]
    for a, c in zip(xs, xs[1:]):
        b += ribs(a + 55, c - 55, 700, 270, "#4a4333", 0.55, 20)
        b += pointed(a + 80, c - 80, GY, 520, "#16130e", 0.8)
    b += P("M-20 300 L1100 300", "#4a4333", 0.5, stroke="#4a4333", sw=10)
    for x in (-60, 330, 750, 1140):
        b += bone_pillar(x - 55, 110, 700, "#322d22", "#8a7e66")
    b += R(-20, 1440, 1120, 60, "#322d22")
    b += tail("#2a251c")
    b += candelabra(110, GY, 3, 0.9) + candelabra(970, GY, 3, 0.9)
    for x in (230, 860, 300, 790):
        b += candle(x, GY, 30 + x % 17, 0.8)
    for x, w in ((-30, 150), (960, 150)):
        b += bone_pillar(x, w, 380, "#080706", "#6b6150", 1.0)
    b += ground("#2a251c")
    for x in (180, 910, 120, 1000):
        b += candle(x, GY + 40 + x % 30, 28, 0.7)
    b += vig()
    return wrap(b)


def realm3_boss():
    b = frame("#080706", "#241f17", "#f0d8a0", (540, 600), 640, 0.3, "#1c1812", "#040403", "#241f17", "#241f17", 0.7)
    # nested lancet window (glowing)
    b += pointed(240, 840, GY, 260, "#2b251a", 0.9)
    b += pointed(300, 780, GY, 340, "#3a3224", 0.8)
    b += pointed(360, 720, GY, 420, "#48402e", 0.5)
    b += E(540, 800, 260, 340, "#f0d8a0", 0.04)
    # giant ribcage framing: ribs sweep from floor edges to the spine at the top
    for i in range(7):
        t = i / 6.0
        y0 = 1450 - i * 110
        yr = 260 + i * 60
        w = 60 + i * 10
        b += P("M-30 %s Q%s %s 540 %s" % (f(y0 + 150), f(150 + t * 60), f(yr - 140), f(120 + i * 22)), "#3b3427", 0.55, stroke="#3b3427", sw=w * 0.45)
        b += P("M1110 %s Q%s %s 540 %s" % (f(y0 + 150), f(930 - t * 60), f(yr - 140), f(120 + i * 22)), "#3b3427", 0.55, stroke="#3b3427", sw=w * 0.45)
    for i in range(7):  # spine hanging from the vault
        b += E(540, 40 + i * 34, 30 - i * 1.5, 13, "#4b4332", 0.7)
    b += P("M540 0 L540 270", "#4b4332", 0.4, stroke="#4b4332", sw=14)
    b += tail("#241f17")
    for x in (80, 1000):
        b += candelabra(x, GY, 5, 0.95)
    for x in (200, 880):
        b += candelabra(x, GY, 3, 0.8)
    for x, w in ((-30, 130), (980, 130)):
        b += bone_pillar(x, w, 300, "#060504", "#6b6150", 1.0)
    b += ground("#241f17")
    for x in (60, 120, 960, 1020, 250, 830):
        b += candle(x, GY + 60 + (x * 7) % 90, 26, 0.7)
    b += vig()
    return wrap(b)


# ------------------------------------------------------------------ realm 4: Ashen Abyss
def embers(n, seed, ymin=100, ymax=1480, col="#ff6a2a", skip=None):
    random.seed(seed)
    s = ""
    for _ in range(n):
        y = ymin + (ymax - ymin) * random.random() ** 0.6
        x = random.uniform(10, 1070)
        r = random.choice((2, 2, 3, 3, 4, 6))
        s += C(x, y, r, col, random.uniform(0.15, 0.5) * (0.4 + 0.6 * y / ymax))
    return s


def broken_span(y, x0, x1, th, fill, op, seed, hang=60):
    """Bridge deck from x0..x1, jagged ends, supports snapped off."""
    random.seed(seed)
    j = lambda: random.uniform(-16, 16)
    d = "M%s %s L%s %s L%s %s L%s %s L%s %s L%s %s L%s %s Z" % (
        f(x0), f(y), f(x1 + j()), f(y), f(x1 - 30), f(y + th * 0.6), f(x1 - 70), f(y + th + hang), f(x1 - 110), f(y + th),
        f(x0 + 50), f(y + th + 20), f(x0), f(y + th * 0.5))
    s = P(d, fill, op)
    # railing posts
    for x in range(int(x0) + 30, int(x1) - 30, 80):
        if random.random() < 0.7:
            s += R(x, y - random.randint(20, 46), 10, 46, fill, op)
    return s


def spire(x, base, top, w, fill, op):
    return P("M%s %s L%s %s L%s %s L%s %s L%s %s Z" % (f(x - w), f(base), f(x - w * 0.5), f(top + 120), f(x), f(top), f(x + w * 0.4), f(top + 160), f(x + w), f(base)), fill, op)


def realm4():
    b = frame("#080405", "#26100f", "#d8402a", (540, 1420), 640, 0.30, "#1c0e0d", "#050203", "#2a1210", "#2a1210")
    for x, t, w in ((90, 360, 70), (330, 560, 50), (760, 520, 55), (990, 330, 80)):
        b += spire(x, 1300, t, w, "#12090a", 0.9)
    b += broken_span(960, -40, 520, 38, "#150a0b", 0.9, "a")
    b += broken_span(1130, 620, 1130, 44, "#1a0d0d", 0.95, "b")
    b += P("M180 500 L250 470 L290 520 L240 560 Z", "#150a0b", 0.8)
    b += P("M820 700 L900 680 L930 730 L870 760 Z", "#150a0b", 0.8)
    b += P("M420 380 L470 360 L500 400 L450 430 Z", "#150a0b", 0.6)
    b += embers(46, "e4", 200, 1480)
    b += tail("#2a1210")
    b += broken_span(1290, -60, 330, 60, "#0a0505", 1.0, "c", 90)
    b += broken_span(1290, 760, 1140, 60, "#0a0505", 1.0, "d", 90)
    b += R(-40, 1300, 40, 240, "#0a0505") 
    b += ground("#2a1210")
    # cracked slab edge at the ground line
    b += P("M0 1500 L110 1512 L190 1500 L330 1510 L520 1500 L700 1508 L900 1500 L1080 1506 L1080 1500 Z", "#0a0505", 0.9)
    b += embers(30, "e5", 1100, 1700, "#ff7a30")
    b += vig()
    return wrap(b)


def realm4_boss():
    b = frame("#050203", "#200c0c", "#e8452a", (540, 640), 620, 0.34, "#180a0a", "#030101", "#2a1210", "#2a1210", 0.7)
    # black sun with cracked ember ring
    b += C(540, 600, 250, "#040102", 0.95)
    b += C(540, 600, 262, "#ff4a3d", 0.0)
    b += E(540, 600, 262, 262, "#ff4a3d", 0.16, stroke="#ff4a3d", sw=14)
    b += E(540, 600, 330, 330, "#ff4a3d", 0.07, stroke="#ff4a3d", sw=6)
    b += P("M470 470 L520 560 L490 620 L550 700 L520 770", "#ff4a3d", 0.14, stroke="#ff4a3d", sw=8)
    for x, t, w in ((70, 260, 90), (260, 520, 60), (830, 480, 60), (1010, 240, 95)):
        b += spire(x, 1300, t, w, "#0f0708", 0.95)
    # long bridge into the sun (perspective trapezoid with snapped end)
    b += P("M440 1300 L640 1300 L700 1440 L380 1440 Z", "#120909", 0.6)
    b += broken_span(1030, -40, 330, 40, "#120909", 0.9, "f")
    b += broken_span(1080, 740, 1130, 40, "#120909", 0.9, "g")
    b += embers(70, "e6", 120, 1480)
    b += tail("#2a1210")
    b += broken_span(1260, -60, 300, 70, "#070303", 1.0, "h", 110)
    b += broken_span(1260, 780, 1140, 70, "#070303", 1.0, "i", 110)
    b += ground("#2a1210")
    b += P("M0 1500 L90 1514 L180 1500 L360 1512 L540 1500 L720 1512 L900 1500 L1080 1510 L1080 1500 Z", "#070303", 0.9)
    b += embers(40, "e7", 1100, 1780, "#ff7a30")
    b += vig()
    return wrap(b)


def main():
    shutil.copy(os.path.join(OUT, "knight.svg"), os.path.join(OUT, "realm_1.svg"))
    shutil.copy(os.path.join(OUT, "warden.svg"), os.path.join(OUT, "realm_1_boss.svg"))
    for n, (a, bs) in {2: (realm2, realm2_boss), 3: (realm3, realm3_boss), 4: (realm4, realm4_boss)}.items():
        for name, fn in (("realm_%d.svg" % n, a), ("realm_%d_boss.svg" % n, bs)):
            with open(os.path.join(OUT, name), "w") as fh:
                fh.write(fn())
            print(name, os.path.getsize(os.path.join(OUT, name)))


if __name__ == "__main__":
    main()
