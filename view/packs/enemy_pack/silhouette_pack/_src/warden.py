from rigkit import *

ACCENT = "#ff4a3d"
H = (512, 640)
SL, SR = (296, 384), (728, 384)
N = (512, 376)
L1, L2 = 165, 175
HAFT, CHAIN = 70, 150


def limb(side):
    sx = -1 if side == "l" else 1
    up = Art()
    up.circle(0, L1, 42, fill=DARK2, sw=2)
    up.smooth([(-44, -6), (-48, 60), (-36, 150), (0, 172), (36, 150), (46, 60), (44, -6), (0, -40)])
    up.line([(-40, 8), (-44, 70), (-32, 148)], sw=3, opacity=0.6)
    up.poly([(-36, 104), (-40, 160), (40, 160), (36, 104)], fill=DARK2, sw=2)
    fo = Art()
    fo.circle(0, 0, 40, fill=DARK2, sw=2)  # elbow joint
    fo.poly([(-38, -6), (-44, 70), (-34, 150), (34, 150), (44, 70), (38, -6)])
    fo.line([(-34, 4), (-40, 70), (-30, 146)], sw=3, opacity=0.6)
    fo.poly([(-42, 40), (-48, 84), (48, 84), (42, 40)], fill=DARK2, sw=2)  # shackle band
    fo.ellipse(sx * 52, 86, 11, 16, fill=DARK, sw=2)  # broken chain ring
    fo.ellipse(sx * 52, 112, 7, 12, fill=DARK, sw=2)
    fo.smooth([(-36, 150), (-40, 178), (-24, 204), (24, 204), (40, 178), (36, 150)])
    return up, fo


def build(out_dir):
    R = Rig("warden", ACCENT)

    legs = Art()
    left = [(-110, 0), (-136, 80), (-146, 160), (-130, 240), (-126, 318), (-170, 336), (-176, 347), (-66, 347),
            (-70, 316), (-84, 240), (-72, 160), (-46, 80), (-24, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    for sx in (-1, 1):
        legs.poly([(sx * 146, 150), (sx * 72, 150), (sx * 82, 196), (sx * 138, 200)], fill=DARK2, sw=2)
        legs.line([(sx * 134, 250), (sx * 126, 312)], sw=3, opacity=0.6)
    R.part("legs", "", H, 0, legs)

    body = Art()
    # ragged cloak behind
    body.poly([(-210, -250), (-250, -90), (-236, 40), (-200, 90), (-160, 40), (-120, 110), (-70, 30), (0, 130),
               (70, 30), (120, 110), (160, 40), (200, 90), (236, 40), (250, -90), (210, -250)], fill=DARK2, sw=2)
    body.poly([(-100, 14), (-112, -50), (-150, -140), (-212, -226), (-236, -268), (-150, -296), (-70, -306),
               (70, -306), (150, -296), (236, -268), (212, -226), (150, -140), (112, -50), (100, 14)])
    # hollow ribcage
    body.smooth([(-84, -230), (-108, -150), (-86, -70), (0, -40), (86, -70), (108, -150), (84, -230), (0, -250)],
                fill="#020304", stroke=RIM, sw=2.5)
    for k, y in enumerate((-212, -176, -140, -104, -72)):
        w = 82 - abs(k - 2) * 6
        body.line([(-w, y), (0, y + 20), (w, y)], sw=6, color=DARK2, opacity=1.0, smooth=True)
        body.line([(-w, y - 3), (0, y + 17), (w, y - 3)], sw=1.5, color=HI, opacity=0.45, smooth=True)
    body.line([(0, -250), (0, -50)], sw=7, color=DARK2, opacity=1.0)
    body.poly([(-100, 8), (-120, 70), (-60, 96), (0, 80), (60, 96), (120, 70), (100, 8)], fill=DARK2, sw=2)
    for sx in (-1, 1):
        body.poly([(sx * 150, -300), (sx * 260, -300), (sx * 290, -250), (sx * 250, -196), (sx * 160, -206)],
                  fill=DARK2, sw=2.5)
        body.poly([(sx * 250, -300), (sx * 300, -372), (sx * 276, -296)], fill=DARK, sw=2)
        body.poly([(sx * 284, -262), (sx * 346, -290), (sx * 296, -226)], fill=DARK, sw=2)
        body.line([(sx * 150, -300), (sx * 260, -300), (sx * 290, -252)], sw=3, opacity=0.8)
    body.line([(-236, -268), (-150, -296), (-70, -306)], sw=3, opacity=0.8)
    R.part("body", "", H, 1, body)

    core = Art()
    core.poly([(0, -60), (-20, -110), (-10, -150), (0, -190), (12, -150), (22, -110)], fill=ACCENT, stroke=None)
    core.poly([(0, -92), (-8, -118), (0, -146), (7, -118)], fill="#ffd2c0", stroke=None, opacity=0.8)
    R.part("core", "body", (512, 640), 2, core, glow=True)

    head = Art()
    head.poly([(-64, 14), (-74, -50), (-62, -110), (-30, -146), (0, -156), (30, -146), (62, -110), (74, -50),
               (64, 14), (40, 40), (14, 30), (0, 44), (-14, 30), (-40, 40)])
    for sx in (-1, 1):
        head.poly([(sx * 52, -120), (sx * 110, -150), (sx * 170, -148), (sx * 214, -204), (sx * 200, -118),
                   (sx * 150, -100), (sx * 84, -78)], fill=DARK2, sw=2.5)
        head.line([(sx * 52, -122), (sx * 110, -152), (sx * 170, -150), (sx * 214, -204)], sw=3, opacity=0.8)
    head.poly([(-48, -70), (-8, -52), (-8, -10), (-40, 6), (-58, -30)], fill="#010203", stroke=None)
    head.poly([(48, -70), (8, -52), (8, -10), (40, 6), (58, -30)], fill="#010203", stroke=None)
    head.line([(-30, 22), (-30, 40)], sw=2.5, opacity=0.6)
    head.line([(0, 18), (0, 44)], sw=2.5, opacity=0.6)
    head.line([(30, 22), (30, 40)], sw=2.5, opacity=0.6)
    head.line([(-74, -50), (-62, -110), (-30, -146), (0, -156)], sw=3, opacity=0.8)
    R.part("head", "body", N, 3, head)

    eyes = Art()
    eyes.poly([(-50, -58), (-12, -42), (-14, -22), (-48, -32)], fill=ACCENT, stroke=None)
    eyes.poly([(50, -58), (12, -42), (14, -22), (48, -32)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 4, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 5, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 6, fl)
    R.part("arm_r", "body", SR, 7, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 8, fr)

    hand = (SR[0], SR[1] + L1 + L2)
    w = Art()
    w.poly([(-12, 44), (-12, -HAFT), (12, -HAFT), (12, 44)], fill=DARK2, sw=2)
    w.circle(0, 52, 16, fill=DARK2, sw=2.5)
    w.poly([(-26, -HAFT + 6), (-30, -HAFT - 18), (30, -HAFT - 18), (26, -HAFT + 6)], fill=DARK, sw=2)
    w.line([(0, 30), (0, -HAFT + 10)], color=ACCENT, sw=7, opacity=1.0)
    R.part("weapon", "forearm_r", hand, 9, w, glow=True)

    ch = Art()
    for i in range(7):
        y = -(14 + i * 22)
        if i % 2 == 0:
            ch.ellipse(0, y, 10, 15, fill=DARK, stroke=HI, sw=4, opacity=None)
        else:
            ch.ellipse(0, y, 5, 15, fill=DARK, stroke=HI, sw=4)
    R.part("chain", "weapon", (hand[0], hand[1] - HAFT - 18), 10, ch)

    ball = Art()
    cy = -58
    import math as m
    for k in range(10):
        a = k * 2 * m.pi / 10
        c, s = m.cos(a), m.sin(a)
        tip = (c * 96, cy + s * 96)
        b1 = (c * 48 - s * 17, cy + s * 48 + c * 17)
        b2 = (c * 48 + s * 17, cy + s * 48 - c * 17)
        ball.poly([b1, tip, b2], fill=DARK, sw=2)
    ball.circle(0, cy, 54, fill=DARK, stroke=HI, sw=3)
    ball.circle(0, cy, 34, fill=DARK2, stroke=HI, sw=2.5)
    # ember crack (original mark, no logo-like symbol): single jagged fissure
    ball.line([(-18, cy - 30), (8, cy - 12), (-10, cy + 4), (14, cy + 30)],
              color=ACCENT, sw=8, opacity=1.0)
    R.part("ball", "chain", (hand[0], hand[1] - HAFT - 18 - 150), 11, ball, glow=True)

    R.build_layout(out_dir)
    base = make_pose_fn(R, L1, L2)

    def pose(name, ch=180, **kw):
        p = base(name, **kw)
        p.set("chain", ch - p.wrot("weapon"))
        return p

    pose("idle", body=(1, 0, 0), head=-2, hr=(690, 700), blade=150, ch=120, hl=(290, 720), bend_l=1)
    pose("windup_quick", body=(-8, 10, 6), head=6, hr=(740, 600), blade=40, ch=150, hl=(300, 640), bend_r=-1)
    pose("strike_quick", body=(14, -16, 24), head=12, hr=(560, 640), blade=-70, ch=-130, hl=(300, 600), bend_r=1)
    pose("windup_heavy", body=(-10, 0, 6), head=-8, hr=(650, 430), blade=0, ch=10, hl=(470, 420), bend_r=-1, bend_l=-1)
    pose("strike_heavy", body=(20, -8, 54), head=18, hr=(600, 610), blade=150, ch=165, hl=(400, 640), bend_r=-1)
    pose("windup_feint", body=(-4, -8, 22), head=-18, hr=(690, 440), blade=12, ch=45, hl=(300, 600), bend_r=-1)
    pose("windup_combo", body=(10, -14, 6), head=10, hr=(600, 520), blade=92, ch=92, hl=(300, 580), bend_r=-1)
    pose("strike_combo", body=(-14, 18, 16), head=-8, hr=(460, 520), blade=-92, ch=-92, hl=(760, 560), bend_r=1, bend_l=-1)
    pose("recover", body=(10, 0, 34), head=20, hr=(700, 640), blade=130, ch=160, hl=(300, 760))
    pose("staggered", body=(-16, 0, 20), head=-22, hr=(780, 500), blade=40, ch=160, hl=(230, 500), bend_r=1, bend_l=-1)
    pose("hurt", body=(-8, 0, 8), head=-12, hr=(700, 670), blade=115, ch=140, hl=(290, 700))
    pose("death", body=(-82, 40, 62), head=-10, legs=(-84, 40, 62), hr=(480, 850), blade=-100, ch=-100, hl=(580, 830),
         bend_r=1, bend_l=-1)
    R.write_rig()
    return R
