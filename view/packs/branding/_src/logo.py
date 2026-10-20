"""Angular block letterforms as stroked paths (no <text>), logo group builder."""
EMBER = "#f08a3a"
BONE = "#ece3d3"
INK = "#05070a"

# centerline polylines on a grid: height 6, width given. (points, closed)
def P(*pts, closed=False):
    return (list(pts), closed)

E_ = [P((4, 0), (0, 0), (0, 6), (4, 6)), P((0, 3), (3, 3))]
R_ = [P((0, 6), (0, 0), (3, 0), (4, 1), (4, 2), (3, 3), (0, 3)), P((2, 3), (4, 6))]
K_ = [P((0, 0), (0, 6)), P((4, 0), (1, 3), (4, 6))]
GL = {
    "S": (4, [P((4, 0), (1, 0), (0, 1), (0, 2), (1, 3), (3, 3), (4, 4), (4, 5), (3, 6), (0, 6))]),
    "O": (4, [P((1, 0), (3, 0), (4, 1), (4, 5), (3, 6), (1, 6), (0, 5), (0, 1), closed=True)]),
    "U": (4, [P((0, 0), (0, 5), (1, 6), (3, 6), (4, 5), (4, 0))]),
    "L": (4, [P((0, 0), (0, 6), (4, 6))]),
    "C": (4, [P((4, 0), (1, 0), (0, 1), (0, 5), (1, 6), (4, 6))]),
    "I": (4, [P((2, 0), (2, 6)), P((0.6, 0), (3.4, 0)), P((0.6, 6), (3.4, 6))]),
    "K": (4, K_),
    "E": (4, E_),
    "R": (4, R_),
    "К": (4, K_),
    "Л": (4, [P((0, 6), (1, 5), (1, 0), (4, 0), (4, 6))]),
    "И": (4, [P((0, 0), (0, 6)), P((4, 0), (4, 6)), P((0, 6), (4, 0))]),
    "Е": (4, E_),
    "Р": (4, [P((0, 6), (0, 0), (3, 0), (4, 1), (4, 2), (3, 3), (0, 3))]),
    "Д": (5, [P((4.6, 6), (4.6, 0), (1.4, 0), (0.6, 6)), P((-0.2, 6), (5.2, 6)),
                   P((-0.2, 6), (-0.2, 7.4)), P((5.2, 6), (5.2, 7.4))]),
    "У": (4, [P((0, 0), (2, 3.6), (4, 0)), P((2, 3.6), (0.8, 6.4))]),
    "Ш": (6, [P((0, 0), (0, 6), (6, 6), (6, 0)), P((3, 0), (3, 6))]),
}
TEXT = {"en": ["SOULS", "CLICKER"], "ru": ["КЛИКЕР", "ДУШ"]}


def _path(pts, closed, u, ox, oy):
    d = "M" + " L".join("%.1f %.1f" % (ox + x * u, oy + y * u) for x, y in pts)
    return d + (" Z" if closed else "")


def word_width(word, u, gap=1.1, t=1.0):
    return sum(GL[c][0] * u + t * u + gap * u for c in word) - gap * u


def logo_group(lang, uid="lg", u=27.0, W=1600, H=500):
    """Returns SVG markup in a WxH box (transparent)."""
    t = 1.0 * u
    gap = 1.1
    lines = TEXT[lang]
    h_line = 6 * u + t
    gap_y = 1.9 * u
    total = h_line * 2 + gap_y
    y0 = (H - total) / 2 + t / 2 + (0 if lang == "en" else 0)
    out, defs = [], []
    for li, word in enumerate(lines):
        ww = word_width(word, u, gap)
        x = (W - ww) / 2 + t / 2
        yt = y0 + li * (h_line + gap_y)
        gid = "%s_g%d" % (uid, li)
        defs.append('<linearGradient id="%s" gradientUnits="userSpaceOnUse" x1="0" y1="%.1f" x2="0" y2="%.1f">'
                    '<stop offset="0" stop-color="%s"/><stop offset="0.55" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
                    % (gid, yt - t / 2, yt + 6 * u + t / 2, BONE, "#e9cfa8", EMBER))
        ds = []
        for ch in word:
            w, strokes = GL[ch]
            for pts, closed in strokes:
                ds.append(_path(pts, closed, u, x, yt))
            x += w * u + t + gap * u
        d = " ".join(ds)
        out.append('<path d="%s" fill="none" stroke="%s" stroke-opacity="0.07" stroke-width="%.1f" stroke-linejoin="round"/>' % (d, EMBER, t + 40))
        out.append('<path d="%s" fill="none" stroke="%s" stroke-opacity="0.14" stroke-width="%.1f" stroke-linejoin="round"/>' % (d, EMBER, t + 22))
        out.append('<path d="%s" fill="none" stroke="%s" stroke-width="%.1f" stroke-linejoin="miter" stroke-miterlimit="6"/>' % (d, INK, t + 14))
        out.append('<path d="%s" fill="none" stroke="url(#%s)" stroke-width="%.1f" stroke-linejoin="miter" stroke-miterlimit="6"/>' % (d, gid, t))
        if li == 0:  # blade ornaments flanking the first line
            cy = yt + 3 * u
            left_end = (W - ww) / 2 - 36
            right_start = (W + ww) / 2 + 36
            span = min(300, left_end - 50)
            for sgn, a in ((-1, left_end), (1, right_start)):
                tip = a - 0 if sgn < 0 else a
                far = a - sgn * span if sgn < 0 else a + span
                # tapered blade pointing away from the word, pommel diamond near the word
                if sgn < 0:
                    pts = [(a, cy - 9), (a - span, cy), (a, cy + 9)]
                    pom = (a + 12, cy)
                else:
                    pts = [(a, cy - 9), (a + span, cy), (a, cy + 9)]
                    pom = (a - 12, cy)
                pp = " ".join("%.1f,%.1f" % p for p in pts)
                out.append('<polygon points="%s" fill="%s"/>' % (pp, EMBER))
                px, py = pom
                out.append('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="%s"/>' % (
                    px - 12, py, px, py - 16, px + 12, py, px, py + 16, EMBER))
    return '<defs>%s</defs>%s' % ("".join(defs), "\n".join(out))


def logo_svg(lang):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="500" viewBox="0 0 1600 500">\n%s\n</svg>\n'
            % logo_group(lang))
