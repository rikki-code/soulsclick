"""Generator + preview for the player-hands silhouette pack (not shipped: _src has a .gdignore).

  python3 _src/build.py            # writes hands/*.svg + rig.json, shields/*.svg, weapons/*.svg, gear.json, previews
  python3 _src/build.py --no-preview

Frame: parts are drawn in canvas coordinates minus their pivot (like the enemy rigs), then cropped to the bbox.
Canvas 1080x1920. Rest pose: arm/forearm directions of a low guard, hands upright (fists open upward, gear
points up). Angles in poses: degrees clockwise from "up".
"""
import json
import math
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.dirname(HERE)
PROJECT = os.path.normpath(os.path.join(PACK, "..", "..", "..", ".."))
GODOT = os.environ.get("GODOT", "/Users/vladimirafanasev/dev/godot/bin/godot.macos.editor.arm64")

W, H = 1080, 1920
ACCENT = "#e6a65d"  # warm steel / ember: player-only, never used by enemies
DARK, DARK2, RIM, HI = "#0a0c10", "#141922", "#2f3947", "#7686a0"
L1, L2 = 620.0, 620.0
DIST = 1130.0  # shoulder -> wrist; shoulders slide with the hand (arm `move`) so arms enter steeply from the bottom
FIST_C = 88.0  # wrist pivot -> fist center (grip point), along the hand's up axis

POSES = {  # per hand: fist centre x, y, hand angle (deg clockwise from up), arm direction phi (deg from up, up-right +)
    "idle":         {"l": (230, 1650, 0, 22),   "r": (870, 1690, -10, -22)},
    "block":        {"l": (400, 1350, 6, 18),   "r": (890, 1740, -4, -22)},
    "parry":        {"l": (470, 1230, 24, 26),  "r": (900, 1760, 0, -22)},
    "attack":       {"l": (200, 1720, -6, 22),  "r": (610, 1210, -55, -48)},
    "hurt":         {"l": (190, 1760, -10, 22), "r": (910, 1780, 10, -22)},
    "guard_broken": {"l": (20, 1560, -62, 8),   "r": (850, 1700, -12, -22)},
    "staggered":    {"l": (90, 1480, -35, 12),  "r": (990, 1500, 40, -12)},
}


def n(v):
    s = "%.1f" % v
    return s[:-2] if s.endswith(".0") else s


class Art:
    def __init__(self, k=1.0):
        self.items, self.xs, self.ys, self.k = [], [], [], k

    def _t(self, pts, m):
        for x, y in pts:
            self.xs += [x - m, x + m]
            self.ys += [y - m, y + m]

    def poly(self, pts, fill=DARK, stroke=RIM, sw=3, op=None):
        d = "M" + " L".join("%s %s" % (n(x), n(y)) for x, y in pts) + " Z"
        self._t(pts, sw + 2)
        self.items.append('<path d="%s" fill="%s"%s%s/>' % (d, fill, self._s(stroke, sw), self._o(op)))

    def smooth(self, pts, fill=DARK, stroke=RIM, sw=3, op=None):
        P, m, segs = list(pts), len(pts), []
        for i in range(m):
            p0, p1, p2, p3 = P[(i - 1) % m], P[i], P[(i + 1) % m], P[(i + 2) % m]
            c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
            c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
            segs.append("C%s %s %s %s %s %s" % (n(c1[0]), n(c1[1]), n(c2[0]), n(c2[1]), n(p2[0]), n(p2[1])))
        self._t(pts, sw + 6)
        self.items.append('<path d="M%s %s %s Z" fill="%s"%s%s/>' % (n(P[0][0]), n(P[0][1]), " ".join(segs), fill, self._s(stroke, sw), self._o(op)))

    def line(self, pts, color=HI, sw=3, op=0.6):
        d = "M" + " L".join("%s %s" % (n(x), n(y)) for x, y in pts)
        self._t(pts, sw + 2)
        self.items.append('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round" opacity="%s"/>' % (d, color, n(sw), op))

    def circle(self, cx, cy, r, fill=DARK, stroke=RIM, sw=3, op=None):
        self._t([(cx - r, cy - r), (cx + r, cy + r)], sw + 2)
        self.items.append('<circle cx="%s" cy="%s" r="%s" fill="%s"%s%s/>' % (n(cx), n(cy), n(r), fill, self._s(stroke, sw), self._o(op)))

    def ellipse(self, cx, cy, rx, ry, fill=DARK, stroke=RIM, sw=3, op=None):
        self._t([(cx - rx, cy - ry), (cx + rx, cy + ry)], sw + 2)
        self.items.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"%s%s/>' % (n(cx), n(cy), n(rx), n(ry), fill, self._s(stroke, sw), self._o(op)))

    @staticmethod
    def _s(stroke, sw):
        return ' stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % (stroke, n(sw)) if stroke else ""

    @staticmethod
    def _o(op):
        return ' opacity="%s"' % op if op is not None else ""

    def save(self, path):
        k = self.k
        x0, y0 = math.floor(min(self.xs) * k), math.floor(min(self.ys) * k)
        x1, y1 = math.ceil(max(self.xs) * k), math.ceil(max(self.ys) * k)
        w, h = x1 - x0, y1 - y0
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
               '<g transform="translate(%d %d) scale(%s)">%s</g></svg>\n' % (w, h, w, h, -x0, -y0, k, "".join(self.items)))
        with open(path, "w") as f:
            f.write(svg)
        return (-x0, -y0), (w, h), len(svg)


def mirror(pts):
    return [(-x, y) for x, y in pts]


# ---------- hand rig ----------
def shoulder_for(wrist, phi):
    a = math.radians(phi)
    return (wrist[0] - DIST * math.sin(a), wrist[1] + DIST * math.cos(a))


def solve_arm(S, wrist, ha):
    """2-bone IK. Returns (elbow, abs upper angle, abs fore angle), angles in degrees clockwise from up.
    Elbow is chosen on the outer side (left arm: smaller x, right arm: larger x)."""
    dx, dy = wrist[0] - S[0], wrist[1] - S[1]
    d = max(min(math.hypot(dx, dy), L1 + L2 - 1), abs(L1 - L2) + 1)
    base = math.atan2(dy, dx)
    A = math.acos(max(-1, min(1, (L1 * L1 + d * d - L2 * L2) / (2 * L1 * d))))
    best = None
    for bend in (-1, 1):
        e = base + bend * A
        E = (S[0] + L1 * math.cos(e), S[1] + L1 * math.sin(e))
        h = math.degrees(math.atan2(wrist[1] - E[1], wrist[0] - E[0])) + 90
        score = -abs(h - ha)  # forearm closest to the hand direction
        if best is None or score > best[0]:
            best = (score, E, e)
    _, E, e = best
    h = math.atan2(wrist[1] - E[1], wrist[0] - E[0])
    return E, math.degrees(e) + 90, math.degrees(h) + 90


def wrist_for(c, ha):
    a = math.radians(ha)
    return (c[0] - FIST_C * math.sin(a), c[1] + FIST_C * math.cos(a))


def limb(art, p0, p1, w0, w1, rim_side):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    ln = math.hypot(dx, dy)
    nx, ny = -dy / ln, dx / ln
    a = [(p0[0] + nx * w0 / 2, p0[1] + ny * w0 / 2), (p0[0] - nx * w0 / 2, p0[1] - ny * w0 / 2)]
    b = [(p1[0] - nx * w1 / 2, p1[1] - ny * w1 / 2), (p1[0] + nx * w1 / 2, p1[1] + ny * w1 / 2)]
    art.poly([a[0], a[1], b[0], b[1]], DARK, RIM, 3)
    # rim light on the outer edge
    s = 1 if rim_side == "l" else -1
    k = s * -1
    q0 = (p0[0] + nx * w0 / 2 * k * -1 * -1, p0[1] + ny * w0 / 2 * k * -1 * -1)
    return nx, ny


def build_hands(rest, out):
    arts, info = {}, {}
    for side in ("l", "r"):
        S = rest[side]["S"]
        E, W_ = rest[side]["E"], rest[side]["W"]
        sgn = -1 if side == "l" else 1  # outer side x sign
        # upper arm (local frame = canvas - shoulder)
        a = Art()
        up = lambda p: (p[0] - S[0], p[1] - S[1])
        e = up(E)
        _sleeve(a, (0, 0), e, 300, 215, sgn)
        a.circle(e[0], e[1], 108, DARK2, RIM, 3)
        a.line([(e[0] - sgn * 40, e[1] - 20), (e[0] - sgn * 6, e[1] - 62)], HI, 4, 0.45)
        arts["arm_" + side] = (a, S)
        # forearm: bracer
        f = Art()
        w = (W_[0] - E[0], W_[1] - E[1])
        _sleeve(f, (0, 0), w, 215, 150, sgn)
        ln = math.hypot(*w)
        u = (w[0] / ln, w[1] / ln)
        nn = (-u[1], u[0])
        c0, c1 = (w[0] - u[0] * 120, w[1] - u[1] * 120), (w[0] - u[0] * 28, w[1] - u[1] * 28)
        for c, ww in ((c0, 150), (c1, 138)):
            pass
        f.poly([(c0[0] + nn[0] * 98, c0[1] + nn[1] * 98), (c0[0] - nn[0] * 98, c0[1] - nn[1] * 98),
                (c1[0] - nn[0] * 86, c1[1] - nn[1] * 86), (c1[0] + nn[0] * 86, c1[1] + nn[1] * 86)], DARK2, RIM, 3)
        f.line([(c0[0] + nn[0] * 90, c0[1] + nn[1] * 90), (c0[0] - nn[0] * 90, c0[1] - nn[1] * 90)], ACCENT, 7, 0.9)
        f.line([(c1[0] + nn[0] * 78, c1[1] + nn[1] * 78), (c1[0] - nn[0] * 78, c1[1] - nn[1] * 78)], ACCENT, 5, 0.6)
        f.circle(w[0], w[1], 78, DARK2, RIM, 3)
        arts["forearm_" + side] = (f, E)
        # hand: upright gauntlet fist, pivot at the wrist
        h = Art(1.25)
        thumb = -sgn  # thumb on the inner side
        h.poly([(-74, 18), (-68, -12), (68, -12), (74, 18)], DARK2, RIM, 3)  # cuff
        h.line([(-66, 4), (66, 4)], ACCENT, 6, 0.85)
        h.smooth([(-60, -14), (-70, -52), (-68, -108), (-42, -140), (42, -140), (68, -108), (70, -52), (60, -14)], DARK, RIM, 3)
        for y in (-52, -82, -112):
            h.line([(-56, y), (56, y)], HI, 3, 0.32)
        h.smooth([(thumb * 52, -118), (thumb * 80, -104), (thumb * 78, -64), (thumb * 54, -60)], DARK2, RIM, 3)
        h.line([(-sgn * 52, -134), (-sgn * 20, -140)], HI, 4, 0.55)
        arts["hand_" + side] = (h, W_)
    z = {"arm_l": 10, "forearm_l": 11, "hand_l": 13, "arm_r": 20, "forearm_r": 21, "hand_r": 23}
    parent = {"arm_l": "", "forearm_l": "arm_l", "hand_l": "forearm_l", "arm_r": "", "forearm_r": "arm_r", "hand_r": "forearm_r"}
    world_pivot = {"arm_l": rest["l"]["S"], "arm_r": rest["r"]["S"]}
    for s in "lr":
        world_pivot["forearm_" + s] = rest[s]["E"]
        world_pivot["hand_" + s] = rest[s]["W"]
    parts = []
    offs = {}
    for pid in ["arm_l", "forearm_l", "hand_l", "arm_r", "forearm_r", "hand_r"]:
        art, piv = arts[pid]
        off, size, nb = art.save(os.path.join(out, pid + ".svg"))
        offs[pid] = off
        if nb > 30000:
            print("WARN %s %d bytes" % (pid, nb))
        p = parent[pid]
        if p:
            pw = world_pivot[p]
            at = [round(piv[0] - pw[0] + offs[p][0], 1), round(piv[1] - pw[1] + offs[p][1], 1)]
        else:
            at = [piv[0], piv[1]]
        parts.append({"id": pid, "file": pid + ".svg", "parent": p, "pivot": list(off), "at": at, "z": z[pid]})
    return parts, offs


def _sleeve(art, p0, p1, w0, w1, sgn):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    ln = math.hypot(dx, dy)
    nx, ny = -dy / ln, dx / ln
    L = [(p0[0] + nx * w0 / 2, p0[1] + ny * w0 / 2), (p1[0] + nx * w1 / 2, p1[1] + ny * w1 / 2)]
    R = [(p0[0] - nx * w0 / 2, p0[1] - ny * w0 / 2), (p1[0] - nx * w1 / 2, p1[1] - ny * w1 / 2)]
    art.poly([L[0], L[1], R[1], R[0]], DARK, RIM, 3)
    # rim light on the edge that faces up-left (the one with the smaller x)
    edge = L if (L[0] + L[1]) < (R[0] + R[1]) else R
    art.line([(edge[0][0] + (p1[0] - p0[0]) * 0.1, edge[0][1] + (p1[1] - p0[1]) * 0.1),
              (edge[1][0] - (p1[0] - p0[0]) * 0.05, edge[1][1] - (p1[1] - p0[1]) * 0.05)], HI, 4, 0.5)


def make_rig(out):
    # rest geometry from the idle pose
    rest = {}
    for s in "lr":
        cx, cy, ha, phi = POSES["idle"][s]
        wr = wrist_for((cx, cy), ha)
        S = shoulder_for(wr, phi)
        E, a1, a2 = solve_arm(S, wr, ha)
        rest[s] = {"S": S, "E": E, "W": wr, "a1": a1, "a2": a2}
    parts, offs = build_hands(rest, out)
    poses = {}
    for name, spec in POSES.items():
        pose = {}
        for s in "lr":
            cx, cy, ha, phi = spec[s]
            wr = wrist_for((cx, cy), ha)
            S = shoulder_for(wr, phi)
            E, a1, a2 = solve_arm(S, wr, ha)
            r1 = a1 - rest[s]["a1"]
            r2 = a2 - rest[s]["a2"] - r1
            r3 = ha - r1 - r2
            pose["arm_" + s] = {"rot": round(r1, 1), "move": [round(S[0] - rest[s]["S"][0], 1), round(S[1] - rest[s]["S"][1], 1)]}
            pose["forearm_" + s] = {"rot": round(r2, 1), "move": [0, 0]}
            pose["hand_" + s] = {"rot": round(r3, 1), "move": [0, 0]}
        poses[name] = pose
    fist = [offs["hand_l"][0], offs["hand_l"][1] - FIST_C]
    fist_r = [offs["hand_r"][0], offs["hand_r"][1] - FIST_C]
    rig = {"accent": ACCENT, "canvas": [W, H], "parts": parts, "poses": poses, "glow_parts": [],
           "slots": {"shield": {"parent": "hand_l", "at": fist, "z": 14},
                     "weapon": {"parent": "hand_r", "at": fist_r, "z": 22}}}
    with open(os.path.join(out, "rig.json"), "w") as f:
        json.dump(rig, f, indent=1)
        f.write("\n")
    return rig


# ---------- gear (drawn upright, origin = grip point) ----------
def rim_glow(a, pts, sw=7, op=0.95):
    a.line(pts, ACCENT, sw, op)


def shield_buckler(a):
    a.circle(0, 0, 140, DARK, RIM, 4)
    a.circle(0, 0, 118, DARK2, RIM, 2)
    a.circle(0, 0, 130, "none", ACCENT, 7, 0.95)
    a.circle(0, 0, 46, DARK, HI, 3, 0.9)
    a.circle(0, 0, 22, DARK2, RIM, 2)
    for k in range(8):
        t = math.radians(k * 45 + 22.5)
        a.circle(95 * math.cos(t), 95 * math.sin(t), 6, DARK, HI, 2, 0.8)
    a.line([(-118, -40), (-88, -92), (-40, -118)], HI, 4, 0.55)


def shield_kite(a):
    out = [(0, -230), (150, -190), (156, -70), (112, 90), (0, 250), (-112, 90), (-156, -70), (-150, -190)]
    a.smooth(out, DARK, RIM, 4)
    inner = [(0, -205), (130, -172), (136, -64), (98, 78), (0, 222), (-98, 78), (-136, -64), (-130, -172)]
    a.smooth(inner, DARK2, RIM, 2)
    a.smooth([(0, -216), (142, -180), (146, -68), (106, 84), (0, 236), (-106, 84), (-146, -68), (-142, -180)], "none", ACCENT, 7, 0.95)
    a.poly([(-14, -190), (14, -190), (14, 200), (-14, 200)], DARK, HI, 2, 0.9)
    a.line([(0, -190), (0, 200)], HI, 3, 0.4)
    a.line([(-136, -70), (136, -70)], HI, 3, 0.35)
    a.circle(0, -70, 34, DARK, HI, 3)
    a.circle(0, -70, 14, DARK2, RIM, 2)
    a.line([(-126, -150), (-60, -196)], HI, 4, 0.55)


def shield_tower(a):
    out = [(-266, -300), (-220, -340), (220, -340), (266, -300), (270, 300), (240, 480), (0, 560), (-240, 480), (-270, 300)]
    a.poly(out, DARK, RIM, 4)
    a.poly([(-238, -296), (-208, -318), (208, -318), (238, -296), (242, 296), (216, 454), (0, 528), (-216, 454), (-242, 296)], DARK2, RIM, 2)
    a.poly([(-258, -296), (-216, -330), (216, -330), (258, -296), (262, 296), (234, 470), (0, 546), (-234, 470), (-262, 296)], "none", ACCENT, 8, 0.95) if False else None
    a.line([(-262, 280), (-258, -296), (-216, -330), (216, -330), (258, -296), (262, 280)], ACCENT, 8, 0.95)
    for x in (-130, 130):
        a.poly([(x - 12, -318), (x + 12, -318), (x + 12, 470), (x - 12, 470)], DARK, RIM, 2)
        a.line([(x - 6, -310), (x - 6, 440)], HI, 3, 0.35)
    a.poly([(-250, -150), (250, -150), (250, -112), (-250, -112)], DARK, RIM, 2)
    a.poly([(-250, 190), (250, 190), (250, 228), (-250, 228)], DARK, RIM, 2)
    a.line([(-244, -150), (244, -150)], HI, 3, 0.4)
    a.circle(0, 0, 54, DARK, HI, 4)
    a.circle(0, 0, 26, DARK2, RIM, 2)
    for x in (-200, -66, 66, 200):
        for y in (-131, 209):
            a.circle(x, y, 7, DARK2, HI, 2, 0.8)
    a.line([(-230, -270), (-196, -318)], HI, 4, 0.55)


def blade(a, half_w, tip, base, guard_y, guard_w, grip_y0, grip_y1, pommel_r, fuller=True, belly=0.0):
    """Upright sword: blade from base (y, small) to tip (y, more negative); grip below the guard."""
    b = [(-half_w, base), (-half_w * (1 - belly), base + (tip - base) * 0.55), (0, tip), (half_w * (1 - belly), base + (tip - base) * 0.55), (half_w, base)]
    a.poly(b, DARK, RIM, 3)
    a.line([(-half_w + 4, base), (-half_w * (1 - belly) + 3, base + (tip - base) * 0.55), (0, tip + 4)], ACCENT, 7, 0.95)
    a.line([(half_w - 4, base), (half_w * (1 - belly) - 3, base + (tip - base) * 0.55), (0, tip + 4)], ACCENT, 7, 0.95)
    if fuller:
        a.line([(0, base - 6), (0, tip + 40)], HI, 3, 0.5)
    a.poly([(-grip_w(guard_w), guard_y - 10), (grip_w(guard_w), guard_y - 10), (guard_w / 2, guard_y + 12), (-guard_w / 2, guard_y + 12)], DARK2, RIM, 3)
    a.poly([(-18, grip_y0), (18, grip_y0), (16, grip_y1), (-16, grip_y1)], DARK2, RIM, 3)
    for y in range(int(grip_y0 + 14), int(grip_y1 - 10), 24):
        a.line([(-16, y), (16, y + 10)], HI, 3, 0.35)
    a.circle(0, grip_y1 + pommel_r - 4, pommel_r, DARK2, RIM, 3)


def grip_w(g):
    return g / 2 + 6


def weapon_dagger(a):
    blade(a, 30, -330, -60, -60, 140, -48, 90, 17, belly=0.15)


def weapon_sword(a):
    blade(a, 38, -740, -66, -66, 200, -54, 120, 21, belly=0.1)


def weapon_greatsword(a):
    blade(a, 56, -1060, -72, -72, 290, -60, 230, 28, belly=0.08)
    a.poly([(-20, -90), (20, -90), (20, -62), (-20, -62)], DARK2, RIM, 2)


GEAR = {
    "shields": {"buckler": shield_buckler, "kite": shield_kite, "tower": shield_tower},
    "weapons": {"dagger": weapon_dagger, "sword": weapon_sword, "greatsword": weapon_greatsword},
}
GEAR_K = {"buckler": 1.25, "kite": 1.25, "tower": 1.15, "dagger": 1.2, "sword": 1.2, "greatsword": 1.1}
GEAR_NOTES = {
    "buckler": "small round; fist hides behind the boss", "kite": "medium; pivot at the grip behind the boss",
    "tower": "huge; raised it hides the enemy from y~1010 down (eyes/head stay visible)",
    "dagger": "short, fast", "sword": "one-hand", "greatsword": "two-hand length, blade reaches y~700 from idle",
}


def build_gear():
    gear = {}
    for kind, items in GEAR.items():
        gear[kind] = {}
        for gid, fn in items.items():
            a = Art(GEAR_K[gid])
            fn(a)
            off, size, nb = a.save(os.path.join(PACK, kind, gid + ".svg"))
            gear[kind][gid] = {"file": "%s/%s.svg" % (kind, gid), "pivot": list(off), "size": list(size),
                               "glow": True, "note": GEAR_NOTES[gid]}
            if nb > 30000:
                print("WARN %s %d bytes" % (gid, nb))
    with open(os.path.join(PACK, "gear.json"), "w") as f:
        json.dump(gear, f, indent=1)
        f.write("\n")
    return gear


# ---------- preview ----------
def mm(m, n_):
    a, b, c, d, e, f = m
    A, B, C, D, E, F = n_
    return (a * A + c * B, b * A + d * B, a * C + c * D, b * C + d * D, a * E + c * F + e, b * E + d * F + f)


def local_m(p, d):
    mv = d.get("move", [0, 0])
    r = math.radians(d.get("rot", 0))
    return mm(mm((1, 0, 0, 1, p["at"][0] + mv[0], p["at"][1] + mv[1]), (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0)),
              (1, 0, 0, 1, -p["pivot"][0], -p["pivot"][1]))


def inner(path):
    t = open(path).read()
    return re.search(r"<svg[^>]*>(.*)</svg>", t, flags=re.S).group(1)


def compose(rig, gear, pose_id, shield, weapon):
    pose = rig["poses"][pose_id]
    parts = {p["id"]: dict(p) for p in rig["parts"]}
    files = {pid: os.path.join(PACK, "hands", p["file"]) for pid, p in parts.items()}
    for slot, kind, gid in (("shield", "shields", shield), ("weapon", "weapons", weapon)):
        s, g = rig["slots"][slot], gear[kind][gid]
        pid = "gear_" + slot
        parts[pid] = {"id": pid, "parent": s["parent"], "at": s["at"], "pivot": g["pivot"], "z": s["z"]}
        files[pid] = os.path.join(PACK, g["file"])
    world = {}

    def wm(pid):
        if pid not in world:
            p = parts[pid]
            m = local_m(p, pose.get(pid, {}))
            world[pid] = mm(wm(p["parent"]), m) if p["parent"] else m
        return world[pid]
    out = []
    for pid in sorted(parts, key=lambda k: parts[k]["z"]):
        out.append('<g transform="matrix(%s)">%s</g>' % (" ".join("%.4f" % v for v in wm(pid)), inner(files[pid])))
    return "\n".join(out)


def sheet(rig, gear, shield, weapon, path, scale=0.3, cols=4):
    ids = list(POSES)
    rows = (len(ids) + cols - 1) // cols
    cw, ch = W * scale, H * scale
    body = []
    for i, pid in enumerate(ids):
        x, y = (i % cols) * cw, (i // cols) * ch
        body.append(
            '<clipPath id="c%d"><rect x="%.1f" y="%.1f" width="%.1f" height="%.1f"/></clipPath>'
            '<g clip-path="url(#c%d)"><g transform="translate(%.1f %.1f) scale(%s)">'
            '<rect width="%d" height="%d" fill="#222a37"/><rect x="0" y="1500" width="%d" height="420" fill="#1a212c"/>'
            '<rect x="190" y="600" width="700" height="900" fill="#ffffff" fill-opacity="0.05" stroke="#7686a0" stroke-opacity="0.35" stroke-width="3" stroke-dasharray="14 10"/>'
            '<ellipse cx="540" cy="760" rx="46" ry="14" fill="#5cb8ff" fill-opacity="0.35"/>%s</g></g>'
            % (i, x, y, cw, ch, i, x, y, scale, W, H, W, compose(rig, gear, pid, shield, weapon)))
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n%s\n</svg>\n' % (
        cw * cols, ch * rows, cw * cols, ch * rows, "\n".join(body))
    open(path, "w").write(svg)
    return path


def rasterize(jobs):
    lp = os.path.join(PACK, "_previews", ".jobs.txt")
    open(lp, "w").write("".join("%s\t%s\t1\n" % j for j in jobs))
    r = subprocess.run([GODOT, "--headless", "--path", PROJECT, "-s", "tools/svg_to_png.gd", "--", "--list", lp],
                       capture_output=True, text=True)
    os.remove(lp)
    for line in (r.stdout + r.stderr).splitlines():
        if "rror" in line:
            print(line)
    return r.returncode == 0


def lint(rig):
    bad = re.compile(r"<filter|<text|<image|<style|\bclass=|href=|<script|filter=")
    for d in ("hands", "shields", "weapons"):
        for fn in sorted(os.listdir(os.path.join(PACK, d))):
            if fn.endswith(".svg"):
                t = open(os.path.join(PACK, d, fn)).read()
                if bad.search(t) or len(t) > 30000:
                    print("LINT FAIL", d, fn)
    print("lint done")


COMBOS = [("buckler", "dagger"), ("kite", "sword"), ("tower", "greatsword")]

if __name__ == "__main__":
    rig = make_rig(os.path.join(PACK, "hands"))
    gear = build_gear()
    lint(rig)
    if "--no-preview" not in sys.argv:
        jobs = []
        for s, w in COMBOS:
            p = sheet(rig, gear, s, w, os.path.join(PACK, "_previews", "%s_%s.svg" % (s, w)))
            jobs.append((p, p[:-4] + ".png"))
        rasterize(jobs)
