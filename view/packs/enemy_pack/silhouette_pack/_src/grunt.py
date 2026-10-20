from rigkit import *

ACCENT = "#8fe04a"
H = (512, 700)          # hips
SL, SR = (377, 488), (647, 488)
N = (512, 462)          # neck
L1, L2 = 118, 148       # upper arm, forearm (hand centre at its end)


def limb(side):
    s = -1 if side == "l" else 1
    up = Art()
    up.circle(0, 118, 22, fill=DARK, sw=2)
    up.smooth([(-25, -4), (-27, 44), (-17, 114), (0, 126), (16, 114), (24, 44), (26, -4), (0, -24)])
    up.poly([(-26, 0), (-34, 30), (-14, 46), (-6, 20)], fill=DARK2, sw=1.5)  # torn sleeve
    up.line([(-22, 6), (-24, 60), (-15, 112)], sw=2)
    fo = Art()
    fo.circle(0, 0, 20, fill=DARK, sw=2)  # elbow joint
    fo.smooth([(-17, -10), (-20, 60), (-14, 122), (14, 122), (20, 60), (17, -10), (0, -16)])
    fo.line([(-15, 0), (-17, 70), (-12, 118)], sw=2)
    fo.ellipse(0, 144, 22, 23)
    if side == "l":  # open clawed hand
        for dx, ln in ((-15, 42), (0, 56), (15, 42)):
            fo.poly([(dx - 5, 156), (dx + 5, 156), (dx + dx * 0.15, 156 + ln)], sw=1.5)
    return up, fo


def build(out_dir):
    R = Rig("grunt", ACCENT)

    legs = Art()
    left = [(-78, 0), (-102, 60), (-114, 125), (-98, 190), (-92, 248), (-130, 262), (-136, 277), (-50, 277),
            (-54, 246), (-66, 190), (-62, 125), (-40, 60), (-24, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    legs.line([(-100, 66), (-108, 125), (-94, 188)], sw=2)
    legs.line([(100, 66), (108, 125), (94, 188)], sw=2, opacity=0.35)
    legs.poly([(-98, 120), (-126, 150), (-108, 170)], fill=DARK2, sw=1.5)  # knee wrap
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-58, 12), (-72, -60), (-94, -130), (-134, -186), (-160, -222), (-146, -262), (-104, -290),
               (-50, -314), (14, -320), (80, -300), (140, -262), (160, -222), (134, -186), (94, -130),
               (74, -60), (58, 12), (44, 46), (28, 14), (10, 52), (-8, 16), (-28, 54), (-46, 18)])
    # ragged cloth hem and ribs
    body.poly([(-62, 10), (-84, 62), (-60, 40), (-48, 74), (-30, 30)], fill=DARK2, sw=1.5)
    body.poly([(62, 10), (86, 58), (62, 38), (50, 70), (30, 30)], fill=DARK2, sw=1.5)
    for y in (-150, -115, -80):
        body.line([(-62, y), (-18, y + 12)], sw=2, opacity=0.4)
        body.line([(62, y), (18, y + 12)], sw=2, opacity=0.4)
    body.line([(0, -250), (0, -20)], sw=2, opacity=0.3)
    body.line([(-150, -226), (-100, -262), (-34, -282)], sw=2.5, opacity=0.8)
    body.line([(-160, -222), (-134, -186), (-96, -130)], sw=2, opacity=0.5)
    R.part("body", "", H, 1, body)

    head = Art()
    head.poly([(-46, 2), (-62, -40), (-54, -86), (-24, -120), (8, -138), (30, -164), (40, -122), (60, -76),
               (56, -30), (42, 2), (22, 20), (0, 8), (-22, 20)])
    head.poly([(-34, -30), (-38, -70), (-14, -98), (14, -98), (38, -70), (34, -30), (18, -8), (-18, -8)],
              fill="#020305", stroke=None)
    head.line([(-60, -44), (-52, -84), (-24, -118), (8, -136)], sw=2.5, opacity=0.8)
    head.poly([(-20, -4), (-14, 14), (-8, -2), (0, 16), (8, -2), (14, 14), (20, -4)], fill="#0d1016", sw=1.5)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-32, -72), (-8, -60), (-10, -46), (-34, -56)], fill=ACCENT, stroke=None)
    eyes.poly([(32, -72), (8, -60), (10, -46), (34, -56)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    w = Art()
    w.poly([(-6, 30), (-7, -12), (7, -12), (6, 30)], fill=DARK2, sw=1.5)
    w.poly([(-26, -10), (-26, -22), (26, -22), (26, -10)], fill=DARK2, sw=1.5)
    w.poly([(16, -22), (20, -120), (15, -196), (-2, -242), (-18, -198), (-24, -120), (-17, -22)])
    w.line([(-17, -26), (-24, -120), (-18, -198), (-2, -242)], color=ACCENT, sw=9, opacity=1.0)
    w.line([(4, -30), (4, -170)], sw=2, opacity=0.35)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 8, w, glow=True)

    rig = R.build_layout(out_dir)

    def pose(name, body=(0, 0, 0), head=0, legs=(0, 0, 0), hr=None, hl=None, blade=0, bend_r=-1, bend_l=1,
             grip_l=None, extra=None):
        p = R.new_pose()
        p.set("body", body[0], (body[1], body[2]))
        p.set("legs", legs[0], (legs[1], legs[2]))
        p.set("head", head, (0, 12))
        if extra:
            for k, v in extra.items():
                p.set(k, *v)
        if hr:
            p.arm("arm_r", "forearm_r", hr, L1, L2, bend_r)
            p.hold("weapon", "forearm_r", blade)
        if grip_l is not None:
            wp = p.pivot("weapon")
            a = math.radians(blade)
            hl = (wp[0] + math.sin(a) * grip_l, wp[1] - math.cos(a) * grip_l)
        if hl:
            p.arm("arm_l", "forearm_l", hl, L1, L2, bend_l)
        R.poses[name] = p

    pose("idle", body=(2, 0, 0), head=-3, hr=(672, 740), blade=26, hl=(362, 748))
    pose("windup_quick", body=(-9, 6, 4), head=6, hr=(722, 548), blade=78, hl=(360, 640), bend_r=-1)
    pose("strike_quick", body=(12, -16, 22), head=10, hr=(470, 640), blade=-78, hl=(330, 560), bend_r=1)
    pose("windup_heavy", body=(-12, 0, -4), head=-8, hr=(578, 318), blade=-8, grip_l=-46, bend_r=1, bend_l=-1)
    pose("strike_heavy", body=(20, -10, 46), head=16, hr=(540, 760), blade=172, grip_l=-46, bend_r=-1, bend_l=1)
    pose("windup_feint", body=(-5, -12, 6), head=-16, hr=(680, 370), blade=40, hl=(335, 585), bend_r=1)
    pose("windup_combo", body=(10, -10, 4), head=10, hr=(330, 590), blade=-92, hl=(660, 600), bend_r=-1, bend_l=-1)
    pose("strike_combo", body=(-12, 14, 14), head=-8, hr=(700, 580), blade=96, hl=(440, 600), bend_r=1, bend_l=1)
    pose("recover", body=(10, 0, 30), head=18, hr=(630, 800), blade=148, hl=(390, 790))
    pose("staggered", body=(-18, 0, 16), head=-22, hr=(790, 520), blade=62, hl=(300, 520), bend_r=1, bend_l=-1)
    pose("hurt", body=(-9, 0, 6), head=-12, hr=(640, 640), blade=18, hl=(392, 640))
    pose("death", body=(-84, 30, 118), head=-10, legs=(-86, 30, 118), hr=(300, 950), blade=-100, hl=(400, 930),
         bend_r=1, bend_l=-1)
    R.write_rig()
    return R
