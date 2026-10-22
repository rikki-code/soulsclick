from rigkit import *
from shapes import tube

# Tutorial boss: a big chubby teddy bear swinging a giant striped toy mallet. Light pastel style, not near-black.
ACCENT = "#ff7a8a"
H = (512, 800)
SR = (650, 520)
SL = (390, 520)
N = (500, 500)
L1, L2 = 165, 175

FUR = "#d9a066"
FUR2 = "#c48a52"   # shaded fur
BELLY = "#f6dcb0"
EAR = "#f2a8a0"
LINE = "#4a3322"
BOW = "#e86a5a"
BLUE = "#8fc9f0"
WHITE = "#ffffff"
WOOD = "#c98b4a"
PATCH = "#9fd3a6"
SW = 4


def fur(a, pts, fill=FUR, sw=SW, t=1.0):
    a.smooth(pts, fill=fill, stroke=LINE, sw=sw, t=t)


def rrect(cx, cy, hw, hh, r):
    """Rounded-rectangle outline points (8 anchors) for smooth()."""
    x0, x1, y0, y1 = cx - hw, cx + hw, cy - hh, cy + hh
    return [(x0 + r, y0), (x1 - r, y0), (x1, y0 + r), (x1, y1 - r), (x1 - r, y1), (x0 + r, y1), (x0, y1 - r),
            (x0, y0 + r)]


def limb(scale, right):
    s = scale
    up = Art()
    up.circle(0, 0, 40 * s, fill=FUR, stroke=LINE, sw=SW)
    up.poly(tube([(0, 0), (4, 80), (0, L1)], 36 * s, 32 * s), fill=FUR, stroke=LINE, sw=SW)
    up.circle(0, 0, 36 * s, fill=FUR, stroke=None, sw=0)  # hide the seam inside the shoulder
    up.circle(0, L1, 32 * s, fill=FUR, stroke=LINE, sw=SW)
    up.line([(-18 * s, 40), (-16 * s, 100)], color=FUR2, sw=5, opacity=0.8)
    fo = Art()
    fo.circle(0, 0, 31 * s, fill=FUR, stroke=LINE, sw=SW)
    fo.poly(tube([(0, 0), (-3, 90), (0, L2 - 10)], 30 * s, 29 * s), fill=FUR, stroke=LINE, sw=SW)
    fo.circle(0, 0, 27 * s, fill=FUR, stroke=None, sw=0)
    fo.circle(0, L2, 40 * s, fill=FUR, stroke=LINE, sw=SW)  # round paw
    if not right:  # open paw: pad and toe beans; the right paw is covered by the mallet grip
        fo.ellipse(0, L2 + 8 * s, 20 * s, 17 * s, fill=EAR, stroke=LINE, sw=3)
        for dx in (-18, 0, 18):
            fo.circle(dx * s, L2 - 24 * s + (0 if dx == 0 else 8 * s), 7 * s, fill=EAR, stroke=LINE, sw=2.5)
    fo.line([(-17 * s, 40), (-16 * s, 100)], color=FUR2, sw=5, opacity=0.8)
    return up, fo


def build(out_dir):
    R = Rig("tut_teddy", ACCENT)

    # ---- legs: two stubby thick legs with foot pads
    legs = Art()
    left = [(-160, 30), (-182, 100), (-160, 170), (-100, 196), (-42, 178), (-26, 100), (-40, 30)]
    for pts in (left, mirror(left)):
        fur(legs, pts)
    for sx in (-1, 1):
        legs.ellipse(sx * 104, 150, 40, 26, fill=EAR, stroke=LINE, sw=3)
        for dx in (-22, 0, 22):
            legs.circle(sx * 104 + dx, 120 + (0 if dx == 0 else 6), 8, fill=EAR, stroke=LINE, sw=2.5)
    R.part("legs", "", H, 0, legs)

    # ---- body: pear-shaped torso, belly, stitched patch, bow tie
    body = Art()
    fur(body, [(-120, -300), (0, -332), (130, -300), (186, -200), (206, -80), (172, 20), (80, 62), (-20, 70),
               (-120, 52), (-186, -20), (-202, -120), (172 * -1, -230)])
    body.smooth([(-100, -40), (-110, -140), (-50, -220), (50, -226), (116, -150), (126, -50), (70, 22),
                 (-20, 30)], fill=BELLY, stroke=LINE, sw=3)
    # stitched patch on the belly
    body.poly([(24, -120), (96, -128), (102, -58), (30, -48)], fill=PATCH, stroke=LINE, sw=3)
    for (x0, y0, x1, y1) in ((30, -118, 44, -120), (54, -123, 68, -125), (78, -126, 92, -127),
                             (96, -108, 97, -94), (98, -84, 99, -70), (88, -57, 74, -55), (64, -54, 50, -52),
                             (40, -50, 31, -51), (29, -66, 28, -80), (27, -94, 27, -108)):
        body.line([(x0, y0), (x1, y1)], color=LINE, sw=2.5, opacity=1.0)
    body.line([(52, -100), (74, -76)], color=LINE, sw=3, opacity=1.0)
    body.line([(74, -100), (52, -76)], color=LINE, sw=3, opacity=1.0)
    body.line([(-90, -120), (-70, -60), (-30, -16)], color=FUR2, sw=4, opacity=0.5, smooth=True)
    # bow tie under the chin
    body.poly([(-12, -226), (-78, -258), (-86, -196)], fill=BOW, stroke=LINE, sw=SW)
    body.poly([(-12, -226), (54, -258), (62, -196)], fill=BOW, stroke=LINE, sw=SW)
    body.ellipse(-12, -226, 17, 20, fill="#f08a7a", stroke=LINE, sw=SW)
    body.line([(-60, -238), (-30, -232)], color="#ffb5a8", sw=3, opacity=0.9)
    body.line([(34, -238), (14, -232)], color="#ffb5a8", sw=3, opacity=0.9)
    R.part("body", "", H, 1, body)

    # ---- head: ears, round head, muzzle, nose, mouth, cheeks
    head = Art()
    for sx in (-1, 1):  # ears behind the head
        head.circle(sx * 122 + (6 if sx > 0 else 0), -208, 54, fill=FUR, stroke=LINE, sw=SW)
        head.circle(sx * 122 + (6 if sx > 0 else 0), -206, 31, fill=EAR, stroke=LINE, sw=3)
    fur(head, [(-152, -110), (-134, -190), (-62, -236), (28, -242), (114, -216), (160, -130), (166, -40),
               (112, 30), (10, 50), (-100, 36), (-156, -30)])
    head.ellipse(-110, -34, 26, 17, fill=EAR, stroke=None, sw=0, opacity=0.55)
    head.ellipse(128, -34, 26, 17, fill=EAR, stroke=None, sw=0, opacity=0.55)
    head.ellipse(8, -22, 82, 60, fill=BELLY, stroke=LINE, sw=3)
    head.smooth([(-20, -64), (10, -74), (40, -64), (24, -44), (10, -38), (-4, -44)], fill="#1a1210", stroke=LINE, sw=3)
    head.ellipse(2, -62, 8, 4, fill="#ffffff", stroke=None, sw=0, opacity=0.7)
    head.line([(10, -38), (10, -14)], color=LINE, sw=3.5, opacity=1.0)
    head.line([(-34, 6), (-12, -10), (10, -14), (30, -10), (52, 6)], color=LINE, sw=3.5, opacity=1.0, smooth=True)
    head.line([(-148, -100), (-140, -150)], color=FUR2, sw=4, opacity=0.6)
    R.part("head", "body", N, 2, head)

    # ---- eyes: big white eyes with dark pupils and angry brows
    eyes = Art()
    for sx in (-1, 1):
        cx = -66 if sx < 0 else 86
        eyes.ellipse(cx, -104, 38, 45, fill=WHITE, stroke=LINE, sw=SW)
        px = cx + (8 if sx < 0 else -8)
        eyes.ellipse(px, -96, 21, 26, fill="#1c1410", stroke=None, sw=0)
        eyes.circle(px - 7, -108, 7, fill=WHITE, stroke=None, sw=0)
        eyes.circle(px + 8, -84, 3.5, fill=WHITE, stroke=None, sw=0, opacity=0.8)
        # brow slants down toward the nose
        bx0, by0, bx1, by1 = (cx - 44, -170, cx + 36, -140) if sx < 0 else (cx + 44, -170, cx - 36, -140)
        eyes.poly([(bx0, by0 - 10), (bx1, by1 - 10), (bx1, by1 + 12), (bx0, by0 + 12)], fill=FUR2, stroke=LINE, sw=3.5)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    # ---- arms (left smaller, hangs behind the mallet)
    ul, fl = limb(0.86, False)
    ur, fr = limb(1.0, True)
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    # ---- weapon: giant toy mallet, art points up from the hand
    w = Art()
    w.poly([(-14, 66), (-14, -250), (14, -250), (14, 66)], fill=WOOD, stroke=LINE, sw=SW)
    w.line([(-5, 30), (-5, -200)], color="#a86f34", sw=3, opacity=0.8)
    w.circle(0, 70, 21, fill=WOOD, stroke=LINE, sw=SW)
    hw, hh, cy = 112, 62, -296
    head_pts = rrect(0, cy, hw, hh, 42)
    w.smooth(head_pts, fill=BLUE, stroke=None, sw=0, t=0.5)
    for x0, x1 in ((-66, -22), (22, 66)):
        w.poly([(x0, cy - hh + 2), (x1, cy - hh + 2), (x1, cy + hh - 2), (x0, cy + hh - 2)], fill=WHITE, stroke=None, sw=0)
    for x in (-66, -22, 22, 66):
        w.line([(x, cy - hh + 2), (x, cy + hh - 2)], color="#5aa0d0", sw=2.5, opacity=0.8)
    w.smooth(head_pts, fill="none", stroke=LINE, sw=SW, t=0.5)
    w.line([(-hw + 10, cy + 16), (-hw + 10, cy - 8), (-hw + 24, cy - hh + 12), (-hw + 56, cy - hh + 4)],
           color=ACCENT, sw=9, opacity=1.0, smooth=True)
    w.line([(hw - 54, cy - hh + 4), (hw - 22, cy - hh + 12), (hw - 10, cy - 8), (hw - 10, cy + 16)],
           color=ACCENT, sw=9, opacity=1.0, smooth=True)
    w.line([(-hw + 14, cy + hh - 16), (-hw + 36, cy + hh - 4), (hw - 36, cy + hh - 4), (hw - 14, cy + hh - 16)],
           color=ACCENT, sw=6, opacity=0.9, smooth=True)
    # grip: furry fist over the handle
    w.circle(0, -4, 31, fill=FUR, stroke=LINE, sw=SW)
    for dy in (-18, -2, 14):
        w.line([(-24, dy), (-8, dy + 4)], color=LINE, sw=3, opacity=0.9)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 8, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    pose("idle", body=(2, 0, 0), head=-3, hr=(715, 840), blade=22, hl=(400, 820))
    pose("windup_quick", body=(-9, -6, 10), head=6, hr=(700, 650), blade=34, hl=(390, 700))
    pose("strike_quick", body=(12, -16, 20), head=8, hr=(470, 700), blade=-70, hl=(360, 640), bend_r=1)
    pose("windup_heavy", body=(-12, 0, -4), head=-10, hr=(640, 450), blade=14, hl=(420, 560), bend_r=1, bend_l=-1)
    pose("strike_heavy", body=(20, -10, 30), head=16, hr=(600, 600), blade=150, hl=(450, 690), bend_r=-1)
    pose("windup_feint", body=(-6, -14, 12), head=-20, hr=(700, 640), blade=40, hl=(380, 680))
    pose("windup_combo", body=(10, -12, 10), head=10, hr=(470, 780), blade=-72, hl=(480, 800), bend_r=-1)
    pose("strike_combo", body=(-12, 14, 20), head=-8, hr=(650, 780), blade=45, hl=(420, 790), bend_r=1)
    pose("recover", body=(10, 0, 36), head=20, hr=(620, 810), blade=70, hl=(410, 850))
    pose("staggered", body=(-18, 0, 22), head=-22, hr=(740, 620), blade=18, hl=(310, 600), bend_r=1, bend_l=-1)
    pose("hurt", body=(-9, 0, 10), head=-12, hr=(710, 780), blade=18, hl=(380, 760))
    pose("death", body=(-84, 90, -10), head=-10, legs=(-86, 90, -10), hr=(500, 880), blade=-86, hl=(380, 880),
         bend_r=1, bend_l=-1)
    R.write_rig()
    return R
