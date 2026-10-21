from rigkit import *
from shapes import tube

# Cathedral Gargoyle: crouched stone brute, horned head, two bat wings, big hooked claw.
ACCENT = "#9a4dff"
H = (512, 790)
SL, SR = (372, 570), (652, 570)
N = (512, 530)
WL, WR = (440, 540), (584, 540)
L1, L2 = 105, 120


def wing(sx):
    w = Art()
    # bone arm up and out, then three finger spokes with scalloped membrane
    tip = [(120, -130), (230, -250), (300, -240)]
    fing = [(300, -240), (330, -120), (290, -10), (200, 30), (110, 50), (30, 40)]
    pts = [(0, -10)] + tip + [(310, -170), (330, -110), (270, -70), (270, -20), (200, 10), (190, 50), (110, 30), (90, 56),
                              (30, 40)]
    w.poly([(x * sx, y) for x, y in pts], fill=DARK2, sw=2)
    for (x, y) in ((300, -240), (316, -120), (262, -30), (180, 30)):
        w.line([(0, -10), (x * 0.5 * sx, y * 0.5), (x * sx, y)], sw=4, opacity=0.5, color=RIM)
    w.poly(tube([(0, 0), (60 * sx, -70), (120 * sx, -130), (230 * sx, -250), (300 * sx, -240)], 18, 6), fill=DARK, sw=2)
    w.poly([(300 * sx, -240), (326 * sx, -290), (312 * sx, -234)], fill=DARK, sw=1.5)  # wing claw
    w.line([(0, -20), (60 * sx, -86), (120 * sx, -146), (230 * sx, -266), (300 * sx, -256)], sw=2.5, opacity=0.8)
    return w


def arm(side):
    s = -1 if side == "l" else 1
    up = Art()
    up.circle(0, 0, 38, fill=DARK, sw=2)
    up.poly(tube([(0, 0), (0, 60), (0, 108)], 32, 26), sw=2)
    up.circle(0, 108, 26, fill=DARK, sw=2)
    up.line([(-26, 10), (-24, 90)], sw=2.5, opacity=0.6)
    fo = Art()
    fo.circle(0, 0, 24, fill=DARK, sw=2)
    fo.poly([(s * 16, -6), (s * 44, 14), (s * 14, 28)], fill=DARK2, sw=1.5)
    fo.poly(tube([(0, 0), (0, 60), (0, 122)], 26, 22), sw=2)
    if side == "l":
        fo.ellipse(0, 138, 30, 30)
        for dx in (-22, 0, 22):
            fo.poly([(dx - 8, 150), (dx + 8, 150), (dx + dx * 0.3, 196)], sw=1.5)
    return up, fo


def build(out_dir):
    R = Rig("gargoyle", ACCENT)

    legs = Art()
    left = [(-60, -10), (-140, 20), (-168, 90), (-140, 150), (-170, 172), (-176, 185), (-70, 185), (-76, 160),
            (-64, 110), (-30, 60), (-10, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    for sx in (-1, 1):
        legs.line([(sx * 140, 30), (sx * 164, 90), (sx * 138, 148)], sw=2.5, opacity=0.7)
        for dx in (-30, -4, 22):
            legs.poly([(sx * 120 + dx - 8, 184), (sx * 120 + dx, 168), (sx * 120 + dx + 8, 184)], fill=DARK2, sw=1.2)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-70, 10), (-130, -40), (-160, -120), (-150, -220), (-110, -290), (-40, -320), (40, -320), (110, -290),
               (150, -220), (160, -120), (130, -40), (70, 10), (0, 30)])
    for x in (-90, -30, 30, 90):  # back ridge spikes
        body.poly([(x - 18, -300), (x, -340), (x + 18, -300)], fill=DARK2, sw=1.5)
    for pts in ([(-40, -220), (-20, -170), (-50, -130), (-30, -80)], [(50, -200), (30, -150), (60, -100)]):
        body.line(pts, sw=2.5, opacity=0.5)  # cracks
    body.poly([(-100, -60), (-60, -30), (-110, -20)], fill=DARK2, sw=1.2)
    body.line([(-150, -220), (-110, -290), (-40, -320), (40, -320)], sw=2.5, opacity=0.8)
    body.line([(-158, -150), (-150, -220)], sw=2.5, opacity=0.8)
    R.part("body", "", H, 3, body)
    R.part("wing_l", "body", WL, 1, wing(-1))
    R.part("wing_r", "body", WR, 2, wing(1))


    head = Art()
    head.poly([(-70, 0), (-84, -60), (-60, -120), (-24, -150), (24, -150), (60, -120), (84, -60), (70, 0), (40, 20),
               (0, 30), (-40, 20)])
    for sx in (-1, 1):  # horns
        head.poly([(sx * 60, -110), (sx * 104, -168), (sx * 96, -262), (sx * 62, -230), (sx * 70, -176), (sx * 34, -132)],
                  fill=DARK2, sw=2)
        head.line([(sx * 102, -170), (sx * 94, -258)], sw=2.5, opacity=0.8)
    head.poly([(-40, -20), (40, -20), (30, 12), (-30, 12)], fill="#020305", stroke=None)  # maw
    for x in (-26, -9, 9, 26):
        head.poly([(x - 5, -20), (x, -4), (x + 5, -20)], fill=DARK2, sw=1)
    head.line([(-70, 0), (-84, -60), (-60, -120), (-24, -150), (24, -150)], sw=2.5, opacity=0.8)
    R.part("head", "body", N, 4, head)

    eyes = Art()
    eyes.poly([(-50, -86), (-16, -72), (-18, -56), (-52, -66)], fill=ACCENT, stroke=None)
    eyes.poly([(50, -86), (16, -72), (18, -56), (52, -66)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 5, eyes, glow=True)

    ul, fl = arm("l")
    ur, fr = arm("r")
    R.part("arm_l", "body", SL, 6, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 7, fl)
    R.part("arm_r", "body", SR, 8, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 9, fr)

    w = Art()  # claw: stone palm and four hooked talons with glowing inner edges
    w.ellipse(0, 6, 40, 34)
    w.poly([(-30, 24), (30, 24), (26, 44), (-26, 44)], fill=DARK2, sw=1.5)  # wrist band
    for x, tx, ty in ((-34, -18, -128), (-12, -4, -148), (12, 10, -148), (34, 28, -128)):
        w.poly([(x - 11, -12), (x + 11, -12), (tx + 6, ty + 20), (tx + (14 if x > 0 else -14), ty)], sw=1.5)
        w.line([(x * 0.9, -22), ((x + tx) / 2, (ty - 12) / 2 - 20), (tx + (10 if x > 0 else -10), ty + 6)],
               color=ACCENT, sw=8, opacity=1.0)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 10, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)

    def W(r, l):  # rest = wings up and out; positive r / negative l = spread lower
        return {"wing_r": (r,), "wing_l": (l,)}

    pose("idle", body=(2, 0, 0), head=-3, hr=(700, 780), blade=10, hl=(330, 780), extra=W(-8, 8))
    pose("windup_quick", body=(-12, -6, 16), head=8, hr=(800, 680), blade=80, hl=(350, 760), extra=W(-36, 36))
    pose("strike_quick", body=(16, -20, 30), head=10, hr=(440, 720), blade=-85, hl=(380, 700), bend_r=1, extra=W(-12, 12))
    pose("windup_heavy", body=(-12, 16, -8), head=-10, hr=(660, 380), blade=0, hl=(380, 460), bend_r=1, bend_l=-1,
         extra=W(0, 0))
    pose("strike_heavy", body=(22, -10, 50), head=18, hr=(560, 760), blade=165, hl=(430, 780), bend_r=-1, extra=W(-30, 30))
    pose("windup_feint", body=(-6, -14, 18), head=-22, hr=(700, 690), blade=45, hl=(340, 740), extra=W(62, 4))
    pose("windup_combo", body=(12, -12, 10), head=10, hr=(520, 740), blade=-100, hl=(660, 760), bend_r=-1, bend_l=-1,
         extra=W(-34, -46))
    pose("strike_combo", body=(-14, 16, 22), head=-8, hr=(790, 740), blade=100, hl=(420, 780), bend_r=1, bend_l=1,
         extra=W(46, 34))
    pose("recover", body=(12, 0, 40), head=20, hr=(690, 790), blade=125, hl=(370, 800), extra=W(-10, 10))
    pose("staggered", body=(-20, 0, 26), head=-22, hr=(800, 540), blade=30, hl=(240, 540), bend_r=1, bend_l=-1,
         extra=W(-20, 20))
    pose("hurt", body=(-10, 0, 12), head=-12, hr=(700, 760), blade=18, hl=(350, 760), extra=W(-18, 18))
    pose("death", body=(-84, 70, 22), head=-10, legs=(-86, 70, 22), hr=(200, 840), blade=-100, hl=(330, 860),
         bend_r=1, bend_l=-1, extra=W(30, 120))
    R.write_rig()
    return R
