from rigkit import *

# Tutorial slime: cute pastel mint blob, big friendly eyes. Light style (not a near-black silhouette).
ACCENT = "#ffd24a"
H = (512, 780)
TOP = (512, 370)  # head pivot: top of the blob

MINT = "#9be3b0"
BELLY = "#d4f7dc"
OUT = "#4a3322"
WHITE = "#ffffff"
PUPIL = "#2a1a10"
CHEEK = "#ff9fb2"
LEAF = "#6cc98a"
SW = 4


def build(out_dir):
    R = Rig("tut_slime", ACCENT)

    # flat puddle under the body
    legs = Art()
    legs.ellipse(0, 18, 270, 38, fill=BELLY, stroke=OUT, sw=SW)
    legs.ellipse(-60, 14, 120, 14, fill=WHITE, stroke=None, sw=0, opacity=0.5)
    R.part("legs", "", H, 0, legs)

    # blob with wobbly drips along the bottom edge
    body = Art()
    blob = [(-215, -30), (-238, -130), (-216, -252), (-150, -352), (-60, -410), (42, -416), (142, -360),
            (212, -260), (238, -140), (216, -30), (172, 14), (132, -8), (100, 44), (62, -4), (10, 10),
            (-40, -8), (-86, 50), (-126, -4), (-172, 16)]
    body.smooth(blob, fill=MINT, stroke=OUT, sw=SW)
    body.ellipse(0, -80, 150, 66, fill=BELLY, stroke=None, sw=0, opacity=0.9)  # belly
    body.ellipse(-120, -320, 34, 18, fill=WHITE, stroke=None, sw=0, rot=-40, opacity=0.8)  # shine
    body.circle(-84, -354, 9, fill=WHITE, stroke=None, sw=0, opacity=0.8)
    R.part("body", "", H, 1, body)

    # leaf tuft on top
    head = Art()
    head.smooth([(0, 6), (-30, -40), (-26, -96), (6, -130), (34, -90), (30, -40)], fill=LEAF, stroke=OUT, sw=SW)
    head.line([(0, 0), (4, -90)], color=OUT, sw=3, opacity=0.7)
    head.smooth([(8, 8), (50, -20), (96, -22), (120, -4), (84, 14), (44, 18)], fill=LEAF, stroke=OUT, sw=SW)
    R.part("head", "body", TOP, 2, head)

    # face: big eyes, cheeks, smile
    eyes = Art()
    for sx in (-1, 1):
        ex = sx * 84
        eyes.circle(ex, -232, 58, fill=WHITE, stroke=OUT, sw=SW)
        eyes.circle(ex + sx * -4, -224, 30, fill=PUPIL, stroke=None, sw=0)
        eyes.circle(ex + sx * -4 - 10, -236, 10, fill=WHITE, stroke=None, sw=0)
        eyes.circle(ex + sx * -4 + 8, -212, 5, fill=WHITE, stroke=None, sw=0)
        eyes.ellipse(sx * 158, -156, 30, 18, fill=CHEEK, stroke=None, sw=0, opacity=0.9)
    eyes.smooth([(-36, -156), (-14, -134), (14, -134), (36, -156)], fill="none", stroke=OUT, sw=SW,
                closed=False, opacity=1.0)
    R.part("eyes", "body", H, 3, eyes, glow=True)

    R.build_layout(out_dir)

    def pose(name, body=(0, 0, 0), head=(0, 0, 0), legs=(0, 0, 0), eyes=None):
        p = R.new_pose()
        p.set("body", body[0], (body[1], body[2]))
        p.set("head", head[0], (head[1], head[2]))
        p.set("legs", legs[0], (legs[1], legs[2]))
        e = eyes if eyes is not None else body  # eyes follow the body unless overridden
        p.set("eyes", e[0], (e[1], e[2]))
        R.poses[name] = p
        return p

    pose("idle")
    pose("windup_quick", body=(-8, 10, 30), head=(-10, 0, 0), legs=(0, 8, 0))
    pose("strike_quick", body=(8, -40, 20), head=(14, 0, 0), legs=(0, -20, 0))
    pose("windup_heavy", body=(-12, 14, 40), head=(-16, 0, 6), legs=(0, 10, 0))
    pose("strike_heavy", body=(12, -50, 30), head=(20, 0, 0), legs=(0, -26, 0))
    pose("windup_feint", body=(-6, -18, 24), head=(-8, 0, 0), legs=(0, -10, 0))
    pose("windup_combo", body=(-8, 20, 28), head=(-10, 0, 0), legs=(0, 10, 0))
    pose("strike_combo", body=(8, -40, 20), head=(14, 0, 0), legs=(0, -20, 0))
    pose("recover", body=(3, 0, 12), head=(4, 0, 0))
    pose("staggered", body=(25, 10, 24), head=(30, 0, 0), legs=(0, 6, 0), eyes=(25, 10, 50))
    pose("hurt", body=(-10, 16, 8), head=(-14, 0, 0), legs=(0, 8, 0))
    pose("death", body=(-80, 150, -20), head=(-20, 0, 0), legs=(0, 40, 30), eyes=(-80, 150, -20))
    R.write_rig()
    return R
