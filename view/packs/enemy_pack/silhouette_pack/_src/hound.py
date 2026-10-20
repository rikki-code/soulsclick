from rigkit import *

# Chain Hound: low, fast skirmisher. Crouched wolf-eared, spiked collar, chain wraps, hooked sickle.
ACCENT = "#ff9a1f"
H = (512, 760)
SL, SR = (384, 548), (640, 548)
N = (512, 540)
L1, L2 = 125, 150


def limb(side):
    s = -1 if side == "l" else 1
    up = Art()
    up.smooth([(-20, -4), (-22, 44), (-15, 118), (0, 128), (15, 118), (21, 44), (20, -4), (0, -22)])
    up.line([(-17, 6), (-19, 60), (-12, 114)], sw=2, opacity=0.6)
    up.poly([(-20, 70), (-20, 90), (20, 90), (20, 70)], fill=DARK2, sw=1.5)  # chain wrap
    fo = Art()
    fo.circle(0, 0, 18, fill=DARK, sw=2)
    fo.poly([(s * 12, -4), (s * 44, 20), (s * 14, 30)], fill=DARK2, sw=1.5)  # elbow spur
    fo.smooth([(-16, -10), (-18, 60), (-13, 126), (13, 126), (18, 60), (16, -10), (0, -14)])
    fo.poly([(-18, 50), (-18, 66), (18, 66), (18, 50)], fill=DARK2, sw=1.5)
    fo.ellipse(0, 148, 20, 21)
    if side == "l":
        for dx, ln in ((-14, 44), (0, 58), (14, 44)):
            fo.poly([(dx - 5, 160), (dx + 5, 160), (dx + dx * 0.2, 160 + ln)], sw=1.5)
    return up, fo


def build(out_dir):
    R = Rig("hound", ACCENT)

    legs = Art()
    left = [(-70, 0), (-112, 50), (-126, 92), (-96, 140), (-86, 180), (-128, 200), (-136, 215), (-58, 215),
            (-60, 190), (-56, 140), (-48, 80), (-24, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    legs.line([(-116, 56), (-124, 92), (-96, 140)], sw=2, opacity=0.5)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(40, -4), (120, 14), (186, -22), (214, -96), (196, -60), (150, -34), (70, 34)], fill=DARK2, sw=1.5)  # tail
    body.poly([(-50, 10), (-62, -60), (-100, -130), (-150, -190), (-168, -225), (-130, -256), (-60, -268),
               (0, -262), (60, -268), (130, -256), (168, -225), (150, -190), (100, -130), (62, -60), (50, 10),
               (30, 40), (10, 14), (-12, 44), (-32, 16)])
    for x, h in ((-130, 50), (-84, 40), (84, 40), (130, 50)):  # spiked collar
        body.poly([(x - 18, -252), (x + 4, -252 - h - 14), (x + 20, -246)], fill=DARK, sw=1.5)
    for y in (-170, -128, -90):
        body.line([(-60, y), (-18, y + 12)], sw=2, opacity=0.4)
        body.line([(60, y), (18, y + 12)], sw=2, opacity=0.4)
    # chain bandolier
    for i in range(8):
        t = i / 7
        body.ellipse(-110 + 200 * t, -210 + 170 * t, 12, 8, fill=DARK, stroke=HI, sw=2.5, rot=40 + (i % 2) * 90)
    body.line([(-168, -225), (-130, -256), (-60, -268)], sw=2.5, opacity=0.8)
    body.line([(-160, -222), (-134, -186), (-100, -130)], sw=2, opacity=0.5)
    R.part("body", "", H, 1, body)

    head = Art()
    head.poly([(-50, 2), (-66, -40), (-62, -80), (-84, -156), (-36, -112), (-14, -122), (14, -122), (36, -112),
               (84, -156), (62, -80), (66, -40), (50, 2), (28, 24), (0, 34), (-28, 24)])
    head.poly([(-40, -58), (-14, -92), (14, -92), (40, -58), (30, -12), (0, -2), (-30, -12)], fill="#020305", stroke=None)
    head.poly([(-24, 4), (-18, 22), (-10, 6), (0, 24), (10, 6), (18, 22), (24, 4)], fill="#0d1016", sw=1.5)
    head.line([(-66, -42), (-62, -80), (-84, -154)], sw=2.5, opacity=0.8)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-38, -66), (-10, -54), (-12, -42), (-40, -52)], fill=ACCENT, stroke=None)
    eyes.poly([(38, -66), (10, -54), (12, -42), (40, -52)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    w = Art()  # hooked sickle with a short chain tail
    w.poly([(-6, 34), (-7, -50), (7, -50), (6, 34)], fill=DARK2, sw=1.5)
    w.poly([(-22, -46), (-22, -60), (22, -60), (22, -46)], fill=DARK2, sw=1.5)
    w.poly([(-8, -60), (-6, -150), (14, -214), (60, -252), (126, -256), (92, -226), (66, -190), (40, -132), (26, -60)])
    w.line([(26, -64), (40, -132), (66, -190), (92, -226), (126, -256)], color=ACCENT, sw=9, opacity=1.0)
    w.line([(-4, -70), (-2, -150)], sw=2, opacity=0.4)
    for i in range(3):
        w.ellipse(0, 50 + i * 20, 9 if i % 2 == 0 else 5, 13, fill=DARK, stroke=HI, sw=3)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 8, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    hm = (0, 10)
    pose("idle", body=(3, 0, 0), head=-4, hr=(700, 790), blade=24, hl=(330, 790), hmove=hm)
    pose("windup_quick", body=(-12, -6, 16), head=8, hr=(740, 640), blade=84, hl=(350, 720), hmove=hm)
    pose("strike_quick", body=(16, -22, 34), head=12, hr=(470, 720), blade=-84, hl=(320, 640), bend_r=1, hmove=hm)
    pose("windup_heavy", body=(-14, 0, -8), head=-10, hr=(600, 400), blade=-8, hl=(430, 440), bend_r=1, bend_l=-1, hmove=hm)
    pose("strike_heavy", body=(24, -10, 60), head=18, hr=(540, 650), blade=150, hl=(450, 700), bend_r=-1, hmove=hm)
    pose("windup_feint", body=(-6, -14, 14), head=-18, hr=(700, 450), blade=44, hl=(335, 690), bend_r=1, hmove=hm)
    pose("windup_combo", body=(12, -12, 10), head=10, hr=(330, 690), blade=-98, hl=(660, 700), bend_r=-1, bend_l=-1, hmove=hm)
    pose("strike_combo", body=(-14, 16, 22), head=-8, hr=(720, 680), blade=100, hl=(440, 700), bend_r=1, bend_l=1, hmove=hm)
    pose("recover", body=(12, 0, 44), head=20, hr=(650, 720), blade=125, hl=(390, 800), hmove=hm)
    pose("staggered", body=(-20, 0, 26), head=-22, hr=(760, 600), blade=30, hl=(290, 590), bend_r=1, bend_l=-1, hmove=hm)
    pose("hurt", body=(-10, 0, 12), head=-12, hr=(660, 720), blade=18, hl=(390, 720), hmove=hm)
    pose("death", body=(-84, 30, 60), head=-10, legs=(-86, 30, 60), hr=(300, 950), blade=-100, hl=(400, 930),
         bend_r=1, bend_l=-1, hmove=hm)
    R.write_rig()
    return R
