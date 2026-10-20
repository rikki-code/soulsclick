"""Authoring helpers for the silhouette enemy pack (not shipped: _src has a .gdignore).

Parts are drawn in a local frame whose origin is the part's pivot, then cropped to their bounding box.
Rest pose = every part unrotated; `idle` and the other poses are offsets from it.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "..", "..", "tools"))
import rig_preview as rp  # noqa: E402

DARK = "#0a0c10"
DARK2 = "#141922"
RIM = "#2f3947"
HI = "#7686a0"


def n(v):
    s = "%.1f" % v
    return s[:-2] if s.endswith(".0") else s


def mirror(pts):
    return [(-x, y) for x, y in pts]


class Art:
    def __init__(self):
        self.items = []
        self.xs = []
        self.ys = []

    def _track(self, pts, margin):
        for x, y in pts:
            self.xs += [x - margin, x + margin]
            self.ys += [y - margin, y + margin]

    def poly(self, pts, fill=DARK, stroke=RIM, sw=2, opacity=None):
        d = "M" + " L".join("%s %s" % (n(x), n(y)) for x, y in pts) + " Z"
        self._add(d, pts, fill, stroke, sw, opacity)

    def smooth(self, pts, fill=DARK, stroke=RIM, sw=2, closed=True, t=1.0, opacity=None):
        P = list(pts)
        m = len(P)
        segs = []
        for i in range(m if closed else m - 1):
            p0 = P[(i - 1) % m] if closed or i > 0 else P[0]
            p1 = P[i]
            p2 = P[(i + 1) % m]
            p3 = P[(i + 2) % m] if closed or i + 2 < m else P[-1]
            c1 = (p1[0] + (p2[0] - p0[0]) / 6 * t, p1[1] + (p2[1] - p0[1]) / 6 * t)
            c2 = (p2[0] - (p3[0] - p1[0]) / 6 * t, p2[1] - (p3[1] - p1[1]) / 6 * t)
            segs.append("C%s %s %s %s %s %s" % (n(c1[0]), n(c1[1]), n(c2[0]), n(c2[1]), n(p2[0]), n(p2[1])))
        d = "M%s %s " % (n(P[0][0]), n(P[0][1])) + " ".join(segs) + (" Z" if closed else "")
        self._add(d, pts, fill, stroke if closed or stroke else stroke, sw, opacity, closed)

    def _add(self, d, pts, fill, stroke, sw, opacity, closed=True):
        self._track(pts, sw + 6)
        attrs = 'd="%s" fill="%s"' % (d, fill if closed else "none")
        if stroke:
            attrs += ' stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % (stroke, n(sw))
        if opacity is not None:
            attrs += ' opacity="%s"' % opacity
        self.items.append("<path %s/>" % attrs)

    def line(self, pts, color=HI, sw=2, opacity=0.6, smooth=False):
        """Open stroke: rim light, edge glow, cracks."""
        if smooth:
            self.smooth(pts, fill="none", stroke=color, sw=sw, closed=False, opacity=opacity)
            return
        d = "M" + " L".join("%s %s" % (n(x), n(y)) for x, y in pts)
        self._track(pts, sw + 2)
        self.items.append('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round" '
                          'stroke-linecap="round" opacity="%s"/>' % (d, color, n(sw), opacity))

    def circle(self, cx, cy, r, fill=DARK, stroke=RIM, sw=2, opacity=None):
        self._track([(cx - r, cy - r), (cx + r, cy + r)], sw + 2)
        a = 'cx="%s" cy="%s" r="%s" fill="%s"' % (n(cx), n(cy), n(r), fill)
        if stroke:
            a += ' stroke="%s" stroke-width="%s"' % (stroke, n(sw))
        if opacity is not None:
            a += ' opacity="%s"' % opacity
        self.items.append("<circle %s/>" % a)

    def ellipse(self, cx, cy, rx, ry, fill=DARK, stroke=RIM, sw=2, rot=0, opacity=None):
        r = max(rx, ry)
        self._track([(cx - r, cy - r), (cx + r, cy + r)], sw + 2)
        a = 'cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"' % (n(cx), n(cy), n(rx), n(ry), fill)
        if stroke:
            a += ' stroke="%s" stroke-width="%s"' % (stroke, n(sw))
        if rot:
            a += ' transform="rotate(%s %s %s)"' % (n(rot), n(cx), n(cy))
        if opacity is not None:
            a += ' opacity="%s"' % opacity
        self.items.append("<ellipse %s/>" % a)

    def bbox(self):
        return (math.floor(min(self.xs)), math.floor(min(self.ys)), math.ceil(max(self.xs)), math.ceil(max(self.ys)))


class Rig:
    def __init__(self, enemy_id, accent):
        self.id = enemy_id
        self.accent = accent
        self.defs = []  # (id, parent, pivot_world, z, Art)
        self.glow = []
        self.poses = {}
        self.rig = None

    def part(self, pid, parent, pivot, z, art, glow=False):
        self.defs.append((pid, parent, pivot, z, art))
        if glow:
            self.glow.append(pid)

    def build_layout(self, out_dir):
        os.makedirs(out_dir, exist_ok=True)
        info = {}
        parts = []
        for pid, parent, pivot, z, art in self.defs:
            x0, y0, x1, y1 = art.bbox()
            info[pid] = dict(world=pivot, off=(-x0, -y0))
            w, h = x1 - x0, y1 - y0
            svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
                   '<g transform="translate(%d %d)">%s</g></svg>\n' % (w, h, w, h, -x0, -y0, "".join(art.items)))
            with open(os.path.join(out_dir, pid + ".svg"), "w") as f:
                f.write(svg)
            if len(svg) > 30000:
                print("WARN %s.svg is %d bytes" % (pid, len(svg)))
            if parent:
                pw, po = info[parent]["world"], info[parent]["off"]
                at = [round(pivot[0] - pw[0] + po[0], 1), round(pivot[1] - pw[1] + po[1], 1)]
            else:
                at = [pivot[0], pivot[1]]
            parts.append({"id": pid, "file": pid + ".svg", "parent": parent,
                          "pivot": [info[pid]["off"][0], info[pid]["off"][1]], "at": at, "z": z})
        self.rig = {"accent": self.accent, "canvas": [1024, 1024], "parts": parts, "poses": {},
                    "glow_parts": self.glow}
        self.rig["_parts"] = {p["id"]: p for p in parts}
        self.out_dir = out_dir
        return self.rig

    def new_pose(self):
        return Pose(self)

    def write_rig(self):
        for name, pose in self.poses.items():
            self.rig["poses"][name] = pose.export()
        out = {k: v for k, v in self.rig.items() if not k.startswith("_")}
        text = json.dumps(out, indent=1)
        # keep pose entries on one line each for readability
        with open(os.path.join(self.out_dir, "rig.json"), "w") as f:
            f.write(text + "\n")


class Pose:
    def __init__(self, rigobj):
        self.r = rigobj
        self.data = {}

    # compat with rig_preview FK: acts like the dict of part -> {rot, move}
    def set(self, part, rot=0.0, move=(0, 0)):
        self.data[part] = {"rot": rot, "move": list(move)}
        return self

    def fk_rig(self):
        return self.r.rig

    def wrot(self, part):
        m = rp.part_world(self.r.rig, part, self.data)
        return math.degrees(math.atan2(m[1], m[0]))

    def pivot(self, part):
        return rp.pivot_world(self.r.rig, part, self.data)

    def arm(self, upper, fore, target, L1, L2, bend):
        """2-bone IK: hand centre of `fore` (local (0, L2)) onto target (canvas pixels)."""
        S = self.pivot(upper)
        dx, dy = target[0] - S[0], target[1] - S[1]
        d = math.hypot(dx, dy)
        d = max(min(d, L1 + L2 - 0.5), abs(L1 - L2) + 0.5)
        base = math.atan2(dy, dx)
        cosA = (L1 * L1 + d * d - L2 * L2) / (2 * L1 * d)
        A = math.acos(max(-1, min(1, cosA)))
        e = base + bend * A
        E = (S[0] + L1 * math.cos(e), S[1] + L1 * math.sin(e))
        h = math.atan2(target[1] - E[1], target[0] - E[0])
        parent = self.r.rig["_parts"][upper]["parent"]
        prot = self.wrot(parent) if parent else 0.0
        a1 = math.degrees(e) - 90
        a2 = math.degrees(h) - 90
        self.set(upper, a1 - prot)
        self.set(fore, a2 - a1)

    def hold(self, weapon_part, fore, blade_deg):
        """Blade world angle: 0 = up, clockwise positive (weapon art points up at rest)."""
        self.set(weapon_part, blade_deg - self.wrot(fore))

    def export(self):
        out = {}
        for pid in self.r.rig["_parts"]:
            d = self.data.get(pid, {"rot": 0, "move": [0, 0]})
            out[pid] = {"rot": round(d["rot"], 1), "move": [round(d["move"][0], 1), round(d["move"][1], 1)]}
        return out


def make_pose_fn(R, L1, L2, extra_parts=()):
    """Returns pose(name, body, head, legs, hr, hl, blade, bend_r, bend_l, grip_l, extra)."""
    def pose(name, body=(0, 0, 0), head=0, legs=(0, 0, 0), hr=None, hl=None, blade=0, bend_r=-1, bend_l=1,
             grip_l=None, extra=None, hmove=(0, 0)):
        p = R.new_pose()
        p.set("body", body[0], (body[1], body[2]))
        p.set("legs", legs[0], (legs[1], legs[2]))
        p.set("head", head, hmove)
        if hr:
            p.arm("arm_r", "forearm_r", hr, L1, L2, bend_r)
            p.hold("weapon", "forearm_r", blade)
        if grip_l is not None:
            wp = p.pivot("weapon")
            a = math.radians(blade)
            hl = (wp[0] + math.sin(a) * grip_l, wp[1] - math.cos(a) * grip_l)
        if hl:
            p.arm("arm_l", "forearm_l", hl, L1, L2, bend_l)
        if extra:
            for k, v in extra.items():
                p.set(k, *v)
        R.poses[name] = p
        return p
    return pose
