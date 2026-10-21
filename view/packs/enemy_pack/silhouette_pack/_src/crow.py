from rigkit import *
from shapes import tube

# Carrion Crow: gaunt, forward-leaning, long neck, bald skull and long hooked beak (faces left),
# ragged bat-skeleton wings, long thin legs with big talons.
ACCENT = "#f2e46a"
H = (512, 790)
N = (432, 455)
WR, WL = (560, 545), (480, 545)


def wing(sx):
    w = Art()
    pts = [(0, -10), (90, -70), (210, -120), (330, -196), (312, -120), (372, -84), (320, -40), (340, 50), (270, 10),
           (256, 100), (190, 40), (150, 84), (100, 30), (30, 40)]
    w.poly([(x * sx, y) for x, y in pts], fill=DARK2, sw=1.5)
    for tx, ty in ((330, -196), (372, -84), (340, 50), (256, 100), (150, 84)):  # finger bones
        w.line([(210 * sx, -120), (tx * sx, ty)], sw=3, opacity=0.55, color=RIM)
    w.poly(tube([(0, 0), (90 * sx, -60), (210 * sx, -112)], 12, 8), fill=DARK, sw=1.5)
    w.circle(90 * sx, -62, 11, fill=DARK, sw=1.5)
    w.circle(210 * sx, -114, 12, fill=DARK, sw=1.5)
    w.poly([(206 * sx, -122), (228 * sx, -170), (224 * sx, -112)], fill=DARK, sw=1.5)  # wrist spur
    w.line([(0, -18), (90 * sx, -78), (210 * sx, -128), (330 * sx, -204)], sw=2.5, opacity=0.8)
    return w


def build(out_dir):
    R = Rig("crow", ACCENT)

    legs = Art()
    for sx in (-1, 1):
        x = sx * 30
        legs.poly([(x - 16, -4), (x + 16, -4), (x + sx * 24, 40), (x + sx * 8, 56)], fill=DARK2, sw=1.2)  # ragged thigh
        legs.poly(tube([(x, 20), (x + sx * 12, 72), (x - sx * 4, 128), (x, 172)], 8, 5), sw=1.5)
        legs.circle(x + sx * 12, 72, 9, fill=DARK, sw=1.5)
        for dx, dy in ((-82, 185), (-62, 180), (-30, 185), (52, 183)):  # toes + hooked claws
            fx = x + dx
            legs.poly(tube([(x, 170), ((x + fx) / 2, 180), (fx, dy)], 7, 1.5), sw=1.2)
        legs.poly([(x - 80, 176), (x - 96, 186), (x - 76, 186)], sw=1.2)
        legs.poly([(x + 50, 174), (x + 66, 186), (x + 48, 186)], sw=1.2)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly(tube([(-48, -222), (-66, -280), (-80, -335)], 20, 11), fill=DARK, sw=2)  # long neck
    body.poly([(-96, -170), (-84, -230), (-40, -276), (30, -276), (100, -230), (170, -160), (250, -60), (236, -30),
               (206, -52), (212, -14), (172, -44), (166, 2), (130, -34), (70, -30), (0, -60), (-60, -100)])
    for x, y, ln in ((-30, -70, 70), (10, -50, 84), (50, -40, 62), (96, -56, 70)):  # torn feathers hanging
        body.poly([(x - 10, y), (x + 12, y), (x + 2, y + ln * 0.55), (x + 10, y + ln)], fill=DARK2, sw=1.2)
    body.line([(-60, -246), (-20, -270), (30, -270), (100, -226)], sw=2.5, opacity=0.8)
    body.line([(100, -226), (170, -156), (240, -64)], sw=2, opacity=0.5)
    R.part("body", "", H, 3, body)

    head = Art()
    head.poly([(-28, -8), (-34, -44), (-14, -72), (22, -74), (42, -50), (34, -12), (12, 6)])  # bald skull
    head.poly([(24, -70), (50, -98), (46, -62)], fill=DARK2, sw=1.5)  # bony ridge spike
    head.poly([(-30, -58), (-100, -52), (-148, -28), (-164, 8), (-140, -8), (-100, -26), (-30, -28)], fill=DARK2, sw=2)
    head.poly([(-30, -24), (-92, -20), (-122, -8), (-90, -12), (-30, -8)], fill=DARK, sw=1.5)
    head.line([(-30, -58), (-100, -52), (-148, -28)], sw=2.5, opacity=0.8)
    head.line([(-14, -72), (22, -74), (44, -52)], sw=2.5, opacity=0.8)
    R.part("head", "body", N, 4, head)

    eyes = Art()
    eyes.poly([(-26, -52), (12, -40), (10, -29), (-26, -41)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 5, eyes, glow=True)

    R.part("wing_l", "body", WL, 2, wing(-1))
    R.part("wing_r", "body", WR, 6, wing(1))

    R.build_layout(out_dir)
    pose = make_pose_fn(R, 100, 100)

    def W(r, l):  # wing rot: r up = negative, l up = positive
        return {"wing_r": (r,), "wing_l": (l,)}

    pose("idle", body=(2, 0, 0), head=2, extra=W(38, -38))
    pose("windup_quick", body=(6, 6, 20), head=22, hmove=(18, 14), extra=W(-25, 25))
    pose("strike_quick", body=(-16, -40, 24), head=-28, hmove=(-30, 20), extra=W(40, -40))
    pose("windup_heavy", body=(8, 10, 40), head=30, hmove=(24, 16), extra=W(-62, 62))
    pose("strike_heavy", body=(-24, -50, 26), head=-45, hmove=(-40, 30), extra=W(55, -55))
    pose("windup_feint", body=(8, 6, 24), head=24, hmove=(14, 10), extra=W(-70, -10))
    pose("windup_combo", body=(12, 30, 14), head=10, extra=W(-150, 6))
    pose("strike_combo", body=(-12, -30, 18), head=-14, extra=W(-6, 150))
    pose("recover", body=(10, 8, 36), head=18, hmove=(10, 10), extra=W(60, -60))
    pose("staggered", body=(24, 4, 28), head=30, extra=W(-50, 34))
    pose("hurt", body=(10, 8, 12), head=14, extra=W(-24, 24))
    pose("death", body=(-84, 40, 22), head=62, legs=(-86, 40, 22), extra=W(60, 147))
    R.write_rig()
    return R
