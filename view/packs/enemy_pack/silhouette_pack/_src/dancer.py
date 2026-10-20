from rigkit import *

# Veil Dancer: tall, slender, masked, long veil strips and a thin curved saber. Feints and patience.
ACCENT = "#b57bff"
H = (512, 640)
SL, SR = (436, 402), (588, 402)
N = (512, 386)
L1, L2 = 128, 150


def limb(side):
    s = -1 if side == "l" else 1
    up = Art()
    up.smooth([(-16, -4), (-18, 44), (-12, 120), (0, 130), (12, 120), (17, 44), (16, -4), (0, -18)])
    up.line([(-13, 6), (-15, 60), (-9, 116)], sw=2, opacity=0.6)
    fo = Art()
    fo.circle(0, 0, 15, fill=DARK, sw=2)
    # trailing sleeve ribbon
    fo.poly([(s * 8, 20), (s * 40, 90), (s * 54, 190), (s * 30, 150), (s * 24, 220), (s * 8, 126)], fill=DARK2, sw=1.5)
    fo.smooth([(-13, -8), (-15, 60), (-11, 130), (11, 130), (15, 60), (13, -8), (0, -12)])
    fo.line([(-11, 0), (-13, 70), (-9, 126)], sw=2, opacity=0.6)
    fo.ellipse(0, 150, 15, 18)
    if side == "l":
        for dx in (-10, 0, 10):
            fo.poly([(dx - 3, 162), (dx + 3, 162), (dx * 1.3, 206)], sw=1.5)
    return up, fo


def build(out_dir):
    R = Rig("dancer", ACCENT)

    legs = Art()
    left = [(-40, 0), (-52, 90), (-54, 170), (-46, 260), (-42, 318), (-72, 330), (-76, 340), (-18, 340),
            (-24, 316), (-24, 260), (-26, 170), (-18, 90), (-6, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    # veil skirt shreds
    legs.poly([(-70, -24), (-104, 90), (-128, 200), (-98, 170), (-84, 262), (-58, 180), (-34, 290), (-6, 190),
               (0, 300), (8, 190), (34, 288), (58, 180), (84, 264), (98, 170), (128, 202), (104, 90), (70, -24)],
              fill=DARK2, sw=1.5)
    legs.line([(-70, -10), (-100, 90), (-124, 198)], sw=2, opacity=0.6)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-34, 10), (-42, -60), (-56, -140), (-84, -200), (-96, -232), (-60, -250), (0, -258), (60, -250),
               (96, -232), (84, -200), (56, -140), (42, -60), (34, 10)])
    body.poly([(-30, -60), (-36, 8), (0, 24), (36, 8), (30, -60)], fill=DARK2, sw=1.5)  # sash
    body.line([(-56, -140), (-30, -200), (-8, -250)], sw=2, opacity=0.5)
    body.line([(-96, -232), (-60, -250), (0, -258)], sw=2.5, opacity=0.8)
    # shoulder veil drapes
    for sx in (-1, 1):
        body.poly([(sx * 70, -246), (sx * 120, -230), (sx * 132, -150), (sx * 112, -90), (sx * 106, -150),
                   (sx * 82, -190)], fill=DARK2, sw=1.5)
    R.part("body", "", H, 1, body)

    head = Art()
    # trailing hair-veil behind the mask
    for sx in (-1, 1):
        head.poly([(sx * 30, -80), (sx * 70, -50), (sx * 86, 20), (sx * 74, 110), (sx * 62, 40), (sx * 46, 10)],
                  fill=DARK2, sw=1.5)
    head.poly([(-34, 10), (-44, -30), (-40, -80), (-20, -114), (0, -124), (20, -114), (40, -80), (44, -30),
               (34, 10), (16, 34), (0, 44), (-16, 34)])
    for sx in (-1, 1):  # slender curved crown tines
        head.poly([(sx * 22, -112), (sx * 62, -150), (sx * 78, -214), (sx * 40, -176), (sx * 8, -124)],
                  fill=DARK2, sw=1.5)
    head.line([(-44, -30), (-40, -80), (-20, -112), (0, -122)], sw=2.5, opacity=0.8)
    head.line([(0, -120), (0, 40)], sw=2, opacity=0.4)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-30, -60), (-6, -48), (-8, -40), (-32, -50)], fill=ACCENT, stroke=None)
    eyes.poly([(30, -60), (6, -48), (8, -40), (32, -50)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    w = Art()  # curved saber (bends right at the tip)
    w.poly([(-5, 34), (-5, -16), (5, -16), (5, 34)], fill=DARK2, sw=1.5)
    w.poly([(-24, -14), (-30, -24), (30, -24), (24, -14), (0, -8)], fill=DARK2, sw=1.5)
    w.poly([(-9, -24), (-10, -136), (-2, -232), (22, -298), (66, -336), (34, -264), (16, -200), (10, -128), (9, -24)])
    w.line([(-9, -22), (-10, -136), (-2, -232), (22, -298), (66, -336)], color=ACCENT, sw=8, opacity=1.0)
    w.poly([(-3, 34), (-14, 90), (-4, 150), (0, 70)], fill=DARK2, sw=1.5)  # tassel ribbon
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 8, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    pose("idle", body=(2, 0, 0), head=-3, hr=(650, 700), blade=22, hl=(380, 690))
    pose("windup_quick", body=(-9, 6, 4), head=6, hr=(650, 560), blade=70, hl=(372, 600), bend_r=-1)
    pose("strike_quick", body=(12, -16, 18), head=10, hr=(470, 600), blade=-80, hl=(340, 520), bend_r=1)
    pose("windup_heavy", body=(-10, 0, -4), head=-8, hr=(580, 380), blade=14, hl=(440, 420), bend_r=1, bend_l=-1)
    pose("strike_heavy", body=(18, -8, 40), head=16, hr=(560, 560), blade=150, hl=(440, 600), bend_r=-1)
    pose("windup_feint", body=(-3, -12, 18), head=-18, hr=(664, 520), blade=62, hl=(360, 610), bend_r=-1)
    pose("windup_combo", body=(10, -10, 4), head=10, hr=(420, 600), blade=-90, hl=(670, 570), bend_r=1, bend_l=-1)
    pose("strike_combo", body=(-12, 14, 12), head=-8, hr=(660, 570), blade=92, hl=(440, 590), bend_r=-1, bend_l=1)
    pose("recover", body=(10, 0, 30), head=18, hr=(600, 720), blade=120, hl=(400, 760))
    pose("staggered", body=(-18, 0, 16), head=-22, hr=(700, 480), blade=20, hl=(290, 480), bend_r=1, bend_l=-1)
    pose("hurt", body=(-9, 0, 6), head=-12, hr=(640, 650), blade=18, hl=(390, 650))
    pose("death", body=(-84, 80, 112), head=-10, legs=(-86, 80, 112), hr=(380, 920), blade=-100, hl=(400, 920),
         bend_r=1, bend_l=-1)
    R.write_rig()
    return R
