from rigkit import *
from shapes import tube, feather

# Tutorial Scarecrow: friendly pastel training dummy on a post. Never attacks; carries a toy stick.
ACCENT = "#ffd24a"
H = (512, 860)
SR = (600, 520)
SL = (424, 520)
N = (512, 480)
L1, L2 = 150, 150

WOOD = "#e8c48a"
WOOD_D = "#c98b4a"
OUT = "#4a3322"
STRAW = "#ffe27a"
SHIRT = "#f2a8a0"
PATCH = "#8fc9f0"
BURLAP = "#f5dfb3"
HAT = "#e86a5a"
EYE = "#2a1a10"
SW = 4


def P(a, pts, fill, sw=SW):
    a.poly(pts, fill=fill, stroke=OUT, sw=sw)


def S(a, pts, fill, sw=SW, **kw):
    a.smooth(pts, fill=fill, stroke=OUT, sw=sw, **kw)


def L(a, pts, sw=2.5, opacity=0.7, color=OUT, smooth=False):
    a.line(pts, color=color, sw=sw, opacity=opacity, smooth=smooth)


def straw(a, base, ang, ln=44, w=7):
    a.poly(feather(base, ang, ln, w), fill=STRAW, stroke=OUT, sw=2.5)


def stitches(a, pts, n_=5, size=5):
    """Little X stitch marks along a polyline of 2 points."""
    (x0, y0), (x1, y1) = pts
    for i in range(n_):
        t = (i + 0.5) / n_
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        L(a, [(x - size, y - size), (x + size, y + size)], sw=2.5, opacity=0.85)
        L(a, [(x - size, y + size), (x + size, y - size)], sw=2.5, opacity=0.85)


def limb(side):
    sx = 1 if side == "r" else -1
    up = Art()
    # sleeve (burlap shirt) with a straw tuft at the wrist end
    up.circle(0, 0, 30, fill=SHIRT, stroke=OUT, sw=SW)
    P(up, tube([(0, 0), (3 * sx, 75), (0, 138)], 25, 21), SHIRT)
    up.circle(0, 0, 30, fill=SHIRT, stroke=OUT, sw=SW)
    L(up, [(-8, 26), (-6, 62)], sw=2.5, opacity=0.5)
    up.circle(0, L1, 17, fill=WOOD, stroke=OUT, sw=SW)
    fo = Art()
    P(fo, tube([(0, 0), (-3 * sx, 70), (0, 128)], 17, 15), WOOD)
    L(fo, [(5, 16), (3, 80)], sw=2.5, opacity=0.45)
    fo.circle(0, 0, 17, fill=WOOD, stroke=OUT, sw=SW)
    # cuff + straw hand
    P(fo, [(-22, 110), (22, 110), (20, 130), (-20, 130)], SHIRT)
    for ang, ln in ((62, 52), (78, 60), (90, 64), (102, 60), (118, 52)):
        straw(fo, (0, 128), ang, ln, 8)
    return up, fo


def build(out_dir):
    R = Rig("tut_scarecrow", ACCENT)

    # ---- legs: a single wooden post on a cross-plank base (origin = hips H)
    legs = Art()
    P(legs, [(-30, -40), (30, -40), (30, 112), (-30, 112)], WOOD)
    L(legs, [(-12, -20), (-14, 60)], sw=2.5, opacity=0.45)
    L(legs, [(10, 0), (12, 90)], sw=2.5, opacity=0.45)
    P(legs, [(-112, 108), (112, 108), (118, 136), (-118, 136)], WOOD)  # base plank
    P(legs, [(-30, 80), (-84, 108), (-60, 108), (-30, 100)], WOOD_D, sw=3)  # braces
    P(legs, [(30, 80), (84, 108), (60, 108), (30, 100)], WOOD_D, sw=3)
    for x in (-86, 86):
        legs.circle(x, 122, 4, fill=OUT, stroke=None, sw=1)
    R.part("legs", "", H, 0, legs)

    # ---- body (origin = hips H): patched burlap shirt, neck post
    body = Art()
    P(body, [(-18, -420), (18, -420), (18, -330), (-18, -330)], WOOD)  # neck post
    for ang, x in ((200, -26), (235, -14), (305, 14), (340, 26)):
        straw(body, (x, -392), ang, 46, 8)
    for ang, y in ((205, -330), (225, -310)):
        straw(body, (-100, y), ang, 44, 8)  # straw out of sleeve holes
        straw(body, (100, y), 360 - ang + 180, 44, 8)
    S(body, [(-112, -350), (-70, -372), (0, -368), (70, -372), (112, -350), (116, -250), (102, -150),
             (96, -50), (-96, -50), (-102, -150), (-116, -250)], SHIRT)
    # collar rope + hem straw
    L(body, [(-70, -366), (0, -352), (70, -366)], sw=4, opacity=0.9, smooth=True)
    for x, ang in ((-70, 100), (-40, 95), (-8, 90), (24, 85), (56, 82), (82, 78)):
        straw(body, (x, -52), ang, 52, 9)
    # belt rope
    P(body, [(-98, -96), (98, -96), (96, -76), (-96, -76)], WOOD_D, sw=3)
    P(body, [(-8, -100), (14, -100), (14, -72), (-8, -72)], STRAW, sw=3)
    # blue patch with stitches
    P(body, [(22, -300), (78, -304), (80, -236), (24, -232)], PATCH)
    stitches(body, [(30, -296), (74, -298)], 4, 4)
    stitches(body, [(32, -240), (76, -242)], 4, 4)
    # small seam and rip on the other side
    L(body, [(-76, -250), (-52, -200)], sw=3, opacity=0.8)
    stitches(body, [(-78, -252), (-52, -204)], 3, 4)
    L(body, [(-60, -160), (-30, -170)], sw=2.5, opacity=0.5)
    R.part("body", "", H, 1, body)

    # ---- head (origin = neck N)
    head = Art()
    S(head, [(0, -182), (62, -168), (92, -104), (80, -36), (36, -6), (-36, -6), (-80, -36), (-92, -104), (-62, -168)],
      BURLAP, t=1.0)
    head.circle(-52, -62, 14, fill="#f2a8a0", stroke=None, sw=1, opacity=0.55)  # rosy cheeks
    head.circle(52, -62, 14, fill="#f2a8a0", stroke=None, sw=1, opacity=0.55)
    # nose stitch
    L(head, [(0, -96), (-6, -76), (6, -76)], sw=2.5, opacity=0.6)
    # stitched smile with X stitches
    L(head, [(-42, -50), (-22, -36), (0, -32), (22, -36), (42, -50)], sw=3.5, opacity=0.95, smooth=True)
    for x, y in ((-42, -50), (-22, -37), (0, -32), (22, -37), (42, -50)):
        L(head, [(x - 5, y - 6), (x + 5, y + 6)], sw=3, opacity=0.95)
        L(head, [(x - 5, y + 6), (x + 5, y - 6)], sw=3, opacity=0.95)
    # sewn head patch
    head.poly([(56, -150), (86, -126), (66, -100), (40, -122)], fill=PATCH, stroke=OUT, sw=3)
    # straw out from under hat
    for ang, x in ((165, -86), (190, -92), (15, 86), (-10, 92)):
        straw(head, (x, -135), ang, 46, 8)
    # floppy hat
    S(head, [(-96, -158), (-60, -214), (-10, -246), (46, -240), (90, -214), (112, -178), (96, -150), (0, -138),
             (-96, -150)], HAT)
    P(head, [(-108, -168), (-90, -148), (0, -132), (90, -148), (108, -168), (60, -156), (0, -152), (-60, -156)], WOOD_D,
      sw=3)
    P(head, [(36, -228), (88, -250), (136, -230), (150, -190), (132, -172), (126, -204), (96, -218), (50, -204)], HAT)
    head.circle(134, -170, 12, fill=STRAW, stroke=OUT, sw=3)  # pompom
    head.circle(-4, -196, 12, fill=PATCH, stroke=OUT, sw=3)  # hat patch
    R.part("head", "body", N, 2, head)

    # ---- button eyes (origin = neck N)
    eyes = Art()
    for x in (-34, 34):
        eyes.circle(x, -100, 17, fill=EYE, stroke=OUT, sw=3)
        eyes.circle(x - 5, -106, 4, fill="#fff6dc", stroke=None, sw=1)
        eyes.circle(x + 4, -96, 2.5, fill=BURLAP, stroke=None, sw=1)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    # ---- arms
    ur, fr = limb("r")
    R.part("arm_r", "body", SR, 4, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 5, fr)
    ul, fl = limb("l")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)

    # ---- weapon: little wooden toy stick, points up at rest (origin = hand)
    w = Art()
    P(w, [(-8, 50), (-9, -190), (9, -190), (8, 50)], WOOD_D, sw=SW)
    L(w, [(-2, 36), (-3, -170)], sw=2, opacity=0.4)
    P(w, [(-12, 8), (12, 8), (11, -26), (-11, -26)], SHIRT, sw=3)  # grip wrap
    P(w, [(-34, -64), (34, -64), (30, -84), (-30, -84)], WOOD, sw=3)  # little crossguard
    w.circle(0, -208, 18, fill=ACCENT, stroke=OUT, sw=3)  # star knob tip
    w.circle(-5, -213, 5, fill="#fff6dc", stroke=None, sw=1)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 6, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    pose("idle", body=(2, 0, 0), head=-2, hr=(690, 800), hl=(440, 800), blade=10)
    pose("windup_quick", body=(-8, -4, 10), head=5, hr=(720, 640), hl=(450, 740), blade=70)
    pose("strike_quick", body=(10, -14, 22), head=6, hr=(480, 690), hl=(420, 740), blade=-85, bend_r=1)
    pose("windup_heavy", body=(-10, 0, -4), head=-8, hr=(650, 340), hl=(430, 560), blade=8, bend_r=1)
    pose("strike_heavy", body=(18, -6, 36), head=14, hr=(560, 700), hl=(440, 780), blade=160, bend_r=-1)
    pose("windup_feint", body=(-5, -10, 12), head=-18, hr=(710, 710), hl=(440, 790), blade=50)
    pose("windup_combo", body=(8, -8, 8), head=8, hr=(470, 770), hl=(430, 790), blade=-100, bend_r=-1)
    pose("strike_combo", body=(-10, 12, 16), head=-6, hr=(720, 770), hl=(440, 790), blade=95, bend_r=1)
    pose("recover", body=(8, 0, 30), head=16, hr=(680, 810), hl=(440, 820), blade=125)
    pose("staggered", body=(-14, 0, 20), head=-16, hr=(770, 570), hl=(380, 600), blade=40, bend_r=1)
    pose("hurt", body=(-7, 0, 9), head=-9, hr=(690, 790), hl=(440, 800), blade=20)
    pose("death", body=(-68, 150, -20), head=-8, legs=(-70, 150, -20), hr=(250, 780), hl=(330, 700), blade=60, bend_r=1)
    R.write_rig()
    return R
