"""Consumable + reward-kind icons (256x256), same style as relics.py. Run: python3 ui_icons.py
Writes ../items/<id>.svg and ../rewards/<id>.svg. Not shipped (_src has a .gdignore)."""
import os
from relics import Icon, TAGS, SIL, SIL2, EDGE, HI, PLATE, PLATE_EDGE, HERE

BASE = os.path.normpath(os.path.join(HERE, ".."))


def flask(ic):
    """Red healing potion with a white cross: reads as "heals" without the accent tag colour."""
    ic.items.append(open(os.path.join(HERE, "flask_body.svgfrag")).read().strip())


def ember_bomb(ic):
    ic.disc(120, 160, 62)
    ic.sil([(98, 92), (142, 92), (138, 108), (102, 108)], fill=SIL2)
    ic.line([(124, 92), (136, 66), (164, 54)], color=EDGE, sw=10, opacity=1.0, smooth=True)
    ic.accfill([(176, 28), (190, 48), (180, 66), (164, 54), (160, 40)])
    ic.acc([(94, 168), (118, 184), (112, 206), (142, 196)], 9, smooth=True)
    ic.hi([(78, 138), (92, 120)], 6)


def whetstone_oil(ic):
    ic.sil([(100, 44), (156, 44), (156, 70), (100, 70)], fill=SIL2)
    ic.sil([(94, 68), (162, 68), (190, 118), (190, 190), (170, 214), (86, 214), (66, 190), (66, 118)])
    ic.sil([(86, 110), (170, 110), (170, 170), (86, 170)], fill=SIL2, sw=3)
    ic.acc([(94, 140), (162, 140)], 10)
    ic.smooth([(212, 88), (226, 112), (212, 130), (198, 112)], fill=ic.A, stroke=None)
    ic.hi([(76, 124), (76, 184)])


def warding_ash(ic):
    ic.sil([(96, 96), (160, 96), (196, 136), (206, 190), (178, 218), (78, 218), (50, 190), (60, 136)])
    ic.sil([(88, 84), (168, 84), (168, 104), (88, 104)], fill=SIL2)
    ic.line([(92, 96), (164, 96)], color=EDGE, sw=6, opacity=1.0)
    ic.circle(128, 46, 20, fill=ic.A, stroke=None)
    ic.circle(100, 62, 12, fill=ic.A, stroke=None)
    ic.circle(158, 62, 12, fill=ic.A, stroke=None)
    ic.acc([(96, 164), (128, 134), (160, 164)], 10)
    ic.hi([(66, 142), (62, 186)])


def stat_max_hp(ic):
    ic.sm([(128, 214), (60, 148), (46, 108), (62, 66), (100, 54), (128, 82), (156, 54), (194, 66), (210, 108), (196, 148)])
    ic.smooth([(128, 196), (84, 148), (76, 114), (90, 92), (112, 92), (128, 112)], fill=ic.A, stroke=None)
    ic.hi([(60, 92), (80, 64), (104, 58)])


def stat_max_stamina(ic):  # wing
    ic.sm([(52, 196), (50, 130), (84, 80), (140, 46), (206, 38), (190, 96), (160, 150), (110, 190)])
    for p, q in (((70, 176), (150, 70)), ((92, 182), (176, 96)), ((114, 184), (186, 130))):
        ic.acc([p, q], 9, smooth=True)
    ic.hi([(58, 120), (92, 76), (140, 50)])


def stat_attack_damage(ic):
    ic.sil([(128, 24), (150, 70), (150, 156), (106, 156), (106, 70)])
    ic.acc([(128, 40), (128, 140)], 10)
    ic.sil([(66, 156), (190, 156), (190, 174), (66, 174)], fill=SIL2)
    ic.sil([(118, 174), (138, 174), (138, 212), (118, 212)])
    ic.disc(128, 224, 14)
    ic.hi([(112, 70), (112, 150)])


def stat_stamina_regen(ic):  # boot
    ic.sil([(88, 40), (150, 40), (154, 140), (214, 176), (214, 212), (74, 212), (78, 130)])
    ic.sil([(84, 40), (156, 40), (156, 66), (84, 66)], fill=SIL2)
    ic.acc([(76, 226), (212, 226)], 9)
    ic.acc([(116, 104), (128, 124), (140, 104)], 9)
    ic.hi([(92, 70), (90, 128)])


def souls(ic):
    ic.smooth([(128, 28), (170, 90), (186, 148), (160, 204), (128, 216), (96, 204), (70, 148), (86, 90)], fill=SIL, stroke=EDGE, sw=4)
    ic.smooth([(128, 78), (156, 124), (150, 176), (128, 190), (106, 176), (100, 124)], fill=ic.A, stroke=None)
    ic.circle(116, 138, 10, fill=SIL, stroke=None)
    ic.circle(142, 138, 10, fill=SIL, stroke=None)
    ic.hi([(92, 100), (82, 144)])


def heal(ic):
    ic.sil([(98, 38), (158, 38), (158, 98), (218, 98), (218, 158), (158, 158), (158, 218), (98, 218), (98, 158), (38, 158), (38, 98), (98, 98)])
    ic.accfill([(112, 70), (144, 70), (144, 112), (186, 112), (186, 144), (144, 144), (144, 186), (112, 186), (112, 144), (70, 144), (70, 112), (112, 112)])
    ic.hi([(44, 104), (98, 104), (104, 44)])


def consumable(ic):
    ic.sil([(88, 80), (168, 80), (208, 130), (214, 190), (184, 222), (72, 222), (42, 190), (48, 130)])
    ic.sil([(80, 66), (176, 66), (176, 90), (80, 90)], fill=SIL2)
    ic.acc([(70, 78), (186, 78)], 10)
    ic.acc([(100, 160), (128, 134), (156, 160), (128, 186), (100, 160)], 9)
    ic.hi([(56, 140), (52, 188)])


def relic(ic):  # rune ring
    ic.circle(128, 128, 78, fill="none", stroke=EDGE, sw=34)
    ic.circle(128, 128, 78, fill="none", stroke=SIL, sw=26)
    ic.acc([(128, 76), (128, 180)], 11)
    ic.acc([(128, 98), (160, 130)], 10)
    ic.acc([(128, 128), (98, 158)], 10)
    ic.hi([(70, 100), (100, 66)])


ITEMS = {"flask": (flask, "parry"), "ember_bomb": (ember_bomb, "burn"), "whetstone_oil": (whetstone_oil, "focus"),
         "warding_ash": (warding_ash, "block")}
REWARDS = {"stat_max_hp": (stat_max_hp, "vital"), "stat_max_stamina": (stat_max_stamina, "stamina"),
           "stat_attack_damage": (stat_attack_damage, "strike"), "stat_stamina_regen": (stat_stamina_regen, "stamina"),
           "souls": (souls, "soul"), "heal": (heal, "vital"), "consumable": (consumable, "parry"), "relic": (relic, "read")}


def build():
    for sub, table in (("items", ITEMS), ("rewards", REWARDS)):
        out = os.path.join(BASE, sub)
        os.makedirs(out, exist_ok=True)
        for rid, (fn, tag) in table.items():
            ic = Icon(TAGS[tag])
            fn(ic)
            svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'
                   '<circle cx="128" cy="128" r="124" fill="%s" stroke="%s" stroke-width="4"/>%s</svg>\n'
                   % (PLATE, PLATE_EDGE, "".join(ic.items)))
            with open(os.path.join(out, rid + ".svg"), "w") as f:
                f.write(svg)
    print("wrote", len(ITEMS) + len(REWARDS))


if __name__ == "__main__":
    build()
