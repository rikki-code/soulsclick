from rigkit import *

# Reliquary Wretch: low crawling husk, a bone cage grown on its back, four extra spidery arms, a rake of nail-blades.
ACCENT = "#e9e2c6"  # pale bone
H = (512, 800)
SL, SR = (396, 604), (628, 604)
N = (512, 608)
L1, L2 = 115, 140


def tube(c, w0, w1):
    """Tapered polygon along the centerline c (list of points), width w0 at the start to w1 at the end."""
    left, right = [], []
    m = len(c)
    for i, (x, y) in enumerate(c):
        a = c[max(i - 1, 0)]
        b = c[min(i + 1, m - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        d = math.hypot(dx, dy) or 1
        nx, ny = -dy / d, dx / d
        w = (w0 + (w1 - w0) * i / (m - 1)) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


def limb(side):
    s = -1 if side == "l" else 1
    up = Art()
    up.poly(tube([(0, -6), (s * 4, 50), (0, 120)], 34, 22))
    up.line([(-8, 4), (-8, 70), (-4, 114)], sw=2, opacity=0.6)
    up.poly([(-14, 60), (0, 40), (14, 60), (8, 80), (-8, 80)], fill=DARK2, sw=1.2)  # knob joint
    fo = Art()
    fo.circle(0, 0, 14, fill=DARK, sw=2)
    fo.poly([(s * 8, -6), (s * 34, 20), (s * 6, 30)], fill=DARK2, sw=1.5)
    fo.poly(tube([(0, -6), (s * -3, 70), (0, 140)], 26, 14))
    fo.line([(-8, 0), (-10, 70), (-5, 130)], sw=2, opacity=0.6)
    fo.ellipse(0, 156, 14, 18)
    for dx, ln in ((-10, 46), (-3, 60), (4, 60), (11, 46)):
        fo.poly(tube([(dx, 168), (dx * 1.6, 168 + ln * 0.6), (dx * 1.2, 168 + ln)], 6, 1.5), sw=1.2)
    return up, fo


def spider(kind, sx):
    """Extra arm drawn at rest: 'up' arches up/out and hooks in, 'low' reaches out and down to the ground."""
    a = Art()
    if kind == "up":
        c = [(0, 0), (-48, -70), (-96, -150), (-112, -230), (-84, -296), (-40, -318)]
        w = (24, 5)
    else:
        c = [(0, 0), (-56, 10), (-112, 30), (-146, 70), (-152, 112), (-142, 140)]
        w = (24, 5)
    c = [(x if sx == 1 else -x, y) for x, y in c]
    a.poly(tube(c, *w))
    mid = c[len(c) // 2]
    a.circle(mid[0], mid[1], 12, fill=DARK2, sw=2)
    tip = c[-1]
    prev = c[-2]
    d = (tip[0] - prev[0], tip[1] - prev[1])
    dl = math.hypot(*d)
    for k in (-1, 1):  # claw tines
        nx, ny = -d[1] / dl, d[0] / dl
        a.poly([(tip[0] - d[0] * 0.3 + nx * 8 * k, tip[1] - d[1] * 0.3 + ny * 8 * k),
                (tip[0] + d[0] * 0.8 + nx * 22 * k, tip[1] + d[1] * 0.8 + ny * 22 * k),
                (tip[0] + d[0] * 0.2 - nx * 4 * k, tip[1] + d[1] * 0.2 - ny * 4 * k)], fill=DARK, sw=1.2)
    a.line([c[1], c[2], c[3]], sw=2, opacity=0.5)
    return a


def build(out_dir):
    R = Rig("wretch", ACCENT)

    legs = Art()
    left = [(-60, 10), (-130, -14), (-196, 50), (-190, 120), (-220, 170), (-214, 177), (-140, 177), (-130, 150),
            (-132, 100), (-110, 62), (-30, 40)]
    legs.poly(left)
    legs.poly(mirror(left))
    for sx in (-1, 1):
        legs.poly([(sx * 196, 50), (sx * 232, 20), (sx * 188, 18)], fill=DARK, sw=1.5)  # knee thorn
        legs.line([(sx * 186, 52), (sx * 182, 112)], sw=2, opacity=0.5)
    R.part("legs", "", H, 0, legs)

    body = Art()
    # reliquary cage grown out of the back, bars + finial spikes
    body.poly([(-146, -186), (-110, -346), (-40, -384), (0, -394), (40, -384), (110, -346), (146, -186), (96, -204),
               (0, -216), (-96, -204)], fill="#06080b", sw=2.5)
    for x in (-84, -42, 0, 42, 84):
        body.line([(x * 1.2, -204), (x * 0.82, -372)], sw=7, color=DARK2, opacity=1.0)
    body.line([(-120, -300), (0, -318), (120, -300)], sw=6, color=DARK2, opacity=1.0, smooth=True)
    for x, tx, ty in ((-110, -138, -420), (-40, -52, -440), (40, 52, -440), (110, 138, -420)):
        body.poly([(x - 12, -350), (tx, ty), (x + 14, -352)], fill=DARK, sw=1.5)
    body.line([(-146, -188), (-110, -346), (-40, -384), (0, -394)], sw=2.5, opacity=0.8)
    body.poly([(-70, 20), (-110, -40), (-150, -120), (-140, -190), (-96, -232), (-40, -248), (0, -252), (40, -248),
               (96, -232), (140, -190), (150, -120), (110, -40), (70, 20), (30, 46), (0, 24), (-30, 48)])
    for x in (-110, -66, -20, 26, 70, 114):  # vertebra spikes along the hunched top
        body.poly([(x - 12, -236), (x + 2, -276 - (x % 3) * 6), (x + 16, -234)], fill=DARK, sw=1.5)
    body.poly([(-20, -190), (0, -110), (20, -190)], fill=DARK2, sw=1.2)
    for y in (-170, -130, -92):  # ribs pushing through the skin
        body.line([(-90, y), (-30, y + 16)], sw=2.5, opacity=0.5)
        body.line([(90, y), (30, y + 16)], sw=2.5, opacity=0.5)
    # hanging chains with hooks and a rag pouch
    for sx in (-1, 1):
        for i in range(4):
            body.ellipse(sx * (84 + i * 2), -40 + i * 20, 8, 6, fill=DARK, stroke=HI, sw=2, rot=(i % 2) * 90)
        body.poly([(sx * 84, 36), (sx * 104, 60), (sx * 88, 80), (sx * 80, 58)], fill=DARK, sw=1.5)
    body.line([(-150, -120), (-140, -190), (-96, -232), (-40, -248), (0, -252)], sw=2.5, opacity=0.8)
    R.part("body", "", H, 2, body)

    # extra arms: behind the body, children of it, rotated by poses only
    ex = [("arm_x1", (SL[0] - 20, 568), "up", 1, 1), ("arm_x2", (SR[0] + 20, 568), "up", -1, 1),
          ("arm_x3", (SL[0] + 4, 690), "low", 1, 1), ("arm_x4", (SR[0] - 4, 690), "low", -1, 1)]
    for pid, piv, kind, sx, z in ex:
        R.part(pid, "body", piv, z, spider(kind, sx))


    core = Art()  # the relic: a fan of pale bone shards sprouting above the head inside the cage
    for pts in ([(-60, -60), (-86, -128), (-48, -96)], [(-30, -66), (-40, -152), (-8, -90)],
                [(0, -70), (6, -172), (26, -84)], [(34, -64), (66, -140), (56, -78)],
                [(62, -58), (104, -102), (78, -52)]):
        core.poly(pts, fill=ACCENT, stroke=None)
    core.poly([(-70, -48), (70, -48), (50, -80), (-50, -80)], fill="#8f8a74", stroke=None, opacity=0.9)
    R.part("core", "body", (512, 640), 3, core, glow=True)

    head = Art()
    for sx in (-1, 1):  # lank hair / tendrils
        head.poly([(sx * 48, -70), (sx * 80, -20), (sx * 92, 70), (sx * 76, 160), (sx * 66, 70), (sx * 52, 10)],
                  fill=DARK2, sw=1.5)
    head.poly([(-54, -70), (-40, -96), (0, -104), (40, -96), (54, -70), (56, -20), (40, 10), (32, 40), (14, 56), (0, 64),
               (-14, 56), (-32, 40), (-40, 10), (-56, -20)])
    for x, ty in ((-44, -128), (-22, -142), (0, -150), (22, -142), (44, -128)):  # rusted nail crown
        head.poly([(x - 8, -92), (x * 1.1, ty), (x + 8, -92)], fill=DARK2, sw=1.5)
    head.poly([(-46, -52), (-8, -40), (-8, 4), (-40, 4), (-52, -20)], fill="#010203", stroke=None)
    head.poly([(50, -64), (8, -44), (8, 10), (44, 12), (58, -20)], fill="#010203", stroke=None)
    head.line([(0, -100), (0, 62)], sw=1.5, opacity=0.4)
    for x in (-22, -12, 0, 12, 22):  # needle teeth
        head.poly([(x - 3, 32), (x, 52 + (x % 4) * 3), (x + 3, 32)], fill="#0d1016", sw=1.2)
    head.line([(-56, -22), (-54, -70), (-40, -96), (0, -104)], sw=2.5, opacity=0.8)
    R.part("head", "body", N, 4, head)

    eyes = Art()
    eyes.poly([(-38, -40), (-14, -32), (-16, -8), (-40, -14)], fill=ACCENT, stroke=None)
    eyes.poly([(42, -50), (14, -36), (16, -2), (40, -10), (48, -30)], fill=ACCENT, stroke=None)
    R.part("eyes", "head", N, 5, eyes, glow=True)

    ul, fl = limb("l")
    ur, fr = limb("r")
    R.part("arm_l", "body", SL, 6, ul)
    R.part("forearm_l", "arm_l", (SL[0], SL[1] + L1), 7, fl)
    R.part("arm_r", "body", SR, 8, ur)
    R.part("forearm_r", "arm_r", (SR[0], SR[1] + L1), 9, fr)

    w = Art()  # rake of four curved nail-blades on a bone haft
    w.poly(tube([(0, 70), (0, -20), (0, -130)], 14, 12), fill=DARK2, sw=1.5)
    w.poly([(-8, 60), (0, 100), (8, 60)], fill=DARK, sw=1.2)
    w.poly([(-62, -118), (-58, -150), (0, -160), (58, -150), (62, -118), (30, -104), (0, -110), (-30, -104)],
           fill=DARK2, sw=2)
    for x in (-40, -14, 14, 40):
        w.circle(x, -128, 6, fill=DARK, sw=1.5)
    for k, (x0, ang) in enumerate(((-44, -30), (-16, -9), (16, 9), (44, 30))):
        a = math.radians(ang)
        c = []
        for i in range(6):
            t = i / 5
            L = 160 * t
            curl = -ang * 0.0 + (t * t) * (24 if ang > 0 else -24)
            c.append((x0 + math.sin(a) * L + curl, -150 - math.cos(a) * L))
        w.poly(tube(c, 15, 2), sw=1.5)
        w.line([c[1], c[2], c[3], c[4], c[5]], color=ACCENT, sw=6, opacity=1.0)
    R.part("weapon", "forearm_r", (SR[0], SR[1] + L1 + L2), 10, w, glow=True)

    R.build_layout(out_dir)
    pose = make_pose_fn(R, L1, L2)

    def X(a=0, b=0, c=0, d=0):
        return {"arm_x1": (a,), "arm_x2": (b,), "arm_x3": (c,), "arm_x4": (d,)}

    pose("idle", body=(3, 0, 0), head=-4, hr=(700, 840), blade=20, hl=(330, 840), extra=X(6, -6, 2, -2))
    pose("windup_quick", body=(-12, -6, 14), head=8, hr=(660, 720), blade=66, hl=(340, 820), extra=X(-22, 24, -8, 10))
    pose("strike_quick", body=(14, -20, 34), head=12, hr=(480, 800), blade=-80, hl=(330, 740), bend_r=1,
         extra=X(18, -34, 6, -16))
    pose("windup_heavy", body=(-14, 0, -6), head=-10, hr=(640, 500), blade=26, hl=(420, 560), bend_r=1, bend_l=-1,
         extra=X(-24, 30, -10, 10))
    pose("strike_heavy", body=(22, -10, 44), head=18, hr=(570, 650), blade=150, hl=(440, 780), bend_r=-1,
         extra=X(30, -30, 10, -10))
    pose("windup_feint", body=(-6, -14, 20), head=-24, hr=(650, 800), blade=40, hl=(340, 790), bend_r=-1,
         extra=X(52, -14, 22, 6))
    pose("windup_combo", body=(12, -12, 12), head=10, hr=(420, 830), blade=-92, hl=(660, 800), bend_r=-1, bend_l=-1,
         extra=X(-10, 40, -14, 18))
    pose("strike_combo", body=(-14, 16, 24), head=-8, hr=(620, 810), blade=88, hl=(430, 820), bend_r=1, bend_l=1,
         extra=X(-30, 10, -8, 10))
    pose("recover", body=(12, 0, 34), head=22, hr=(620, 730), blade=118, hl=(400, 790), extra=X(-46, 46, -10, 10))
    pose("staggered", body=(-22, 0, 30), head=-24, hr=(720, 640), blade=24, hl=(350, 640), bend_r=1, bend_l=-1,
         extra=X(-18, 34, -6, 10))
    pose("hurt", body=(-10, 0, 14), head=-14, hr=(680, 830), blade=18, hl=(360, 830), extra=X(-14, 14, -6, 6))
    pose("death", body=(-84, 140, -30), head=-10, legs=(-86, 140, -40), hr=(560, 800), blade=-96, hl=(520, 790),
         bend_r=1, bend_l=-1, extra=X(60, -60, -60, 60))
    R.write_rig()
    return R
