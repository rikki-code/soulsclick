"""Relic icons (256x256): dark silhouette on a plate, rim light, ONE accent color chosen by tag.

Run: python3 relics.py  (writes ../relics/<id>.svg). Not shipped (_src has a .gdignore).
Readable at 64 px: strokes >= 7 px (accent >= 8), no detail smaller than ~10 px.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "enemy_pack", "silhouette_pack", "_src"))
from rigkit import Art  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "relics"))
SIL = "#07090c"      # silhouette fill
SIL2 = "#10141b"     # secondary fill (inset parts)
EDGE = "#56657e"     # silhouette rim stroke
HI = "#9fb0cc"       # rim-light lines
PLATE = "#1a212c"
PLATE_EDGE = "#2f3947"

TAGS = {  # tag -> accent
    "parry": "#f2c14e", "block": "#6aa3d9", "strike": "#e8e2d0", "stamina": "#6fd36a", "vital": "#f06b8a",
    "bleed": "#d6283c", "burn": "#ff7a1a", "frost": "#5fd8f0", "shock": "#a06bff", "soul": "#2fd3b5",
    "read": "#c3a6ff", "focus": "#fff0b0", "curse": "#e43cd8",
}


def rot(pts, deg, c=(128, 128)):
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    return [(c[0] + (x - c[0]) * ca - (y - c[1]) * sa, c[1] + (x - c[0]) * sa + (y - c[1]) * ca) for x, y in pts]


class Icon(Art):
    def __init__(self, accent):
        super().__init__()
        self.A = accent

    def sil(self, pts, fill=SIL, sw=4):
        self.poly(pts, fill=fill, stroke=EDGE, sw=sw)

    def sm(self, pts, fill=SIL, sw=4):
        self.smooth(pts, fill=fill, stroke=EDGE, sw=sw)

    def acc(self, pts, sw=10, smooth=False):
        self.line(pts, color=self.A, sw=sw, opacity=1.0, smooth=smooth)

    def accfill(self, pts):
        self.poly(pts, fill=self.A, stroke=None)

    def hi(self, pts, sw=5, smooth=False):
        self.line(pts, color=HI, sw=sw, opacity=0.6, smooth=smooth)

    def fat(self, pts, w=18):
        """Dark thick stroke with a rim (swooshes, cords)."""
        self.line(pts, color=EDGE, sw=w + 7, opacity=1.0, smooth=True)
        self.line(pts, color=SIL, sw=w, opacity=1.0, smooth=True)

    def disc(self, cx, cy, r, fill=SIL, sw=4):
        self.circle(cx, cy, r, fill=fill, stroke=EDGE, sw=sw)


def sword(ic, length=170, wide=22, top=32):
    """Vertical broadsword centred at x=128, tip at `top`. Returns nothing, draws silhouette parts."""
    b = top + length
    blade = [(128, top), (128 + wide, top + 44), (128 + wide, b), (128 - wide, b), (128 - wide, top + 44)]
    return blade, b


# ---------------------------------------------------------------- icons
def whetstone(ic):
    ic.sil([(48, 172), (58, 146), (200, 146), (210, 172), (198, 200), (60, 200)])
    ic.sil(rot([(62, 104), (196, 104), (218, 126), (196, 148), (62, 148)], -22, (140, 130)))
    ic.acc(rot([(70, 106), (198, 106)], -22, (140, 130)), 10)
    ic.sil(rot([(40, 100), (66, 100), (66, 152), (40, 152)], -22, (140, 130)), fill=SIL2)
    ic.hi([(60, 150), (198, 150)])


def iron_lung(ic):
    L = [(118, 90), (96, 118), (68, 168), (62, 202), (92, 210), (116, 190), (118, 140)]
    ic.sm(L)
    ic.sm([(256 - x, y) for x, y in L])
    ic.sil([(120, 40), (136, 40), (136, 104), (120, 104)])
    ic.acc([(128, 100), (104, 134), (90, 164)], 9)
    ic.acc([(128, 100), (152, 134), (166, 164)], 9)
    ic.acc([(104, 134), (114, 164)], 8)
    ic.acc([(152, 134), (142, 164)], 8)


def hawk_feather(ic):
    ic.sm([(58, 204), (68, 152), (98, 102), (148, 62), (204, 42), (198, 94), (168, 142), (120, 180)])
    ic.acc([(54, 210), (110, 140), (200, 48)], 10, smooth=True)
    for p, q in (((96, 124), (118, 122)), ((126, 98), (150, 100)), ((84, 156), (108, 158)), ((150, 78), (170, 84))):
        ic.line([p, q], color=PLATE, sw=6, opacity=1.0)


def tower_shard(ic):
    ic.sil([(62, 54), (192, 54), (194, 118), (164, 138), (178, 170), (128, 214), (112, 176), (78, 160), (88, 120)])
    ic.acc([(128, 56), (116, 98), (140, 126), (122, 178)], 10)
    ic.hi([(64, 58), (190, 58)])


def thick_hide(ic):
    ic.sm([(64, 66), (100, 84), (156, 84), (192, 66), (210, 110), (192, 142), (206, 190), (168, 178), (128, 196),
           (88, 178), (50, 190), (64, 142), (46, 110)])
    ic.acc([(128, 94), (128, 178)], 8)
    for y in (108, 132, 156):
        ic.acc([(110, y), (146, y)], 8)


def executioners_hood(ic):
    ic.sm([(128, 40), (168, 56), (186, 104), (214, 196), (170, 214), (128, 198), (86, 214), (42, 196), (70, 104), (88, 56)])
    ic.sil([(100, 94), (156, 94), (162, 140), (128, 154), (94, 140)], fill="#000000", sw=3)
    ic.acc([(104, 112), (122, 118)], 11)
    ic.acc([(152, 112), (134, 118)], 11)
    ic.hi([(112, 170), (144, 170)], 6)


def foresight(ic):
    ic.sm([(36, 118), (82, 80), (128, 68), (174, 80), (220, 118), (174, 156), (128, 168), (82, 156)])
    ic.circle(128, 118, 30, fill=SIL2, stroke=ic.A, sw=10)
    ic.circle(128, 118, 11, fill=ic.A, stroke=None)
    ic.acc([(92, 192), (108, 208), (92, 224)], 9)
    ic.acc([(128, 192), (144, 208), (128, 224)], 9)
    ic.acc([(164, 192), (180, 208), (164, 224)], 9)


def glass_blade(ic):
    ic.sil([(128, 24), (152, 66), (152, 164), (104, 164), (104, 66)])
    ic.sil([(70, 168), (186, 168), (186, 188), (70, 188)], fill=SIL2)
    ic.sil([(118, 188), (138, 188), (138, 224), (118, 224)], fill=SIL2)
    ic.acc([(128, 40), (116, 84), (140, 108), (120, 144), (130, 164)], 9)
    ic.hi([(106, 70), (106, 160)])


def menders_thread(ic):
    ic.sil(rot([(116, 30), (140, 30), (140, 206), (128, 228), (116, 206)], 38, (128, 130)))
    ic.circle(*rot([(128, 58)], 38, (128, 130))[0], 8, fill=PLATE, stroke=None)
    ic.acc([(176, 62), (210, 98), (186, 136), (148, 128), (140, 168), (96, 196)], 10, smooth=True)


def riposte_charm(ic):
    ic.line([(128, 48), (128, 84)], color=EDGE, sw=8, opacity=1.0)
    ic.circle(128, 40, 16, fill="none", stroke=EDGE, sw=9)
    ic.disc(128, 150, 68)
    ic.circle(128, 150, 54, fill=SIL2, stroke=None)
    ic.acc([(92, 178), (102, 128), (148, 114)], 10, smooth=True)
    ic.accfill([(144, 92), (186, 118), (142, 140)])


def echo_bell(ic):
    ic.sm([(128, 52), (158, 72), (166, 124), (184, 170), (210, 186), (210, 198), (46, 198), (46, 186), (72, 170),
           (90, 124), (98, 72)])
    ic.circle(128, 44, 11, fill="none", stroke=EDGE, sw=8)
    ic.disc(128, 214, 12)
    for s in (1, -1):
        cx = 128 + s * 96
        ic.acc([(cx - s * 30, 96), (cx - s * 14, 130), (cx - s * 30, 164)], 9, smooth=True)
        ic.acc([(cx - s * 2, 74), (cx + s * 22, 130), (cx - s * 2, 186)], 9, smooth=True)


def mirror_shard(ic):
    ic.sil([(98, 38), (172, 58), (204, 140), (150, 216), (88, 192), (66, 108)])
    ic.sil([(106, 70), (160, 84), (180, 138), (140, 186), (100, 168), (88, 116)], fill=SIL2, sw=3)
    ic.acc([(100, 154), (150, 96)], 10)
    ic.acc([(122, 176), (164, 128)], 10)


def ember_wick(ic):
    ic.sil([(92, 138), (164, 138), (164, 206), (92, 206)])
    ic.sil([(100, 138), (100, 168), (110, 178), (120, 168), (120, 138)], fill=SIL2, sw=3)
    ic.sil([(140, 138), (140, 160), (148, 168), (156, 160), (156, 138)], fill=SIL2, sw=3)
    ic.hi([(96, 142), (160, 142)])
    ic.line([(128, 138), (128, 118)], color=EDGE, sw=8, opacity=1.0)
    ic.smooth([(128, 36), (154, 82), (148, 114), (128, 124), (108, 114), (102, 82)], fill=ic.A, stroke=None)
    ic.smooth([(128, 84), (138, 104), (128, 116), (118, 104)], fill=SIL, stroke=None)


def duelists_pride(ic):
    for s in (1, -1):
        c = (128, 128)
        pts = [(128, 18), (138, 50), (138, 168), (118, 168), (118, 50)]
        ic.sil(rot(pts, 45 * s, c))
        ic.sil(rot([(94, 170), (162, 170), (162, 184), (94, 184)], 45 * s, c), fill=SIL2)
        ic.sil(rot([(121, 184), (135, 184), (135, 218), (121, 218)], 45 * s, c), fill=SIL2)
        ic.acc(rot([(128, 28), (128, 120)], 45 * s, c), 8)
    ic.disc(128, 128, 20)
    ic.circle(128, 128, 8, fill=ic.A, stroke=None)


def barbed_shield(ic):
    for k in range(10):
        a = k * 2 * math.pi / 10
        c, s = math.cos(a), math.sin(a)
        ic.sil([(128 + c * 64 - s * 16, 128 + s * 64 + c * 16), (128 + c * 108, 128 + s * 108),
                (128 + c * 64 + s * 16, 128 + s * 64 - c * 16)], sw=3)
    ic.disc(128, 128, 70)
    ic.circle(128, 128, 50, fill="none", stroke=ic.A, sw=9)
    ic.disc(128, 128, 20, fill=SIL2)


def bulwark_sigil(ic):
    ic.sil([(72, 48), (184, 48), (188, 132), (162, 186), (128, 216), (94, 186), (68, 132)])
    ic.sil([(86, 62), (170, 62), (172, 130), (152, 172), (128, 194), (104, 172), (84, 130)], fill=SIL2, sw=3)
    ic.acc([(128, 90), (128, 176)], 11)
    ic.acc([(94, 120), (128, 92), (162, 120)], 11)


def counter_tide(ic):
    ic.sm([(36, 206), (40, 148), (66, 104), (116, 78), (166, 84), (200, 116), (176, 136), (158, 116), (126, 120),
           (108, 150), (126, 206)])
    ic.sil([(30, 206), (226, 206), (226, 226), (30, 226)], fill=SIL2, sw=3)
    ic.acc([(70, 112), (112, 84), (160, 92), (192, 120)], 11, smooth=True)
    ic.circle(206, 156, 8, fill=ic.A, stroke=None)
    ic.circle(222, 130, 6, fill=ic.A, stroke=None)


def ghost_cloak(ic):
    ic.sm([(128, 34), (166, 58), (176, 114), (204, 196), (176, 186), (160, 218), (140, 190), (128, 224), (116, 190),
           (96, 218), (80, 186), (52, 196), (80, 114), (90, 58)])
    ic.sil([(100, 70), (156, 70), (160, 116), (128, 130), (96, 116)], fill="#000000", sw=3)
    ic.circle(112, 96, 8, fill=ic.A, stroke=None)
    ic.circle(144, 96, 8, fill=ic.A, stroke=None)


def martyrs_brand(ic):
    ic.sil([(116, 126), (140, 126), (140, 226), (116, 226)])
    ic.sil([(76, 44), (180, 44), (180, 130), (76, 130)])
    ic.sil([(100, 126), (156, 126), (156, 140), (100, 140)], fill=SIL2)
    ic.acc([(128, 58), (128, 114)], 14)
    ic.acc([(100, 86), (156, 86)], 14)


def bloodsoaked_rag(ic):
    ic.sm([(60, 58), (194, 46), (206, 120), (190, 150), (172, 172), (152, 148), (128, 176), (104, 148), (84, 174),
           (66, 140), (52, 108)])
    ic.sm([(120, 78), (144, 76), (150, 104), (126, 118), (112, 100)], fill=ic.A, sw=3)
    ic.smooth([(128, 186), (146, 210), (140, 228), (116, 228), (110, 210)], fill=ic.A, stroke=None)


def phoenix_ash(ic):
    ic.sil([(40, 214), (70, 180), (110, 164), (146, 164), (186, 180), (216, 214)])
    ic.sil([(128, 52), (150, 90), (212, 62), (186, 126), (156, 142), (128, 162), (100, 142), (70, 126), (44, 62), (106, 90)])
    ic.accfill([(128, 28), (140, 52), (128, 66), (116, 52)])
    for dx in (-22, 0, 22):
        ic.acc([(128 + dx // 2, 168), (128 + dx, 206)], 9)
    ic.hi([(70, 126), (44, 62), (106, 90)], 5)


def reckless_oath(ic):
    ic.sm([(128, 200), (68, 144), (56, 100), (82, 66), (116, 70), (128, 94), (140, 70), (174, 66), (200, 100), (188, 144)])
    ic.acc([(54, 54), (208, 206)], 11)
    ic.sil(rot([(112, 34), (144, 34), (144, 48), (112, 48)], -45, (128, 128)), fill=SIL2)
    ic.sil(rot([(122, 12), (134, 12), (134, 36), (122, 36)], -45, (128, 128)), fill=SIL2)


def overreach(ic):
    ic.sil([(66, 112), (160, 112), (172, 152), (154, 196), (84, 196), (62, 154)])
    for cx, cy in ((82, 112), (104, 104), (126, 102), (148, 108)):
        ic.disc(cx, cy, 17, sw=3)
    ic.sil([(86, 196), (152, 196), (152, 216), (86, 216)], fill=SIL2)
    for y, x0 in ((92, 184), (130, 194), (168, 184)):
        ic.acc([(x0, y), (x0 + 32, y)], 9)


def serrated_edge(ic):
    blade = [(84, 124), (140, 114), (216, 92), (206, 114), (196, 110), (190, 130), (180, 126), (172, 146), (162, 142),
             (154, 160), (142, 156), (84, 156)]
    ic.sil(blade)
    ic.sil([(36, 128), (90, 128), (90, 158), (36, 158)], fill=SIL2)
    ic.acc([(92, 122), (212, 94)], 8)
    ic.smooth([(60, 178), (74, 198), (70, 214), (50, 214), (46, 198)], fill=ic.A, stroke=None)


def cinder_blade(ic):
    ic.sil(rot([(128, 22), (150, 62), (150, 166), (106, 166), (106, 62)], 42))
    ic.sil(rot([(72, 170), (184, 170), (184, 188), (72, 188)], 42), fill=SIL2)
    ic.sil(rot([(119, 188), (137, 188), (137, 222), (119, 222)], 42), fill=SIL2)
    ic.acc(rot([(128, 34), (128, 150)], 42), 9)
    for cx, cy, r in ((70, 70, 8), (96, 44, 6), (52, 106, 6)):
        ic.circle(cx, cy, r, fill=ic.A, stroke=None)


def vampire_fang(ic):
    ic.sil([(70, 30), (186, 30), (186, 60), (70, 60)], fill=SIL2)
    ic.sil([(88, 56), (168, 56), (162, 100), (146, 148), (128, 186), (110, 148), (94, 100)])
    ic.hi([(92, 62), (98, 100), (112, 146)])
    ic.smooth([(128, 194), (144, 214), (138, 232), (118, 232), (112, 214)], fill=ic.A, stroke=None)


def soul_siphon(ic):
    ic.sil([(110, 60), (146, 60), (146, 112), (110, 112)])
    ic.sil([(100, 52), (156, 52), (156, 66), (100, 66)], fill=SIL2)
    ic.disc(128, 164, 52)
    ic.smooth([(84, 166), (172, 166), (164, 192), (128, 210), (92, 192)], fill=ic.A, stroke=None)
    ic.acc([(206, 44), (170, 60), (190, 90), (148, 100), (130, 134)], 9, smooth=True)


def second_wind(ic):
    ic.fat([(44, 92), (116, 84), (170, 86), (194, 68), (180, 48), (158, 60)], 16)
    ic.acc([(60, 130), (150, 128), (204, 130), (218, 156), (198, 174), (178, 158)], 14, smooth=True)
    ic.fat([(48, 172), (118, 172), (150, 178), (160, 200), (144, 212), (130, 196)], 16)


def seers_eye(ic):
    ic.sil([(106, 176), (150, 176), (166, 216), (90, 216)], fill=SIL2)
    ic.disc(128, 112, 74)
    ic.hi([(76, 84), (96, 62)], 6)
    ic.sm([(70, 112), (100, 90), (128, 84), (156, 90), (186, 112), (156, 134), (128, 140), (100, 134)], fill=SIL2, sw=3)
    ic.circle(128, 112, 22, fill=ic.A, stroke=None)
    ic.sil([(124, 96), (132, 96), (134, 112), (132, 128), (124, 128), (122, 112)], fill="#000000", sw=3)


def pilgrims_lantern(ic):
    ic.line([(96, 86), (100, 40), (156, 40), (160, 86)], color=EDGE, sw=9, opacity=1.0, smooth=True)
    ic.sil([(86, 78), (170, 78), (160, 98), (96, 98)])
    ic.sil([(92, 96), (164, 96), (174, 192), (82, 192)], fill=SIL2)
    ic.smooth([(128, 112), (150, 146), (144, 174), (128, 182), (112, 174), (106, 146)], fill=ic.A, stroke=None)
    for x in (110, 146):
        ic.line([(x - 2, 100), (x - 6, 190)], color=SIL, sw=8, opacity=1.0)
    ic.sil([(72, 190), (184, 190), (184, 210), (72, 210)])


def camp_kit(ic):
    ic.sil([(128, 40), (218, 196), (38, 196)])
    ic.sil([(128, 100), (170, 196), (86, 196)], fill="#000000", sw=3)
    ic.line([(128, 40), (128, 100)], color=EDGE, sw=6, opacity=1.0)
    ic.smooth([(128, 128), (146, 160), (140, 186), (128, 192), (116, 186), (110, 160)], fill=ic.A, stroke=None)
    ic.hi([(128, 44), (48, 190)], 5)


def hoarders_ledger(ic):
    ic.sil([(62, 46), (194, 46), (194, 208), (62, 208)])
    ic.sil([(62, 46), (90, 46), (90, 208), (62, 208)], fill=SIL2)
    ic.hi([(70, 50), (186, 50)])
    ic.sil([(184, 100), (212, 100), (212, 128), (184, 128)], fill=SIL2, sw=3)
    ic.circle(144, 120, 32, fill="none", stroke=ic.A, sw=10)
    ic.acc([(144, 106), (144, 134)], 10)
    for y in (172, 186):
        ic.line([(106, y), (176, y)], color=EDGE, sw=6, opacity=1.0)


# id -> (function, accent tag). Accent tag = first tag in items.md unless noted.
ICONS = {
    "whetstone": (whetstone, "strike"), "iron_lung": (iron_lung, "stamina"), "hawk_feather": (hawk_feather, "parry"),
    "tower_shard": (tower_shard, "block"), "thick_hide": (thick_hide, "vital"),
    "executioners_hood": (executioners_hood, "strike"), "foresight": (foresight, "read"),
    "glass_blade": (glass_blade, "curse"), "menders_thread": (menders_thread, "parry"),
    "riposte_charm": (riposte_charm, "parry"), "echo_bell": (echo_bell, "parry"),
    "mirror_shard": (mirror_shard, "parry"), "ember_wick": (ember_wick, "burn"),
    "duelists_pride": (duelists_pride, "parry"), "barbed_shield": (barbed_shield, "block"),
    "bulwark_sigil": (bulwark_sigil, "block"), "counter_tide": (counter_tide, "block"),
    "ghost_cloak": (ghost_cloak, "vital"), "martyrs_brand": (martyrs_brand, "vital"),
    "bloodsoaked_rag": (bloodsoaked_rag, "bleed"), "phoenix_ash": (phoenix_ash, "vital"),
    "reckless_oath": (reckless_oath, "curse"), "overreach": (overreach, "strike"),
    "serrated_edge": (serrated_edge, "bleed"), "cinder_blade": (cinder_blade, "burn"),
    "vampire_fang": (vampire_fang, "bleed"), "soul_siphon": (soul_siphon, "soul"),
    "second_wind": (second_wind, "stamina"), "seers_eye": (seers_eye, "read"),
    "pilgrims_lantern": (pilgrims_lantern, "soul"), "camp_kit": (camp_kit, "vital"),
    "hoarders_ledger": (hoarders_ledger, "soul"),
}


def build():
    os.makedirs(OUT, exist_ok=True)
    for rid, (fn, tag) in ICONS.items():
        ic = Icon(TAGS[tag])
        fn(ic)
        body = "".join(ic.items)
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'
               '<circle cx="128" cy="128" r="124" fill="%s" stroke="%s" stroke-width="4"/>%s</svg>\n'
               % (PLATE, PLATE_EDGE, body))
        with open(os.path.join(OUT, rid + ".svg"), "w") as f:
            f.write(svg)
    print("wrote %d icons" % len(ICONS))


if __name__ == "__main__":
    build()
