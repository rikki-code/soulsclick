from rigkit import *

# Flayed Pilgrim: gaunt, hunched, flayed ribs, tattered wide-brim hat over a hollow skull, long hook-staff.
ACCENT = "#2fe0b8"
H = (512, 690)
SL, SR = (440, 436), (588, 436)
N = (514, 414)
L1, L2 = 135, 155
FLESH = "#1a1214"  # dried flayed meat, barely warmer than the dark


def limb(side):
    s = -1 if side == "l" else 1
    up = Art()
    up.smooth([(-15, -4), (-17, 50), (-11, 126), (0, 136), (11, 126), (16, 50), (15, -4), (0, -18)])
    up.line([(-12, 6), (-14, 64), (-8, 122)], sw=2, opacity=0.6)
    up.line([(4, 10), (8, 70), (2, 120)], sw=1.5, color=RIM, opacity=0.9)  # sinew
    fo = Art()
    fo.circle(0, 0, 15, fill=DARK, sw=2)
    fo.poly([(s * 10, -6), (s * 36, 14), (s * 8, 24)], fill=DARK, sw=1.5)  # elbow thorn
    fo.smooth([(-12, -8), (-14, 66), (-10, 140), (10, 140), (14, 66), (12, -8), (0, -12)])
    for y in (30, 58, 86):  # rag wraps
        fo.poly([(-15, y), (-15, y + 12), (15, y + 18), (15, y + 6)], fill=DARK2, sw=1.2)
    fo.line([(-10, 0), (-12, 70), (-8, 136)], sw=2, opacity=0.6)
    fo.ellipse(0, 158, 14, 17)
    for dx, ln in ((-9, 40), (0, 52), (9, 40)):
        fo.poly([(dx - 3, 170), (dx + 3, 170), (dx * 1.2, 170 + ln)], sw=1.2)
    return up, fo


def build(out_dir):
    R = Rig("pilgrim", ACCENT)

    legs = Art()
    left = [(-56, 0), (-64, 80), (-52, 150), (-62, 214), (-52, 262), (-86, 276), (-90, 285), (-22, 285),
            (-28, 262), (-30, 214), (-24, 150), (-30, 80), (-12, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    legs.poly([(-96, -10), (-106, 120), (-88, 104), (-84, 204), (-62, 132), (-42, 236), (-20, 120), (0, 212), (20, 120),
               (44, 240), (62, 132), (86, 208), (90, 104), (108, 122), (96, -10)], fill=DARK2, sw=1.5)  # robe tatters
    legs.line([(-96, -6), (-104, 118), (-86, 200)], sw=2, opacity=0.5)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-52, 10), (-62, -60), (-86, -140), (-106, -214), (-100, -262), (-50, -284), (0, -288), (50, -284),
               (100, -262), (106, -214), (86, -140), (62, -60), (52, 10)])
    body.smooth([(-44, -226), (-58, -154), (-36, -88), (0, -70), (36, -88), (58, -154), (44, -226), (0, -238)],
                fill="#020304", stroke=RIM, sw=2.5)  # flayed chest void
    for k, y in enumerate((-212, -176, -140, -106)):
        w = 50 - abs(k - 1) * 4
        body.line([(-w, y), (0, y + 14), (w, y)], sw=6, color=DARK2, opacity=1.0, smooth=True)
        body.line([(-w, y - 3), (0, y + 11), (w, y - 3)], sw=1.5, color=HI, opacity=0.45, smooth=True)
    body.line([(0, -236), (0, -78)], sw=6, color=DARK2, opacity=1.0)
    for x in (-90, -74, 76, 92):  # peeled skin strips
        body.poly([(x, -230), (x + 14, -150), (x + 4, -104), (x - 8, -150)], fill=FLESH, sw=1.2)
    body.poly([(-64, 6), (-76, 60), (-30, 84), (0, 64), (30, 84), (76, 60), (64, 6)], fill=DARK2, sw=1.5)  # rope belt rags
    for i in range(6):  # chain belt
        body.ellipse(-50 + i * 20, 10, 9, 6, fill=DARK, stroke=HI, sw=2, rot=(i % 2) * 90)
    body.poly([(-100, -258), (-170, -332), (-130, -246)], fill=DARK, sw=1.5)  # shoulder thorns
    body.poly([(100, -258), (172, -336), (130, -246)], fill=DARK, sw=1.5)
    body.poly([(-106, -214), (-166, -226), (-110, -190)], fill=DARK, sw=1.5)
    body.poly([(106, -214), (160, -240), (108, -190)], fill=DARK, sw=1.5)
    # hunchback spine spikes along the left rim
    body.line([(-100, -262), (-50, -284), (0, -288), (50, -284), (100, -262)], sw=2.5, opacity=0.8)
    R.part("body", "", H, 1, body)

    head = Art()
    head.poly([(-40, 8), (-48, -40), (-40, -90), (-22, -116), (0, -122), (22, -116), (40, -90), (48, -40), (40, 8),
               (22, 56), (0, 72), (-22, 56)])  # skull and long jaw
    head.poly([(-36, -74), (-34, -26), (-20, 0), (0, 10), (20, 0), (34, -26), (36, -74)], fill="#020305", stroke=None)
    for x in (-14, -5, 5, 14):  # needle teeth
        head.poly([(x - 3, 40), (x, 62), (x + 3, 40)], fill="#0d1016", sw=1.2)
    head.line([(-40, -88), (-48, -40), (-40, 8)], sw=2.5, opacity=0.8)
    # wide flat-crown pilgrim hat, torn brim (no witch cone)
    head.poly([(-60, -100), (-54, -160), (-30, -178), (-8, -170), (14, -184), (38, -170), (54, -158), (60, -100)],
              fill=DARK2, sw=2)
    head.poly([(-170, -70), (-110, -100), (-40, -110), (0, -114), (40, -110), (110, -100), (170, -70), (206, -40),
               (146, -52), (140, -24), (116, -56), (84, -48), (60, -76), (0, -68), (-60, -76), (-84, -48), (-116, -56),
               (-140, -24), (-146, -52), (-206, -40)], fill=DARK, sw=2)
    head.line([(-170, -70), (-110, -100), (-40, -110), (0, -114)], sw=2.5, opacity=0.8)
    head.line([(-60, -102), (-54, -160), (-30, -178), (-8, -170)], sw=2.5, opacity=0.8)
    head.poly([(-60, -126), (60, -126), (60, -102), (-60, -102)], fill=DARK, sw=1.5)  # hatband
    for x in (-36, -10, 18, 44):  # nails driven through the crown
        head.poly([(x - 4, -168), (x, -214), (x + 4, -168)], fill=DARK, sw=1.2)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-28, -52), (-8, -42), (-10, -30), (-30, -38)], fill=ACCENT, stroke=None)
    eyes.poly([(28, -52), (8, -42), (10, -30), (30, -38)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    w = Art()  # hook staff: pole, crook with an inner glowing edge, back barb, rag strips
    def T(pts):
        return [(x * 0.82, -200 + (y + 250) * 0.78 if y < -200 else y * 0.8 if y < 0 else y) for x, y in pts]
    w.poly([(-7, 70), (-7, -200), (7, -200), (7, 70)], fill=DARK2, sw=1.5)
    w.poly([(-8, 68), (0, 106), (8, 68)], fill=DARK, sw=1.5)
    w.poly([(-9, -30), (-9, -42), (9, -42), (9, -30)], fill=DARK, sw=1.2)
    w.poly(T([(-8, -240), (-12, -310), (6, -366), (40, -392), (84, -392), (122, -360), (140, -314), (128, -262),
              (110, -300), (90, -336), (60, -346), (28, -330), (12, -292), (8, -240)]))
    w.line(T([(10, -296), (26, -330), (60, -346), (90, -336), (110, -300), (126, -266)]), color=ACCENT, sw=9, opacity=1.0)
    w.poly([(-8, -150), (-48, -196), (-8, -184)], fill=DARK, sw=1.5)  # back barb
    w.poly([(7, -120), (44, -100), (36, -50), (14, -90)], fill=DARK2, sw=1.2)  # rags
    w.poly([(-7, -80), (-34, -50), (-24, -20), (-7, -54)], fill=DARK2, sw=1.2)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 8, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    pose("idle", body=(3, 0, 0), head=-4, hr=(690, 740), blade=12, grip_l=120)
    pose("windup_quick", body=(-10, -6, 8), head=8, hr=(680, 650), blade=68, hl=(372, 650))
    pose("strike_quick", body=(14, -18, 20), head=10, hr=(520, 690), blade=-78, hl=(350, 600), bend_r=1)
    pose("windup_heavy", body=(-12, 0, -6), head=-8, hr=(640, 450), blade=30, grip_l=100, bend_r=1, bend_l=-1)
    pose("strike_heavy", body=(20, -8, 44), head=16, hr=(560, 640), blade=148, grip_l=100)
    pose("windup_feint", body=(-4, -12, 16), head=-20, hr=(680, 650), blade=48, hl=(380, 700))
    pose("windup_combo", body=(12, -12, 8), head=10, hr=(450, 720), blade=-80, grip_l=100, bend_r=1, bend_l=1)
    pose("strike_combo", body=(-12, 14, 14), head=-8, hr=(590, 690), blade=82, grip_l=100, bend_r=-1, bend_l=-1)
    pose("recover", body=(10, 0, 34), head=18, hr=(640, 760), blade=112, hl=(410, 800))
    pose("staggered", body=(-18, 0, 18), head=-22, hr=(740, 560), blade=24, hl=(300, 560), bend_r=1, bend_l=-1)
    pose("hurt", body=(-9, 0, 8), head=-12, hr=(660, 740), blade=16, grip_l=110)
    pose("death", body=(-84, 40, 70), head=-10, legs=(-86, 40, 70), hr=(420, 940), blade=-100, hl=(470, 930),
         bend_r=1, bend_l=-1)
    R.write_rig()
    return R
