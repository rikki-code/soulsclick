from rigkit import *
from shapes import tube

# Ash Thrall: hunched, head hanging, one overlong arm dragging an ember-cracked club.
ACCENT = "#e5372b"
H = (512, 780)
SR = (630, 520)
N = (500, 520)
L1, L2 = 165, 175


def build(out_dir):
    R = Rig("thrall", ACCENT)

    legs = Art()
    left = [(-62, 0), (-84, 64), (-74, 124), (-90, 170), (-116, 186), (-118, 195), (-38, 195), (-44, 172), (-40, 124),
            (-34, 64), (-14, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    legs.line([(-80, 66), (-72, 124)], sw=2, opacity=0.5)
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-55, 10), (-80, -60), (-96, -150), (-92, -230), (-52, -282), (10, -296), (70, -334), (132, -300),
               (152, -220), (122, -120), (68, -40), (56, 10), (20, 36), (-20, 24)])
    for x, ln in ((-44, 70), (-10, 96), (26, 60), (50, 84)):  # rag strips at the waist
        body.poly([(x - 14, 0), (x + 14, 0), (x + 8, ln), (x - 6, ln + 12)], fill=DARK2, sw=1.5)
    body.poly(tube([(-86, -200), (-110, -150), (-100, -90), (-92, -40)], 15, 11), fill=DARK2, sw=1.5)  # withered left arm
    body.circle(-92, -34, 13, fill=DARK, sw=1.5)
    for y in (-210, -170, -130):  # ribs showing through
        body.line([(10, y), (60, y + 20)], sw=2, opacity=0.4)
    body.line([(-52, -282), (10, -296), (70, -334), (132, -300)], sw=2.5, opacity=0.8)
    R.part("body", "", H, 1, body)

    head = Art()
    head.poly([(-30, -14), (20, -22), (56, 8), (62, 68), (42, 118), (14, 152), (-18, 142), (-48, 100), (-62, 40)])
    head.poly([(-22, 96), (8, 108), (6, 138), (-16, 130)], fill="#020305", stroke=None)  # slack jaw
    head.line([(-30, -14), (20, -22), (56, 8)], sw=2.5, opacity=0.8)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-36, 52), (-10, 62), (-12, 74), (-38, 66)], fill=ACCENT, stroke=None)
    eyes.poly([(18, 62), (42, 54), (44, 68), (20, 76)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    up = Art()
    up.circle(0, 0, 26, fill=DARK, sw=2)
    up.poly(tube([(0, 0), (4, 80), (0, 165)], 20, 15), sw=2)
    up.circle(0, 165, 17, fill=DARK, sw=2)
    up.line([(-16, 20), (-12, 90)], sw=2, opacity=0.5)
    fo = Art()
    fo.circle(0, 0, 16, fill=DARK, sw=2)
    fo.poly(tube([(0, 0), (-3, 90), (0, 160)], 15, 13), sw=2)
    fo.ellipse(0, 180, 24, 28)
    for dx in (-14, 0, 14):
        fo.poly([(dx - 6, 192), (dx + 6, 192), (dx + dx * 0.3, 232)], sw=1.5)
    R.part("arm_r", "body", SR, 4, up)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 5, fo)

    w = Art()  # club: handle with ember-cracked knob
    w.poly([(-9, 60), (-10, -70), (10, -70), (9, 60)], fill=DARK2, sw=1.5)
    w.poly([(-20, -60), (-52, -112), (-66, -170), (-46, -230), (0, -250), (46, -230), (66, -170), (52, -112), (20, -60)])
    w.poly([(-60, -140), (60, -140), (62, -158), (-62, -158)], fill=DARK2, sw=1.5)
    for x, y in ((-34, -210), (36, -206), (-50, -176), (52, -172)):
        w.poly([(x - 7, y), (x, y - 20), (x + 7, y)], fill=DARK2, sw=1.2)
    w.line([(-4, -88), (-18, -124), (10, -168), (-14, -206), (14, -236)], color=ACCENT, sw=9, opacity=1.0)
    w.line([(-10, -100), (-14, -180)], sw=2, opacity=0.4)
    w.line([(-52, -112), (-66, -170), (-46, -230), (0, -250)], sw=2.5, opacity=0.8)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 6, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    pose("idle", body=(3, 0, 0), head=-3, hr=(700, 830), blade=25)
    pose("windup_quick", body=(-10, -6, 14), head=6, hr=(740, 660), blade=75)
    pose("strike_quick", body=(14, -20, 30), head=8, hr=(470, 700), blade=-85, bend_r=1)
    pose("windup_heavy", body=(-14, 0, -6), head=-10, hr=(650, 340), blade=8, bend_r=1)
    pose("strike_heavy", body=(24, -10, 50), head=20, hr=(560, 700), blade=160, bend_r=-1)
    pose("windup_feint", body=(-6, -14, 16), head=-24, hr=(720, 720), blade=50)
    pose("windup_combo", body=(12, -12, 10), head=10, hr=(470, 780), blade=-100, bend_r=-1)
    pose("strike_combo", body=(-14, 16, 22), head=-8, hr=(740, 780), blade=95, bend_r=1)
    pose("recover", body=(12, 0, 40), head=22, hr=(690, 820), blade=125)
    pose("staggered", body=(-20, 0, 26), head=-22, hr=(790, 560), blade=40, bend_r=1)
    pose("hurt", body=(-10, 0, 12), head=-12, hr=(700, 790), blade=20)
    pose("death", body=(-84, 30, 60), head=-10, legs=(-86, 30, 60), hr=(150, 880), blade=60, bend_r=1)
    R.write_rig()
    return R
