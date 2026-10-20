import sys
from scene import *

OUT = os.path.join(B, "_src")
EN_ACC = {"knight": "#5cb8ff", "warden": "#ff4a3d"}


def render_all(only=None):
    jobs = []

    def emit(name, W, H, layers):
        svg = os.path.join(OUT, name + ".svg")
        build(W, H, layers, svg)
        png = os.path.join(B, name + ".png")
        jobs.append((svg, png))

    # ---- covers: 800x470 (knight), 630x500 (warden); EN + RU
    for lang in ("en", "ru"):
        W, H = 800, 470
        s = W / 1080
        emit("cover_800x470" + ("" if lang == "en" else "_ru"), W, H, [
            tf(bg("knight", "b_"), 0, -690 * s, s),
            glow(400, 300, 300, "#5cb8ff", 0.25, "gk"),
            tf(enemy("knight", "windup_heavy", "e_"), 215, 58, 0.6),
            fade(0, 0, W, 200, "down", 0.65, "ft"),
            fade(0, 330, W, 140, "up", 0.9, "fb"),
            tf(hands("idle", "kite", "sword", "h_"), -75, H - 1920 * 0.36 + 5, 0.36),
            logo_at(lang, 12, 2, 0.47, "lg"),
            vignette(W, H),
        ])
        W, H = 630, 500
        emit("cover_630x500" + ("" if lang == "en" else "_ru"), W, H, [
            tf(bg("warden", "b_"), -225, -610 * 0.8, 0.8),
            glow(315, 300, 280, "#ff4a3d", 0.25, "gk"),
            tf(enemy("warden", "idle", "e_"), 120, 30, 0.6),
            fade(0, 0, W, 200, "down", 0.8, "ft"),
            fade(0, 350, W, 150, "up", 0.9, "fb"),
            tf(hands("idle", "kite", "sword", "h_"), -75, H - 1920 * 0.34 + 5, 0.34),
            logo_at(lang, 8, 4, 0.39, "lg"),
            vignette(W, H),
        ])
    # promo portrait 1080x1920 (warden)
    W, H = 1080, 1920
    emit("promo_1080x1920", W, H, [
        tf(bg("warden", "b_"), 0, 0, 1),
        glow(540, 900, 600, "#ff4a3d", 0.2, "gk"),
        tf(enemy("warden", "windup_heavy", "e_"), 28, 470, 1),
        fade(0, 0, W, 700, "down", 0.8, "ft"),
        fade(0, 1300, W, 620, "up", 0.8, "fb"),
        hands("block", "kite", "sword", "h_"),
        logo_at("en", 40, 130, 0.62, "lg"),
        vignette(W, H, op=0.6),
    ])
    # promo landscape 1920x1080 (knight)
    W, H = 1920, 1080
    s = W / 1080
    emit("promo_1920x1080", W, H, [
        tf(bg("knight", "b_"), 0, -850 * s, s),
        glow(1350, 560, 560, "#5cb8ff", 0.25, "gk"),
        tf(enemy("knight", "windup_heavy", "e_"), 900, -35, 1.15),
        fade(0, 650, W, 430, "up", 0.9, "fb"),
        tf(hands("block", "kite", "sword", "h_"), 120, H - 1920 * 0.6 + 40, 0.6),
        logo_at("en", 20, 20, 0.78, "lg"),
        vignette(W, H),
    ])
    lp = os.path.join(OUT, ".jobs.txt")
    open(lp, "w").write("".join("%s\t%s\t1\n" % j for j in jobs))
    os.system("cd %s && /Users/vladimirafanasev/dev/godot/bin/godot.macos.editor.arm64 --headless --path . -s tools/svg_to_png.gd -- --list %s 2>&1 | grep -i error" % (ROOT, lp))
    os.remove(lp)

render_all()
