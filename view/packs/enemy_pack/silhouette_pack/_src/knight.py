from rigkit import *

ACCENT = "#5cb8ff"
H = (512, 690)
SL, SR = (340, 452), (684, 452)
N = (512, 428)
L1, L2 = 125, 140
BL = 380  # blade length above the guard


def limb(side):
    up = Art()
    up.smooth([(-30, -4), (-32, 50), (-24, 118), (0, 130), (24, 118), (32, 50), (30, -4), (0, -26)])
    up.line([(-26, 10), (-28, 60), (-20, 116)], sw=2.5, opacity=0.6)
    up.poly([(-24, 100), (-28, 128), (28, 128), (24, 100)], fill=DARK2, sw=1.5)
    up.circle(0, 125, 31, fill=DARK2, sw=2)  # elbow cop
    fo = Art()
    fo.circle(0, 0, 30, fill=DARK2, sw=2)  # elbow joint overlaps the upper arm
    fo.poly([(-24, -26), (-28, 60), (-22, 118), (22, 118), (28, 60), (24, -26)])  # vambrace
    fo.line([(-22, 6), (-25, 62), (-19, 116)], sw=2.5, opacity=0.6)
    fo.poly([(-27, 40), (-31, 72), (31, 72), (27, 40)], fill=DARK2, sw=1.5)
    fo.smooth([(-26, 118), (-30, 142), (-18, 166), (18, 166), (30, 142), (26, 118)])  # gauntlet
    return up, fo


def build(out_dir):
    R = Rig("knight", ACCENT)

    legs = Art()
    left = [(-88, 0), (-108, 70), (-118, 130), (-104, 200), (-100, 255), (-136, 272), (-140, 286), (-56, 286),
            (-60, 250), (-70, 200), (-62, 130), (-42, 70), (-22, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    for sx in (-1, 1):
        legs.poly([(sx * 118, 125), (sx * 60, 125), (sx * 70, 160), (sx * 112, 164)], fill=DARK2, sw=1.5)  # knee plate
        legs.line([(sx * 104, 205), (sx * 98, 250)], sw=2.5, opacity=0.6)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-70, 10), (-84, -60), (-104, -140), (-150, -200), (-176, -240), (-110, -262), (-40, -272),
               (40, -272), (110, -262), (176, -240), (150, -200), (104, -140), (84, -60), (70, 10)])
    body.poly([(-104, -150), (-60, -120), (0, -112), (60, -120), (104, -150), (84, -200), (0, -216), (-84, -200)],
              fill=DARK2, sw=1.5)  # breastplate
    body.line([(0, -214), (0, -116)], sw=2.5, opacity=0.5)
    body.poly([(-76, 6), (-96, 60), (-52, 84), (0, 70), (52, 84), (96, 60), (76, 6)], fill=DARK2, sw=1.5)  # tabard hem
    body.poly([(-44, 10), (-52, 110), (0, 126), (52, 110), (44, 10)], fill=DARK, sw=1.5)
    body.line([(-176, -240), (-110, -262), (-40, -272)], sw=3, opacity=0.8)
    body.line([(-150, -202), (-104, -142), (-86, -62)], sw=2.5, opacity=0.5)
    body.line([(-100, -150), (-60, -122), (0, -113)], sw=2, opacity=0.7)
    # spiked pauldrons
    for sx in (-1, 1):
        body.poly([(sx * 130, -236), (sx * 206, -226), (sx * 232, -196), (sx * 196, -160), (sx * 140, -170)],
                  fill=DARK2, sw=2)
        body.poly([(sx * 206, -226), (sx * 250, -262), (sx * 222, -208)], fill=DARK, sw=1.5)
    body.line([(-130, -236), (-206, -226), (-230, -198)], sw=2.5, opacity=0.8)
    R.part("body", "", H, 1, body)

    head = Art()
    head.poly([(-54, 14), (-62, -40), (-56, -100), (-30, -138), (0, -150), (30, -138), (56, -100), (62, -40),
               (54, 14), (28, 26), (-28, 26)])
    head.poly([(-8, -150), (-16, -190), (6, -230), (40, -250), (30, -210), (46, -180), (22, -150)], fill=DARK2, sw=1.5)  # crest
    head.line([(-60, -40), (-54, -100), (-30, -136), (0, -148)], sw=3, opacity=0.8)
    head.poly([(-48, -66), (48, -66), (46, -50), (-46, -50)], fill="#010203", stroke=None)  # visor slit
    head.line([(0, -140), (0, 20)], sw=2.5, opacity=0.5)
    head.line([(-40, -20), (-12, -20)], sw=2, opacity=0.5)
    head.line([(40, -20), (12, -20)], sw=2, opacity=0.5)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-46, -70), (-6, -66), (-6, -50), (-46, -52)], fill=ACCENT, stroke=None)
    eyes.poly([(46, -70), (6, -66), (6, -50), (46, -52)], fill=ACCENT, stroke=None)
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
    w.poly(sc([(-8, 46), (-9, -138), (9, -138), (8, 46)]), fill=DARK2, sw=1.5)
    w.circle(0, 54 * K, 14, fill=DARK2, sw=2)
    w.poly(sc([(-62, -128), (-70, -150), (-30, -150), (0, -138), (30, -150), (70, -150), (62, -128), (0, -118)]), fill=DARK2, sw=2)
    w.poly(sc([(-24, -148), (-28, -280), (-26, -440), (0, -520), (26, -440), (28, -280), (24, -148)]))
    w.line(sc([(-26, -150), (-30, -280), (-28, -440), (0, -522)]), color=ACCENT, sw=9, opacity=1.0)
    w.line(sc([(26, -150), (30, -280), (28, -440), (0, -522)]), color=ACCENT, sw=9, opacity=1.0)
    w.line(sc([(0, -150), (0, -470)]), sw=2.5, opacity=0.5)
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
