from rigkit import *

# Bell Bulwark: squat bell-shaped giant with a tower shield and a bell-headed mace. Heavies, brass accent.
ACCENT = "#e3c66a"
H = (512, 700)
SL, SR = (344, 470), (680, 470)
N = (512, 440)
L1, L2 = 130, 150


def limb(side):
    up = Art()
    up.smooth([(-34, -6), (-36, 50), (-26, 120), (0, 134), (26, 120), (36, 50), (34, -6), (0, -30)])
    up.line([(-30, 8), (-32, 60), (-22, 118)], sw=2.5, opacity=0.6)
    up.circle(0, 128, 30, fill=DARK2, sw=2)
    fo = Art()
    fo.circle(0, 0, 30, fill=DARK2, sw=2)
    fo.poly([(-28, -24), (-32, 60), (-26, 124), (26, 124), (32, 60), (28, -24)])
    fo.line([(-26, 6), (-29, 62), (-23, 120)], sw=2.5, opacity=0.6)
    fo.poly([(-31, 44), (-31, 76), (31, 76), (31, 44)], fill=DARK2, sw=1.5)
    fo.smooth([(-28, 124), (-32, 148), (-20, 172), (20, 172), (32, 148), (28, 124)])
    return up, fo


def build(out_dir):
    R = Rig("bulwark", ACCENT)

    legs = Art()
    left = [(-90, 0), (-112, 70), (-122, 130), (-108, 200), (-104, 250), (-142, 266), (-148, 275), (-52, 275),
            (-58, 248), (-70, 200), (-62, 130), (-42, 70), (-22, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    for sx in (-1, 1):
        legs.poly([(sx * 122, 120), (sx * 62, 120), (sx * 72, 156), (sx * 116, 160)], fill=DARK2, sw=1.5)
    R.part("legs", "", H, 0, legs)

    body = Art()
    # bell-shaped cloak: narrow shoulders flaring to a wide hem
    body.poly([(-50, -250), (-100, -190), (-150, -110), (-200, -10), (-232, 50), (-170, 76), (-110, 60), (-60, 84),
               (0, 66), (60, 84), (110, 60), (170, 76), (232, 50), (200, -10), (150, -110), (100, -190), (50, -250)])
    body.poly([(-92, -200), (-130, -110), (-170, -20), (-120, 20), (-60, 24), (0, 30), (60, 24), (120, 20),
               (170, -20), (130, -110), (92, -200), (0, -226)], fill=DARK2, sw=2)
    for x in (-110, -55, 0, 55, 110):  # bell ribs
        body.line([(x * 0.55, -210), (x * 1.3, 20)], sw=2.5, opacity=0.4)
    body.line([(-232, 50), (-200, -10), (-150, -110), (-100, -190), (-50, -250)], sw=3, opacity=0.8)
    body.line([(-170, 76), (-110, 60), (-60, 84)], sw=2.5, opacity=0.6)
    # round pauldrons
    for sx in (-1, 1):
        body.ellipse(sx * 128, -210, 70, 54, fill=DARK2, sw=2.5, rot=sx * -12)
        body.line([(sx * 70, -240), (sx * 128, -266), (sx * 186, -230)], sw=3, opacity=0.8)
    R.part("body", "", H, 1, body)

    head = Art()
    head.circle(0, -176, 22, fill="none", stroke=HI, sw=5, opacity=None)  # bell loop
    head.poly([(-86, 14), (-92, -40), (-80, -100), (-48, -142), (-14, -158), (14, -158), (48, -142), (80, -100),
               (92, -40), (86, 14), (50, 24), (0, 28), (-50, 24)])
    head.poly([(-92, 2), (-100, 22), (100, 22), (92, 2)], fill=DARK2, sw=2)  # flared lip
    head.poly([(-60, -62), (60, -62), (56, -40), (-56, -40)], fill="#010203", stroke=None)
    head.line([(-92, -40), (-80, -100), (-48, -142), (-14, -158)], sw=3, opacity=0.8)
    head.line([(0, -156), (0, -62)], sw=2.5, opacity=0.4)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-54, -60), (-8, -58), (-8, -44), (-52, -44)], fill=ACCENT, stroke=None)
    eyes.poly([(54, -60), (8, -58), (8, -44), (52, -44)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    w = Art()  # bell-headed mace: the mouth of the bell is the striking face
    w.poly([(-10, 50), (-10, -190), (10, -190), (10, 50)], fill=DARK2, sw=2)
    w.circle(0, 58, 14, fill=DARK2, sw=2)
    w.poly([(-20, -176), (-28, -250), (-16, -290), (0, -300), (16, -290), (28, -250), (20, -176)], fill=DARK, sw=2)
    w.poly([(-22, -236), (-64, -200), (-96, -160), (96, -160), (64, -200), (22, -236)], fill=DARK, sw=2)
    w.line([(-96, -162), (96, -162)], color=ACCENT, sw=9, opacity=1.0)
    w.circle(0, -142, 16, fill=ACCENT, stroke=None)
    w.line([(-22, -176), (-28, -250), (-16, -290), (0, -300)], sw=2.5, opacity=0.8)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 8, w, glow=True)

    sh = Art()  # tower shield, pivot at the grip
    sh.poly([(-84, -196), (-72, -226), (0, -240), (72, -226), (84, -196), (92, 50), (62, 150), (0, 196), (-62, 150), (-92, 50)],
            fill=DARK2, sw=3)
    sh.poly([(-62, -176), (-54, -200), (0, -212), (54, -200), (62, -176), (68, 40), (44, 122), (0, 160), (-44, 122), (-68, 40)],
            fill=DARK, sw=2)
    sh.line([(-84, -196), (-72, -226), (0, -240), (72, -226)], sw=3, opacity=0.8)
    sh.line([(-92, 50), (-84, -196)], sw=2.5, opacity=0.6)
    sh.line([(0, -206), (0, 154)], sw=2.5, opacity=0.4)
    sh.line([(-66, -60), (66, -60)], sw=2.5, opacity=0.4)
    sh.circle(0, -20, 30, fill=DARK2, stroke=HI, sw=3)
    sh.circle(0, -20, 12, fill=DARK, sw=2)
    R.part("shield", "forearm_l", (SL[0], SL[1] + L1 + L2), 9, sh)

    R.build_layout(out_dir)
    base = make_pose_fn(R, L1, L2)

    def pose(name, sd=0, **kw):
        p = base(name, **kw)
        p.hold("shield", "forearm_l", sd)
        return p

    pose("idle", body=(1, 0, 0), head=-2, hr=(720, 720), blade=14, hl=(330, 660), sd=-4)
    pose("windup_quick", body=(-8, 10, 4), head=6, hr=(730, 620), blade=48, hl=(330, 600), sd=-6)
    pose("strike_quick", body=(14, -12, 18), head=10, hr=(560, 640), blade=-72, hl=(500, 600), sd=-10, bend_r=1)
    pose("windup_heavy", body=(-10, 6, -4), head=-8, hr=(660, 330), blade=6, hl=(300, 600), sd=-8, bend_r=-1)
    pose("strike_heavy", body=(18, -12, 40), head=18, hr=(580, 710), blade=165, hl=(310, 660), sd=-8, bend_r=-1)
    pose("windup_feint", body=(-4, -8, 22), head=-16, hr=(720, 470), blade=44, hl=(330, 630), sd=-12, bend_r=-1)
    pose("windup_combo", body=(10, -12, 6), head=10, hr=(420, 620), blade=-92, hl=(470, 620), sd=24, bend_r=1)
    pose("strike_combo", body=(-12, 16, 14), head=-8, hr=(700, 600), blade=96, hl=(290, 660), sd=-14, bend_r=-1)
    pose("recover", body=(10, 0, 30), head=18, hr=(650, 770), blade=118, hl=(330, 740), sd=-4)
    pose("staggered", body=(-16, 0, 16), head=-22, hr=(770, 540), blade=36, hl=(270, 530), sd=-40, bend_r=1, bend_l=-1)
    pose("hurt", body=(-8, 0, 6), head=-12, hr=(700, 680), blade=14, hl=(340, 650), sd=-6)
    pose("death", body=(-84, 60, 70), head=-10, legs=(-86, 60, 70), hr=(480, 920), blade=-100, hl=(330, 880), sd=80,
         bend_r=1, bend_l=-1)
    R.write_rig()
    return R
