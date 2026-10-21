from rigkit import *
from shapes import tube

# Bone Choirboy: small skeleton, huge skull with a loose oversized jaw (separate part), swings a hymnal.
ACCENT = "#efe9d2"
H = (512, 830)
SL, SR = (450, 650), (574, 650)
N = (512, 640)
J = (512, 610)
L1, L2 = 105, 115


def arm(side):
    up = Art()
    up.circle(0, 0, 16, fill=DARK, sw=2)
    up.poly(tube([(0, 0), (0, 50), (0, 105)], 9, 7), sw=1.5)
    up.circle(0, 105, 11, fill=DARK, sw=1.5)
    fo = Art()
    fo.circle(0, 0, 10, fill=DARK, sw=1.5)
    fo.poly(tube([(0, 0), (0, 60), (0, 112)], 8, 6), sw=1.5)
    fo.ellipse(0, 122, 14, 16)
    for dx in (-8, 0, 8):
        fo.poly([(dx - 3, 130), (dx + 3, 130), (dx, 152)], sw=1.2)
    return up, fo


def build(out_dir):
    R = Rig("choirboy", ACCENT)

    legs = Art()
    for sx in (-1, 1):
        x = sx * 30
        legs.poly(tube([(x, 0), (x + sx * 4, 70), (x, 140)], 9, 7), sw=1.5)
        legs.circle(x + sx * 4, 72, 12, fill=DARK, sw=1.5)
        legs.poly([(x - 12, 138), (x - 30, 146), (x - 34, 145), (x + 22, 145), (x + 20, 134)], sw=1.5)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-56, 6), (-40, -34), (-14, -30), (0, -14), (14, -30), (40, -34), (56, 6), (30, 18), (-30, 18)])  # pelvis
    body.poly([(-5, -30), (-5, -100), (5, -100), (5, -30)], fill=DARK2, sw=1.2)  # spine
    body.poly([(-62, -118), (-50, -190), (-20, -216), (20, -216), (50, -190), (62, -118), (46, -88), (0, -80), (-46, -88)],
              fill=DARK2, sw=2)  # ribcage
    for i, y in enumerate((-188, -164, -140, -116)):
        w = 50 - abs(i - 1) * 4
        body.line([(-w, y), (-8, y + 8)], sw=3.5, opacity=0.55)
        body.line([(w, y), (8, y + 8)], sw=3.5, opacity=0.55)
    body.line([(0, -216), (0, -92)], sw=3, opacity=0.5)
    body.poly([(-70, -196), (-30, -222), (30, -222), (70, -196), (60, -178), (0, -204), (-60, -178)], sw=1.5)  # collar bones
    body.line([(-62, -118), (-50, -190), (-20, -216)], sw=2.5, opacity=0.8)
    R.part("body", "", H, 2, body)

    head = Art()
    head.poly([(-72, -56), (-64, -146), (-26, -190), (26, -190), (64, -146), (72, -56), (58, -22), (-58, -22)])
    for x in range(-48, 49, 16):  # upper teeth
        head.poly([(x - 6, -24), (x, -4), (x + 6, -24)], fill=DARK2, sw=1.2)
    head.poly([(-56, -112), (-12, -108), (-14, -66), (-52, -70)], fill="#020305", stroke=None)  # sockets
    head.poly([(56, -112), (12, -108), (14, -66), (52, -70)], fill="#020305", stroke=None)
    head.poly([(-8, -62), (0, -76), (8, -62), (0, -48)], fill="#020305", stroke=None)
    head.line([(-72, -56), (-64, -146), (-26, -190), (26, -190)], sw=2.5, opacity=0.8)
    R.part("head", "body", N, 4, head)

    jaw = Art()  # huge hanging jaw, pivot at the hinge
    jaw.poly([(-84, -24), (-96, 34), (-72, 104), (-30, 138), (30, 138), (72, 104), (96, 34), (84, -24), (58, -12),
              (0, -6), (-58, -12)])
    jaw.poly([(-60, -8), (60, -8), (54, 66), (0, 104), (-54, 66)], fill="#020305", stroke=None)
    for x in range(-48, 49, 16):  # lower teeth
        jaw.poly([(x - 6, 82 - abs(x) * 0.5), (x, 60 - abs(x) * 0.3), (x + 6, 82 - abs(x) * 0.5)], fill=DARK2, sw=1.2)
    jaw.line([(-94, 30), (-72, 102), (-30, 136)], sw=2.5, opacity=0.8)
    R.part("jaw", "head", J, 3, jaw)

    eyes = Art()
    eyes.circle(-32, -90, 12, fill=ACCENT, stroke=None)
    eyes.circle(32, -90, 12, fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 5, eyes, glow=True)

    ul, fl = arm("l")
    ur, fr = arm("r")
    R.part("arm_l", "body", SL, 6, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 7, fl)
    R.part("arm_r", "body", SR, 8, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 9, fr)

    w = Art()  # hymnal: thick slab book, glowing page edge, torn ribbon
    w.poly([(-66, 8), (-66, -190), (66, -190), (66, 8)], fill=DARK2, sw=2.5)
    w.poly([(-54, -4), (-54, -178), (54, -178), (54, -4)], fill=DARK, sw=1.5)
    w.poly([(-66, -190), (-78, -180), (-78, 0), (-66, 8)], fill=DARK, sw=2)  # spine
    w.line([(-34, -150), (-14, -110), (-34, -78), (-10, -40)], sw=3, opacity=0.5)  # embossed crack
    w.line([(60, -184), (60, 2)], color=ACCENT, sw=9, opacity=1.0)  # page edge
    w.line([(-60, 4), (60, 4)], color=ACCENT, sw=7, opacity=0.9)
    w.poly([(20, 4), (34, 4), (40, 70), (28, 58), (22, 76)], fill=DARK2, sw=1.2)  # ribbon
    w.line([(-66, -190), (66, -190)], sw=2.5, opacity=0.8)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 10, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)

    def JW(d):
        return {"jaw": (0, (0, d))}

    pose("idle", body=(2, 0, 0), head=-3, hr=(574, 820), blade=8, grip_l=0, extra=JW(0))
    pose("windup_quick", body=(-10, -6, 12), head=8, hr=(700, 690), blade=80, hl=(470, 790), extra=JW(14))
    pose("strike_quick", body=(14, -18, 26), head=10, hr=(450, 760), blade=-80, hl=(560, 780), bend_r=1, extra=JW(24))
    pose("windup_heavy", body=(-10, 0, -4), head=-10, hr=(570, 470), blade=0, grip_l=-10, bend_r=1, bend_l=-1, extra=JW(40))
    pose("strike_heavy", body=(22, -6, 40), head=18, hr=(560, 730), blade=170, grip_l=0, extra=JW(28))
    pose("windup_feint", body=(-6, -10, 14), head=-24, hr=(640, 800), blade=45, hl=(470, 760), extra=JW(8))
    pose("windup_combo", body=(12, -12, 10), head=10, hr=(430, 790), blade=-98, hl=(560, 800), bend_r=1, extra=JW(14))
    pose("strike_combo", body=(-14, 16, 22), head=-8, hr=(690, 790), blade=98, hl=(470, 790), bend_r=-1, extra=JW(20))
    pose("recover", body=(12, 0, 34), head=22, hr=(600, 840), blade=125, grip_l=0, extra=JW(6))
    pose("staggered", body=(-20, 0, 24), head=-22, hr=(740, 640), blade=30, hl=(300, 620), bend_r=1, bend_l=-1, extra=JW(44))
    pose("hurt", body=(-10, 0, 12), head=-12, hr=(600, 800), blade=14, grip_l=0, extra=JW(18))
    pose("death", body=(-84, 50, 26), head=-10, legs=(-86, 50, 26), hr=(250, 880), blade=-100, hl=(330, 860),
         bend_r=1, bend_l=-1, extra=JW(30))
    R.write_rig()
    return R
