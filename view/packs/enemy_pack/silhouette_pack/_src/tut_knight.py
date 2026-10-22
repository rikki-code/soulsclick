from rigkit import *

# Tutorial toy knight: chubby pastel silver-blue armor, big red plume, toy sword. Same rig/poses as knight.py.
ACCENT = "#5cb8ff"
ARM = "#b9d4ea"
ARM2 = "#8fb0cc"
OUT = "#4a3322"
PLUME = "#e86a5a"
PLUME2 = "#c9483a"
SWORD = "#e8e2d0"
GOLD = "#ffd24a"
SHINE = "#f2f9ff"
SW = 4
H = (512, 690)
SL, SR = (340, 452), (684, 452)
N = (512, 428)
L1, L2 = 125, 140


def A(art, kind, *a, fill=ARM, sw=SW, **k):
    getattr(art, kind)(*a, fill=fill, stroke=OUT, sw=sw, **k)


def limb(side):
    up = Art()
    A(up, "smooth", [(-32, -4), (-36, 50), (-28, 116), (0, 134), (28, 116), (36, 50), (32, -4), (0, -28)])
    up.line([(-24, 12), (-27, 60), (-20, 108)], color=SHINE, sw=4, opacity=0.8, smooth=True)
    A(up, "smooth", [(-26, 98), (-30, 122), (0, 132), (30, 122), (26, 98), (0, 94)], fill=ARM2)
    A(up, "circle", 0, 126, 32, fill=ARM2)  # elbow cop
    fo = Art()
    A(fo, "circle", 0, 0, 31, fill=ARM2)
    A(fo, "smooth", [(-26, -22), (-32, 60), (-24, 116), (0, 124), (24, 116), (32, 60), (26, -22), (0, -30)])
    fo.line([(-20, 8), (-24, 60), (-17, 108)], color=SHINE, sw=4, opacity=0.8, smooth=True)
    A(fo, "smooth", [(-28, 44), (-32, 72), (0, 78), (32, 72), (28, 44), (0, 40)], fill=ARM2)
    A(fo, "smooth", [(-28, 118), (-34, 144), (-20, 170), (0, 176), (20, 170), (34, 144), (28, 118), (0, 112)])  # mitten
    A(fo, "circle", 0, 148, 5, fill=ARM2, sw=2)
    return up, fo


def build(out_dir):
    R = Rig("tut_knight", ACCENT)

    legs = Art()
    left = [(-90, 2), (-112, 70), (-120, 130), (-108, 196), (-104, 246), (-136, 268), (-136, 286), (-92, 292),
            (-56, 286), (-58, 248), (-68, 196), (-60, 130), (-42, 70), (-22, 2)]
    A(legs, "smooth", left)
    A(legs, "smooth", mirror(left))
    for sx in (-1, 1):
        A(legs, "smooth", [(sx * 120, 124), (sx * 90, 114), (sx * 58, 124), (sx * 62, 158), (sx * 90, 168),
                           (sx * 116, 160)], fill=ARM2)  # round knee plate
        legs.line([(sx * 108, 202), (sx * 102, 246)], color=SHINE, sw=4, opacity=0.8)
    R.part("legs", "", H, 0, legs)

    body = Art()
    A(body, "smooth", [(-72, 10), (-90, -60), (-112, -140), (-150, -196), (-170, -236), (-110, -266), (0, -276),
                       (110, -266), (170, -236), (150, -196), (112, -140), (90, -60), (72, 10), (0, 22)])
    A(body, "smooth", [(-104, -150), (-62, -118), (0, -108), (62, -118), (104, -150), (86, -202), (0, -218),
                       (-86, -202)], fill=ARM2)  # breastplate
    body.line([(-84, -190), (-60, -206), (-20, -210)], color=SHINE, sw=4, opacity=0.8, smooth=True)
    A(body, "circle", 0, -160, 16, fill=GOLD, sw=3)  # toy gold button
    A(body, "smooth", [(-78, 6), (-98, 60), (-54, 86), (0, 74), (54, 86), (98, 60), (78, 6), (0, -6)], fill=ARM2)  # belly skirt
    A(body, "smooth", [(-44, 12), (-52, 108), (0, 126), (52, 108), (44, 12)], fill=PLUME2, sw=3)  # tabard flap
    body.line([(-150, -198), (-112, -140), (-92, -62)], color=SHINE, sw=4, opacity=0.6, smooth=True)
    # round pauldrons
    for sx in (-1, 1):
        A(body, "smooth", [(sx * 128, -236), (sx * 196, -232), (sx * 240, -198), (sx * 216, -158), (sx * 150, -158),
                           (sx * 120, -190)], fill=ARM2)
        body.line([(sx * 150, -222), (sx * 196, -218), (sx * 222, -196)], color=SHINE, sw=4, opacity=0.8, smooth=True)
    R.part("body", "", H, 1, body)

    head = Art()
    A(head, "smooth", [(-62, 12), (-72, -40), (-66, -100), (-38, -140), (0, -152), (38, -140), (66, -100),
                       (72, -40), (62, 12), (30, 28), (-30, 28)])
    # big red plume
    A(head, "smooth", [(-12, -148), (-30, -186), (-26, -226), (4, -246), (44, -240), (62, -214), (52, -186),
                       (68, -166), (50, -150), (20, -146)], fill=PLUME)
    A(head, "smooth", [(8, -160), (6, -196), (24, -220), (44, -214)], fill=PLUME2, sw=3, closed=False)
    A(head, "smooth", [(-6, -170), (-10, -210), (10, -232)], fill=PLUME2, sw=3, closed=False)
    head.line([(-64, -44), (-58, -100), (-34, -136), (-6, -146)], color=SHINE, sw=5, opacity=0.8, smooth=True)
    A(head, "smooth", [(-56, -64), (-50, -78), (0, -80), (50, -78), (56, -64), (52, -42), (0, -38), (-52, -42)],
      fill=OUT, sw=3)  # visor slit
    head.line([(0, -140), (0, -84)], color=OUT, sw=3, opacity=0.5)
    A(head, "smooth", [(-22, 4), (0, 10), (22, 4)], fill="none", closed=False, sw=3)  # smile
    A(head, "circle", -44, -6, 9, fill="#f6a7a0", sw=0, opacity=0.7)
    A(head, "circle", 44, -6, 9, fill="#f6a7a0", sw=0, opacity=0.7)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    for sx in (-1, 1):
        eyes.circle(sx * 26, -59, 14, fill=ACCENT, stroke="#ffffff", sw=3)
        eyes.circle(sx * 26 + 3, -63, 5, fill="#ffffff", stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    w = Art()
    K = 0.7  # y scale keeps every pose inside the canvas

    def sc(pts):
        return [(x * 0.95, y * K) for x, y in pts]
    A(w, "smooth", sc([(-9, 46), (-10, -138), (10, -138), (9, 46)]), fill=GOLD, sw=3)  # grip
    A(w, "circle", 0, 54 * K, 15, fill=GOLD, sw=3)  # pommel
    A(w, "smooth", sc([(-64, -128), (-74, -152), (-34, -156), (0, -140), (34, -156), (74, -152), (64, -128), (0, -118)]),
      fill=GOLD, sw=3)  # round crossguard
    A(w, "smooth", sc([(-26, -148), (-30, -280), (-28, -440), (0, -516), (28, -440), (30, -280), (26, -148)]),
      fill=SWORD)
    w.line(sc([(-24, -152), (-28, -280), (-26, -440), (0, -510)]), color=ACCENT, sw=8, opacity=1.0, smooth=True)
    w.line(sc([(24, -152), (28, -280), (26, -440), (0, -510)]), color=ACCENT, sw=8, opacity=1.0, smooth=True)
    w.line(sc([(0, -160), (0, -460)]), color=SHINE, sw=4, opacity=0.9)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2 + 12), 8, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    G = 58  # left hand sits this far up the grip
    pose("idle", body=(1, 0, 0), head=-2, hr=(560, 700), blade=9, grip_l=62, bend_r=-1, bend_l=1)
    pose("windup_quick", body=(-10, 8, 4), head=6, hr=(600, 610), blade=70, grip_l=G, bend_r=-1, bend_l=1)
    pose("strike_quick", body=(12, -20, 20), head=10, hr=(500, 600), blade=-82, grip_l=G, bend_r=1, bend_l=1)
    pose("windup_heavy", body=(-10, 6, -4), head=-8, hr=(640, 392), blade=28, grip_l=G, bend_r=-1, bend_l=-1)
    pose("strike_heavy", body=(18, -14, 40), head=18, hr=(590, 650), blade=138, grip_l=G, bend_r=-1, bend_l=1)
    pose("windup_feint", body=(-4, -10, 18), head=-16, hr=(668, 470), blade=52, grip_l=G, bend_r=-1, bend_l=-1)
    pose("windup_combo", body=(10, -12, 6), head=12, hr=(380, 620), blade=-100, grip_l=G, bend_r=1, bend_l=1)
    pose("strike_combo", body=(-12, 16, 14), head=-8, hr=(600, 570), blade=100, grip_l=G, bend_r=-1, bend_l=1)
    pose("recover", body=(10, 0, 28), head=20, hr=(590, 700), blade=135, grip_l=G, bend_r=-1, bend_l=1)
    pose("staggered", body=(-16, 0, 14), head=-22, hr=(690, 520), blade=55, hl=(280, 500), bend_r=1, bend_l=-1)
    pose("hurt", body=(-8, 0, 6), head=-12, hr=(640, 640), blade=12, grip_l=G)
    pose("death", body=(-84, 40, 100), head=-10, legs=(-86, 40, 100), hr=(470, 930), blade=-100, grip_l=G, bend_r=1, bend_l=-1)
    R.write_rig()
    return R
