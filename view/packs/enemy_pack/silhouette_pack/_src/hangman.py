from rigkit import *

# Hanged Executioner: huge, slow, sack-hooded, noose rope around the neck, bare scarred slab, giant notched cleaver.
ACCENT = "#d0452b"
H = (512, 680)
SL, SR = (366, 392), (658, 392)
N = (512, 376)
L1, L2 = 135, 160


def limb(side):
    s = -1 if side == "l" else 1
    up = Art()
    up.smooth([(-36, -6), (-42, 50), (-34, 124), (0, 138), (34, 124), (42, 50), (36, -6), (0, -28)])
    up.line([(-32, 6), (-38, 60), (-30, 120)], sw=3, opacity=0.6)
    if side == "l":
        up.poly([(-40, 20), (-70, 10), (-60, 50)], fill=DARK, sw=1.5)
    # scar stitches
    for y in (40, 62, 84):
        up.line([(-10, y), (10, y + 6)], sw=2, opacity=0.4)
    fo = Art()
    fo.circle(0, 0, 28, fill=DARK, sw=2)
    fo.poly([(s * 20, -10), (s * 62, 22), (s * 20, 36)], fill=DARK2, sw=1.5)  # elbow spike
    fo.poly([(-32, -8), (-38, 70), (-30, 152), (30, 152), (38, 70), (32, -8)])
    fo.line([(-30, 2), (-36, 70), (-28, 148)], sw=3, opacity=0.6)
    fo.poly([(-40, 46), (-40, 78), (40, 78), (40, 46)], fill=DARK2, sw=2)  # iron cuff
    for x in (-24, 0, 24):
        fo.poly([(x - 6, 46), (x, 30), (x + 6, 46)], fill=DARK, sw=1.2)
    fo.ellipse(0, 170, 30, 28)
    if side == "l":
        for dx in (-20, -7, 7, 20):
            fo.poly([(dx - 6, 186), (dx + 6, 186), (dx * 1.1, 226)], sw=1.2)
    return up, fo


def build(out_dir):
    R = Rig("hangman", ACCENT)

    legs = Art()
    left = [(-110, 0), (-124, 80), (-118, 160), (-122, 232), (-116, 270), (-160, 286), (-166, 295), (-40, 295),
            (-46, 270), (-48, 232), (-46, 160), (-40, 80), (-24, 0)]
    legs.poly(left)
    legs.poly(mirror(left))
    for sx in (-1, 1):
        legs.poly([(sx * 124, 232), (sx * 40, 232), (sx * 44, 264), (sx * 120, 268)], fill=DARK2, sw=1.5)  # boot cuffs
        legs.line([(sx * 118, 90), (sx * 120, 150)], sw=2, opacity=0.5)
    legs.poly([(-110, -6), (-120, 150), (-96, 120), (-84, 190), (-56, 120), (-40, 160), (0, 100), (40, 160), (56, 120),
               (84, 190), (96, 120), (120, 150), (110, -6)], fill=DARK2, sw=1.5)  # apron skirt
    R.part("legs", "", H, 0, legs)

    body = Art()
    body.poly([(-100, 10), (-120, -60), (-142, -160), (-170, -250), (-150, -296), (-80, -318), (0, -324), (80, -318),
               (150, -296), (170, -250), (142, -160), (120, -60), (100, 10)])
    body.poly([(-70, 6), (-90, -80), (-62, -190), (0, -214), (62, -190), (90, -80), (70, 6)], fill=DARK2, sw=1.5)  # apron
    body.line([(-60, -186), (0, -208), (62, -186)], sw=1.5, color=HI, opacity=0.4)
    # chains crossing the chest
    for i in range(9):
        t = i / 8
        body.ellipse(-100 + 200 * t, -280 + 190 * t, 12, 8, fill=DARK, stroke=HI, sw=2.5, rot=40 + (i % 2) * 90)
        body.ellipse(100 - 200 * t, -280 + 190 * t, 12, 8, fill=DARK, stroke=HI, sw=2.5, rot=-40 + (i % 2) * 90)
    # stitched scars
    for y in (-130, -100, -70):
        body.line([(80, y), (120, y - 6)], sw=2, opacity=0.5)
    # iron spiked pauldron (left) and bare shoulder knots (right)
    body.poly([(-170, -300), (-100, -318), (-90, -240), (-176, -226), (-206, -262)], fill=DARK2, sw=2.5)
    for p in ((-206, -262, -266, -300), (-190, -226, -262, -230), (-150, -300, -178, -378), (-110, -312, -112, -386)):
        body.poly([(p[0], p[1] - 18), (p[2], p[3]), (p[0] + 22, p[1] + 14)], fill=DARK, sw=1.5)
    body.line([(-176, -226), (-206, -262), (-170, -300), (-100, -318)], sw=3, opacity=0.8)
    body.line([(-150, -296), (-80, -318), (0, -324), (80, -318), (150, -296)], sw=3, opacity=0.8)
    body.poly([(150, -296), (178, -270), (172, -230), (150, -240)], fill=DARK2, sw=1.5)
    R.part("body", "", H, 1, body)

    head = Art()
    # noose rope coil around the neck + long frayed tail rising beside the hood
    for i in range(4):
        head.ellipse(0, 4 - i * 12, 62 - i * 2, 14, fill=DARK2, stroke=HI, sw=3, opacity=None)
    head.poly([(44, -8), (72, -100), (60, -170), (74, -226), (96, -262), (86, -220), (92, -170), (96, -100), (62, 0)],
              fill=DARK2, sw=2)
    head.line([(54, -10), (72, -100), (62, -170), (74, -226)], color=HI, sw=2, opacity=0.5)
    head.ellipse(98, -282, 16, 22, fill="none", stroke=HI, sw=5, rot=-12)  # frayed loop end
    # sack hood
    head.poly([(-60, -4), (-78, -60), (-72, -116), (-50, -160), (-16, -184), (0, -194), (16, -184), (50, -160), (72, -116),
               (78, -60), (60, -4), (30, 8), (0, 14), (-30, 8)])
    head.poly([(-8, -194), (6, -240), (22, -186)], fill=DARK, sw=1.5)  # knot top
    head.line([(-78, -60), (-72, -116), (-50, -160), (-16, -184), (0, -194)], sw=3, opacity=0.8)
    head.line([(0, -190), (0, 10)], sw=1.5, opacity=0.35)
    # hollow eye holes and stitched mouth
    head.poly([(-50, -104), (-14, -92), (-18, -52), (-46, -60), (-58, -84)], fill="#010203", stroke=None)
    head.poly([(50, -104), (14, -92), (18, -52), (46, -60), (58, -84)], fill="#010203", stroke=None)
    head.line([(-34, -18), (34, -18)], sw=2.5, opacity=0.7)
    for x in (-28, -14, 0, 14, 28):
        head.line([(x, -28), (x, -8)], sw=2.5, opacity=0.7)
    R.part("head", "body", N, 2, head)

    eyes = Art()
    eyes.poly([(-40, -90), (-20, -82), (-22, -66), (-40, -72)], fill=ACCENT, stroke=None)
    eyes.poly([(40, -90), (20, -82), (22, -66), (40, -72)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 3, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 4, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 5, fl)
    R.part("arm_r", "body", SR, 6, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 7, fr)

    w = Art()  # giant notched cleaver, edge on the right, spiked spine, punched hole, chain tail
    w.poly([(-14, 60), (-14, -60), (14, -60), (14, 60)], fill=DARK2, sw=2)
    w.circle(0, 70, 18, fill=DARK2, sw=2.5)
    w.poly([(-34, -52), (-38, -72), (40, -72), (36, -52)], fill=DARK, sw=2)
    def S(pts):
        return [(x * 0.78, -72 + (y + 72) * 0.78) for x, y in pts]
    w.poly(S([(-20, -72), (-24, -330), (-6, -352), (50, -356), (130, -348), (150, -318), (158, -240), (148, -150),
              (138, -110), (112, -86), (14, -72)]))
    for y in (-300, -230, -160):  # spine spikes
        w.poly(S([(-24, y), (-60, y - 22), (-22, y - 40)]), fill=DARK, sw=1.5)
    hx, hy = S([(56, -222)])[0]
    w.circle(hx, hy, 16, fill="#020304", stroke=RIM, sw=2.5)
    w.line(S([(12, -90), (20, -300), (24, -340)]), sw=2, opacity=0.5)
    w.line(S([(130, -348), (150, -318), (158, -240), (148, -150), (138, -110)]), color=ACCENT, sw=9, opacity=1.0)
    w.line(S([(46, -354), (130, -348)]), color=ACCENT, sw=7, opacity=1.0)
    for i in range(4):
        w.ellipse(0, 100 + i * 20, 9 if i % 2 == 0 else 5, 13, fill=DARK, stroke=HI, sw=3)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 8, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)
    pose("idle", body=(2, 0, 0), head=-3, hr=(730, 760), blade=10, hl=(330, 740))
    pose("windup_quick", body=(-8, -6, 8), head=6, hr=(690, 640), blade=66, hl=(330, 680))
    pose("strike_quick", body=(12, -14, 22), head=10, hr=(500, 700), blade=-76, hl=(330, 620), bend_r=1)
    pose("windup_heavy", body=(-10, 0, -2), head=-8, hr=(620, 440), blade=30, hl=(420, 470), bend_r=1, bend_l=-1)
    pose("strike_heavy", body=(18, -8, 50), head=18, hr=(580, 640), blade=150, hl=(440, 650), bend_r=-1)
    pose("windup_feint", body=(-3, -12, 20), head=-16, hr=(690, 580), blade=44, hl=(350, 640), bend_r=-1)
    pose("windup_combo", body=(10, -10, 8), head=10, hr=(440, 700), blade=-84, hl=(700, 640), bend_r=1, bend_l=-1)
    pose("strike_combo", body=(-12, 14, 14), head=-8, hr=(610, 700), blade=86, hl=(420, 650), bend_r=-1, bend_l=1)
    pose("recover", body=(10, 0, 40), head=18, hr=(640, 780), blade=116, hl=(400, 800))
    pose("staggered", body=(-16, 0, 18), head=-20, hr=(750, 580), blade=20, hl=(270, 580), bend_r=1, bend_l=-1)
    pose("hurt", body=(-8, 0, 8), head=-10, hr=(710, 740), blade=14, hl=(350, 730))
    pose("death", body=(-84, 90, 80), head=50, legs=(-86, 90, 80), hr=(600, 950), blade=-96, hl=(540, 930),
         bend_r=1, bend_l=-1)
    R.write_rig()
    return R
