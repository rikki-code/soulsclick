#!/usr/bin/env python3
"""Synthesizes the sound pack in view/packs/audio_pack/ from scratch (no samples, so nothing to license).

usage: python3 tools/gen_audio.py [pack ...]     (default: every pack)
Writes .wav plus a .import that makes Godot store them as ADPCM (music also looped);
afterwards run `godot --headless --path . --import`.
A new cue = a function in CUES; a new pack = a Profile subclass in PROFILES.
"""
import math
import pathlib
import random
import struct
import sys
import wave

SR = 22050
TAU = math.pi * 2
ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "view/packs/audio_pack"
RES_PREFIX = "res://view/packs/audio_pack/"


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


# ---- DSP primitives -------------------------------------------------------

def silence(sec):
    return [0.0] * int(sec * SR)


def mix(dst, src, at=0.0, gain=1.0):
    start = int(at * SR)
    need = start + len(src)
    if need > len(dst):
        dst.extend([0.0] * (need - len(dst)))
    for i, v in enumerate(src):
        dst[start + i] += v * gain
    return dst


def lowpass(buf, cutoff):
    a = 1 - math.exp(-TAU * cutoff / SR)
    y = 0.0
    out = []
    for x in buf:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(buf, cutoff):
    low = lowpass(buf, cutoff)
    return [x - l for x, l in zip(buf, low)]


def sweep_lowpass(buf, f0, f1):
    y = 0.0
    out = []
    n = max(len(buf) - 1, 1)
    for i, x in enumerate(buf):
        f = f0 * (f1 / f0) ** (i / n)
        y += (1 - math.exp(-TAU * f / SR)) * (x - y)
        out.append(y)
    return out


def fade_edges(buf, head=0.002, tail=0.01):
    h, t = int(head * SR), int(tail * SR)
    for i in range(min(h, len(buf))):
        buf[i] *= i / h
    for i in range(min(t, len(buf))):
        buf[len(buf) - 1 - i] *= i / t
    return buf


def shape(kind, phase):
    p = phase % 1.0
    if kind == "sine":
        return math.sin(TAU * p)
    if kind == "tri":
        return 4 * abs(p - 0.5) - 1
    if kind == "saw":
        return 2 * p - 1
    return 1.0 if p < 0.5 else -1.0


def tone(freq, dur, amp=1.0, kind="sine", end_freq=None, decay=6.0, attack=0.004, vibrato=0.0):
    n = int(dur * SR)
    out = [0.0] * n
    phase = 0.0
    att = max(int(attack * SR), 1)
    for i in range(n):
        t = i / n
        f = freq if end_freq is None else freq * (end_freq / freq) ** t
        if vibrato:
            f *= 1 + vibrato * math.sin(TAU * 5.5 * i / SR)
        phase += f / SR
        out[i] = shape(kind, phase) * amp * min(1.0, i / att) * math.exp(-decay * t)
    return fade_edges(out)


def bell(freq, dur, amp=1.0, ratio=3.5, index=1.8, decay=5.0):
    n = int(dur * SR)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t / dur)
        mod = math.sin(TAU * freq * ratio * t) * index * env
        out[i] = math.sin(TAU * freq * t + mod) * amp * env * min(1.0, i / 40)
    return fade_edges(out)


def noise(dur, amp=1.0, decay=6.0, rng=random):
    n = int(dur * SR)
    return [rng.uniform(-1, 1) * amp * math.exp(-decay * i / n) for i in range(n)]


def reverb(buf, wet=0.25, size=1.0):
    tail = int(1.2 * size * SR)
    src = buf + [0.0] * tail
    out = list(src)
    for delay, feedback in ((0.0297, 0.72), (0.0371, 0.70), (0.0411, 0.68), (0.0437, 0.66)):
        d = int(delay * size * SR)
        comb = [0.0] * len(src)
        for i in range(len(src)):
            comb[i] = src[i] + (comb[i - d] * feedback if i >= d else 0.0)
        for i in range(len(src)):
            out[i] += comb[i] * wet * 0.25
    return out


def drive(buf, amount):
    norm = math.tanh(amount)
    return [math.tanh(x * amount) / norm for x in buf]


def crackle(dur, per_second, amp=1.0, decay=3.0):
    """Sparse random clicks that thin out: fuse sparks, flying debris."""
    out = silence(dur)
    n = len(out)
    for _ in range(int(per_second * dur)):
        at = int(random.random() ** 1.6 * n)
        gain = amp * random.uniform(0.3, 1.0) * math.exp(-decay * at / n)
        for k in range(int(0.003 * SR)):
            if at + k < n:
                out[at + k] += random.uniform(-1, 1) * gain * (1 - k / (0.003 * SR))
    return out


def explosion(dur, amp=1.0, sub_hz=90, grit=2.2, debris=260):
    """Crack, a mid-range noise body (what small speakers can play), a punchy thump, sub and falling debris, driven hard."""
    out = highpass(noise(0.035, 1.2, 35), 1200)
    mix(out, sweep_lowpass(noise(dur, 1.6, 4.0 / max(dur, 0.2)), 9000, 450), 0.0, 1.0)
    mix(out, drive(tone(sub_hz * 2.2, dur * 0.6, 1.0, end_freq=sub_hz * 0.8, decay=5.0), 2.5), 0.0, 0.8)
    mix(out, drive(tone(sub_hz, dur, 1.0, end_freq=sub_hz * 0.3, decay=4.5), 2.0), 0.0, 0.4)
    mix(out, lowpass(noise(dur * 1.3, 0.7, 2.2), 140), 0.02, 0.3)
    mix(out, crackle(dur * 1.3, debris, 0.7, 2.5), 0.05, 0.8)
    return [x * amp for x in drive(out, grit)]


def finish(buf, peak=0.85):
    top = max((abs(x) for x in buf), default=0.0) or 1.0
    return fade_edges([x / top * peak for x in buf])


class Profile:
    name = ""
    display = ""
    octave = 1.0

    def note(self, freq, dur, amp=1.0):
        raise NotImplementedError

    def hit(self, dur=0.08, amp=1.0):
        raise NotImplementedError

    def whoosh(self, dur, lo, hi, amp=1.0, rising=True):
        raise NotImplementedError

    def boom(self, dur, amp=1.0):
        raise NotImplementedError

    def pad(self, freq, dur):
        raise NotImplementedError

    def bass(self, freq, dur):
        raise NotImplementedError

    def arp(self, freq, dur):
        return self.note(freq, dur, 0.8)

    def kick(self):
        return self.hit(0.18, 1.0)

    def tick(self):
        return highpass(noise(0.04, 0.5, 14), 4000)

    def shards(self, dur, amp=0.5):
        raise NotImplementedError

    def sparkle(self, dur=0.4, amp=0.5):
        out = silence(dur)
        for k in range(6):
            mix(out, bell(midi(96 + random.choice((0, 4, 7, 12))) * self.octave, 0.18, amp * 0.6), k * dur / 8)
        return out

    music = {}

class DefaultPack(Profile):
    name = "default"
    display = "Dark drone"
    octave = 0.5

    def note(self, freq, dur, amp=1.0):
        out = tone(freq * self.octave, dur, amp, "tri", decay=7, attack=0.003)
        out = lowpass(out, 2600)
        mix(out, highpass(noise(0.012, amp * 0.5, 4), 1500))
        return out

    def hit(self, dur=0.08, amp=1.0):
        out = tone(150, dur * 1.4, amp, end_freq=60, decay=7)
        mix(out, lowpass(noise(dur, amp * 0.5, 10), 900))
        return out

    def whoosh(self, dur, lo, hi, amp=1.0, rising=True):
        src = noise(dur, amp, 2.0)
        return sweep_lowpass(src, lo * 0.4, hi * 0.4) if rising else sweep_lowpass(src, hi * 0.4, lo * 0.4)

    def boom(self, dur, amp=1.0):
        out = explosion(dur, amp, 70, 2.8, 320)
        mix(out, lowpass(noise(dur * 1.5, 0.5, 1.8), 90), 0.05)
        return out

    def shards(self, dur, amp=0.5):
        return crackle(dur, 90, amp, 2.0)

    def pad(self, freq, dur):
        n = int(dur * SR)
        a = tone(freq, dur, 0.8, "saw", decay=0.0, attack=dur * 0.4)
        mix(a, tone(freq * 1.004, dur, 0.8, "saw", decay=0.0, attack=dur * 0.4))
        a = lowpass(a, 520)
        return [x * min(1.0, (n - i) / (0.3 * n)) for i, x in enumerate(a)]

    def bass(self, freq, dur):
        return lowpass(tone(freq, dur, 1.0, "tri", decay=2.5, attack=0.008), 400)

    def arp(self, freq, dur):
        return self.note(freq, dur, 0.9)

    def tick(self):
        return lowpass(noise(0.05, 0.6, 12), 1800)

    def kick(self):
        return self.hit(0.2, 1.1)

    music = {
        "menu": dict(bpm=50, kind="menu"),
        "battle": dict(bpm=100, kind="battle"),
    }


PROFILES = {p.name: p() for p in (DefaultPack,)}


# ---- Layer helpers ----------------------------------------------------------

def modal(base, ratios, amps, decays, dur, detune=0.0):
    """Struck-metal body: decaying sine partials at (inharmonic) ratios; detune adds a slow beating twin of each."""
    n = int(dur * SR)
    out = [0.0] * n
    for r, a, d in zip(ratios, amps, decays):
        for twin in ((1.0, 1.0 + detune) if detune else (1.0,)):
            f = base * r * twin
            if f > SR * 0.45:
                continue
            w = TAU * f / SR
            k = math.exp(-d / SR)
            env = a
            for i in range(n):
                out[i] += env * math.sin(w * i)
                env *= k
    return fade_edges(out, 0.0008, 0.02)


def click(dur=0.02, cutoff=2500, amp=1.0, decay=60):
    return highpass(noise(dur, amp, decay), cutoff)


def swish(dur, lo, hi, amp=1.0, peak=0.5):
    """Air passing: band of noise whose centre rises to `peak` of the length then falls; envelope follows."""
    n = int(dur * SR)
    out = []
    y1 = y2 = 0.0
    for i in range(n):
        t = i / n
        f = lo + (hi - lo) * (t / peak if t < peak else (1 - t) / (1 - peak))
        a = 1 - math.exp(-TAU * f / SR)
        x = random.uniform(-1, 1)
        y1 += a * (x - y1)
        y2 += a * (y1 - y2)
        out.append((y1 - y2) * 6.0 * amp * math.sin(math.pi * t) ** 1.5)
    return out


def tick_train(count, start_gap, end_gap, amp=0.5, cutoff=2500):
    """Ticks that speed up: tension."""
    out = silence(0.02)
    at = 0.0
    gap = start_gap
    for k in range(count):
        mix(out, click(0.012, cutoff, amp * (0.5 + 0.5 * k / max(count - 1, 1)), 90), at)
        at += gap
        gap += (end_gap - start_gap) / max(count - 1, 1)
    return out


def string_pad(freq, dur, att):
    n = int(dur * SR)
    out = silence(dur)
    for d in (-0.004, 0.005):
        mix(out, tone(freq * (1 + d), dur, 0.5, "saw", decay=0.0, attack=att, vibrato=0.003))
    out = lowpass(out, 750)
    rel = int(n * 0.4)
    for i in range(rel):
        out[n - 1 - i] *= 0.5 - 0.5 * math.cos(math.pi * i / rel)
    return out


def taiko(amp=1.0, size=1.0):
    out = drive(tone(100 * size, 0.4, amp, end_freq=46 * size, decay=6.5), 1.8)
    mix(out, lowpass(noise(0.06, amp * 0.7, 28), 700))
    mix(out, tone(210 * size, 0.1, amp * 0.3, end_freq=120, decay=12))
    return out


def gong(base, dur=2.5, amp=1.0):
    return modal(base, (1, 1.47, 2.09, 2.56, 3.9, 5.3), (1, 0.8, 0.6, 0.5, 0.3, 0.2), (1.6, 1.9, 2.3, 2.6, 3.4, 4.5), dur, 0.004)


# ---- Cues -------------------------------------------------------------------

def note_seq(P, notes, gap, dur=0.3, amp=0.9, wet=0.0):
    out = silence(0.01)
    for k, m in enumerate(notes):
        mix(out, P.note(midi(m), dur, amp), k * gap)
    return reverb(out, wet) if wet else out


def cue_ui_click(P):
    out = P.hit(0.07, 0.8)
    mix(out, P.note(midi(72), 0.09, 0.6))
    return out


def cue_ui_hover(P):
    out = lowpass(click(0.03, 1500, 0.6, 70), 4000)
    mix(out, tone(midi(79) * P.octave * 2, 0.04, 0.3, decay=8))
    return out


def cue_attack(P):
    """Player swing: whoosh, then a light impact on the end of it."""
    out = swish(0.3, 500, 4200, 0.8, 0.6)
    mix(out, tone(180, 0.1, 0.5, end_freq=90, decay=8), 0.21)
    mix(out, lowpass(noise(0.05, 0.5, 30), 1800), 0.21)
    return out


def block_variant(P, v):
    """Dull knock of a weapon on a shield: wood body, a faint metal tick."""
    f = (1.0, 0.86)[v]
    out = tone(210 * f, 0.14, 1.0, end_freq=110 * f, decay=9)
    mix(out, modal(300 * f, (1, 2.3, 4.1), (0.7, 0.4, 0.2), (30, 45, 70), 0.12))
    mix(out, lowpass(noise(0.05, 0.8, 30), 1500))
    mix(out, click(0.015, 3000, 0.25, 90), 0.0)
    return lowpass(out, 3500)


def parry_core(v, base_mul=1.0, ring=1.0):
    base = (1000, 1190, 860)[v] * base_mul
    ratios = (1, 2.76, 5.40, 8.93, 13.34, 1.0042)
    amps = (1.0, 0.7, 0.5, 0.32, 0.18, 0.6)
    decays = (4.2 / ring, 6.0 / ring, 8.0 / ring, 11.0, 16.0, 3.8 / ring)
    out = modal(base, ratios, amps, decays, 1.0 * (0.8 + 0.2 * ring))
    mix(out, click(0.03, 2200, 1.4, 55))
    mix(out, modal(base * 2.3, (1, 1.51), (0.5, 0.3), (28, 36), 0.1))  # the bright "shing" of the contact
    whoomp = drive(tone(125, 0.26, 1.0, end_freq=40, decay=7), 1.6)
    mix(whoomp, lowpass(noise(0.09, 0.6, 20), 320))
    mix(out, whoomp, 0.0, 1.0)
    return out


def parry_variant(P, v):
    return reverb(parry_core(v), 0.12, 0.5)


def cue_perfect_parry(P):
    out = parry_core(0, 1.18, 1.0)
    mix(out, swish(0.35, 2500, 7000, 0.25, 0.9), 0.0)
    for k, m in enumerate((88, 95, 100)):
        mix(out, bell(midi(m), 0.9, 0.5 - k * 0.1, 3.0, 0.9, 4.0), 0.05 + k * 0.07)
    return reverb(out, 0.28, 0.8)


def hit_variant(P, v):
    """Flesh and bone: a heavy thump, a wet noise body, a dry crunch."""
    out = drive(tone((150, 125)[v], 0.22, 1.0, end_freq=45, decay=8), 1.5)
    mix(out, lowpass(noise(0.16, 0.9, 12), 800), 0.0, 0.9)
    crunch = highpass(drive(noise(0.09, 1.0, 16), 3.0), 1500)
    mix(out, crunch, 0.008, 0.5)
    mix(out, crackle(0.12, 140, 0.7, 3.0), 0.01, 0.5)
    mix(out, tone(70, 0.3, 0.5, end_freq=40, decay=6), 0.0)
    return out


def cue_enemy_telegraph(P):
    """Rising tension: accelerating ticks over a thin climbing tone."""
    out = tone(320, 0.42, 0.4, "tri", end_freq=900, decay=0.0, attack=0.1)
    out = lowpass(out, 2200)
    mix(out, tick_train(9, 0.085, 0.032, 0.7, 2600), 0.0)
    return out


def cue_telegraph_heavy(P):
    """Deeper and slower: a growling sub climb with heavy ticks, ends on a held beat."""
    n = 0.75
    out = lowpass(tone(70, n, 0.9, "saw", end_freq=210, decay=0.0, attack=0.25), 600)
    mix(out, tone(35, n, 0.9, end_freq=70, decay=0.0, attack=0.3))
    mix(out, tick_train(7, 0.16, 0.06, 0.9, 900), 0.0)
    mix(out, sweep_lowpass(noise(n, 0.5, 0.0), 200, 1800), 0.0, 0.5)
    return out


def cue_guard_break(P):
    """Shatter: low crack, glassy bright shards, falling debris."""
    out = drive(tone(160, 0.3, 1.0, end_freq=40, decay=7), 2.0)
    mix(out, click(0.05, 1500, 1.3, 40))
    mix(out, modal(2400, (1, 1.34, 1.83, 2.41, 3.12), (0.6, 0.5, 0.4, 0.3, 0.2), (9, 11, 13, 16, 20), 0.5, 0.01), 0.0, 0.6)
    mix(out, highpass(crackle(0.6, 220, 1.0, 3.5), 1800), 0.03, 0.9)
    mix(out, tone(300, 0.5, 0.5, end_freq=70, decay=4, kind="saw"), 0.05, 0.25)
    return reverb(out, 0.15, 0.6)


def cue_stamina_empty(P):
    """Out of breath: a soft gasp and a sagging low tone."""
    out = swish(0.38, 700, 2200, 0.8, 0.3)
    mix(out, lowpass(noise(0.3, 0.3, 4), 900), 0.02)
    mix(out, tone(190, 0.3, 0.4, "tri", end_freq=110, decay=5), 0.04)
    return out


def cue_feint(P):
    """Air only: a quick swish up and down, no impact."""
    return swish(0.22, 1200, 5500, 0.9, 0.45)


def cue_stagger(P):
    """Dazed: a dull blow, a wobbling falling tone, a muffled ring."""
    out = drive(tone(130, 0.2, 1.0, end_freq=50, decay=8), 1.4)
    mix(out, tone(420, 0.55, 0.5, "tri", end_freq=150, decay=3.5, vibrato=0.06), 0.03)
    mix(out, lowpass(modal(600, (1, 2.4, 4.1), (0.5, 0.3, 0.15), (5, 8, 12), 0.5, 0.006), 2500), 0.02, 0.6)
    return out


def cue_souls_gain(P):
    """Soft sparkle, rising."""
    out = silence(0.1)
    for k, m in enumerate((91, 95, 98, 103)):
        mix(out, bell(midi(m), 0.35, 0.35, 3.0, 0.6, 6.0), k * 0.05)
    mix(out, swish(0.3, 3000, 8000, 0.12, 0.8))
    return reverb(out, 0.2, 0.6)


def cue_victory(P):
    return note_seq(P, [57, 60, 64, 69, 64, 69, 72], 0.15, 0.9, 0.85, 0.3)


def cue_death(P):
    out = tone(300 * P.octave * 2, 0.9, 0.8, "tri", end_freq=50, decay=2.5)
    mix(out, P.boom(0.6, 0.7), 0.1)
    return reverb(out, 0.25, 0.9)


# name -> (builder, volume_db, pitch_jitter, cooldown_msec, variants); builders of 2+ variants take (P, v)
CUES = {
    "ui_click": (cue_ui_click, -6, 0.02, 20, 1),
    "ui_hover": (cue_ui_hover, -14, 0.04, 40, 1),
    "attack": (cue_attack, -5, 0.04, 80, 1),
    "block": (block_variant, -4, 0.03, 80, 2),
    "parry": (parry_variant, -2, 0.02, 80, 3),
    "perfect_parry": (cue_perfect_parry, -1, 0.0, 80, 1),
    "hit": (hit_variant, -3, 0.05, 80, 2),
    "enemy_telegraph": (cue_enemy_telegraph, -8, 0.03, 80, 1),
    "telegraph_heavy": (cue_telegraph_heavy, -6, 0.03, 80, 1),
    "guard_break": (cue_guard_break, -3, 0.03, 200, 1),
    "stamina_empty": (cue_stamina_empty, -8, 0.04, 200, 1),
    "feint": (cue_feint, -7, 0.05, 100, 1),
    "stagger": (cue_stagger, -5, 0.03, 200, 1),
    "souls_gain": (cue_souls_gain, -10, 0.05, 60, 1),
    "victory": (cue_victory, -3, 0.0, 1000, 1),
    "death": (cue_death, -3, 0.02, 300, 1),
}


# ---- Music ------------------------------------------------------------------

M, S, D = (0, 7, 12, 15), (0, 7, 12, 14), (0, 7, 12, 16)  # minor, sus, major triad shapes
PROGRESSIONS = {
    "menu": [(45, M), (41, D), (43, S), (40, M), (45, M), (46, D), (41, D), (40, D), (45, M), (48, D), (43, D), (40, M)],
    "battle": [(45, M), (45, M), (41, D), (40, D), (45, M), (43, D), (41, D), (40, M),
               (45, M), (46, D), (45, M), (41, D), (43, D), (40, D), (46, D), (40, D)],
}
SCALE = (0, 3, 5, 7, 10, 12, 15)  # A minor pentatonic-ish, for the sparse melody


def bass_note(root):
    b = root - 12
    while b < 33:
        b += 12
    return b


def drone(loop_len, midi_root):
    """Additive drone with every frequency snapped to whole cycles per loop, so it joins itself without a seam."""
    secs = loop_len / SR
    out = [0.0] * loop_len
    layers = ((1.0, 0.5, 0), (1.5, 0.28, 0), (1.0, 0.2, 2), (2.0, 0.15, 0))  # ratio, gain, extra beating cycles
    harmonics = ((1, 1.0), (2, 0.5), (3, 0.3), (4, 0.15), (5, 0.08))
    for ratio, gain, extra in layers:
        f = round(midi(midi_root) * ratio * secs) / secs + extra / secs
        for h, ha in harmonics:
            w = TAU * f * h / SR
            g = gain * ha
            for i in range(loop_len):
                out[i] += g * math.sin(w * i)
    lfo = TAU * 3 / loop_len
    return [x * (0.78 + 0.22 * math.sin(lfo * i)) for i, x in enumerate(out)]


def render_music(P, name, seed):
    rng = random.Random(seed)
    cfg = P.music[name]
    kind = cfg["kind"]
    chords = PROGRESSIONS[kind]
    battle = kind == "battle"
    beat = 60.0 / cfg["bpm"]
    bar = 4 * beat
    bars = len(chords)
    loop_len = int(bars * bar * SR)
    out = silence(bars * bar)
    for b in range(bars):
        root, iv = chords[b]
        t0 = b * bar
        pad_at = t0 - bar * 0.25 + (bars * bar if b == 0 else 0.0)  # the first pad starts "before" the loop: wrap it to the end
        for k, step in enumerate((iv[0], iv[1], iv[3])):
            mix(out, string_pad(midi(root + 12 + step), bar * 1.5, bar * 0.5), pad_at, 0.13 if k < 2 else 0.09)
        bass = bass_note(root)
        if battle:
            for s in range(8):
                if s == 0 or rng.random() < 0.55:
                    mix(out, P.bass(midi(bass + (12 if s in (3, 7) and rng.random() < 0.3 else 0)), beat * 0.45), t0 + s * beat / 2, 0.34 if s == 0 else 0.22)
            mix(out, taiko(1.0), t0, 0.7)
            if rng.random() < 0.55:
                mix(out, taiko(0.7, 1.15), t0 + 2.5 * beat, 0.4)
            if b % 4 == 3:
                for k in range(3):
                    mix(out, taiko(0.6, 1.3), t0 + (3 + k / 3) * beat, 0.4)
            for beat_i in (1, 3):
                if rng.random() < 0.45:
                    mix(out, click(0.03, 3500, 0.6, 50), t0 + beat_i * beat, 0.12)
            if b % 8 == 0:
                mix(out, gong(midi(bass + 12), 3.0), t0, 0.22)
            if b % 8 == 6:
                swell = sweep_lowpass(noise(2 * bar, 1.0, 0.0), 200, 3500)
                mix(out, [x * (i / len(swell)) ** 2 for i, x in enumerate(swell)], t0, 0.25)
        else:
            mix(out, P.bass(midi(bass), bar * 0.9), t0, 0.4)
            if rng.random() < 0.4:
                pitch = root + 12 + rng.choice(SCALE)
                mix(out, lowpass(bell(midi(pitch), 3.0, 1.0, 2.0, 0.5, 3.0), 2000), t0 + rng.choice((0.0, 1.0, 2.0)) * beat, 0.2)
            if b % 6 == 3:
                mix(out, gong(midi(bass + 12), 4.0), t0, 0.16)
    out = reverb(out, 0.32, 1.3)
    for i in range(loop_len, len(out)):
        out[i - loop_len] += out[i]
    out = out[:loop_len]
    d = drone(loop_len, 33)
    gain = 0.35 if battle else 0.45
    out = [x + y * gain for x, y in zip(out, d)]
    return normalize(out, 0.8)


def normalize(buf, peak):
    top = max((abs(x) for x in buf), default=0.0) or 1.0
    return [x / top * peak for x in buf]


# ---- Output -------------------------------------------------------------------

IMPORT_TEMPLATE = """[remap]

importer="wav"
type="AudioStreamWAV"

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode={loop}
edit/loop_begin=0
edit/loop_end=-1
compress/mode=2
"""


def write_wav(buf, path, loop=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in buf))
    # import loop_mode 2 = forward (music); 0 = as stored in the wav, i.e. none (cues)
    path.with_name(path.name + ".import").write_text(IMPORT_TEMPLATE.format(loop=2 if loop else 0))


def trim_tail(buf, floor=0.004):
    end = len(buf)
    while end > 1 and abs(buf[end - 1]) < floor:
        end -= 1
    return fade_edges(buf[:end], 0.002, 0.02)


def build_pack(P):
    random.seed(1234)
    folder = OUT / f"{P.name}_pack"
    for stale in (folder / "sfx").glob("*.wav*"):
        stale.unlink()
    cue_files = {}
    for name, (builder, _, _, _, variants) in CUES.items():
        files = []
        for v in range(variants):
            buf = trim_tail(finish(builder(P, v) if variants > 1 else builder(P)))
            suffix = f"_{v + 1}" if variants > 1 else ""
            write_wav(buf, folder / "sfx" / f"{name}{suffix}.wav")
            files.append(f"sfx/{name}{suffix}.wav")
        cue_files[name] = files
    music_files = {}
    for index, kind in enumerate(P.music):
        write_wav(render_music(P, kind, 100 + index), folder / "music" / f"{kind}.wav", loop=True)
        music_files[kind] = f"music/{kind}.wav"
    write_bank(P, folder, cue_files, music_files)
    print(f"{P.name}: {len(cue_files)} cues, {len(music_files)} tracks")


def write_bank(P, folder, cue_files, music_files):
    lines = [
        '[gd_resource type="Resource" script_class="AudioBank" format=3]',
        "",
        '[ext_resource type="Script" path="res://view/audio/audio_bank.gd" id="bank"]',
        '[ext_resource type="Script" path="res://view/audio/sound_cue.gd" id="cue"]',
    ]
    for files in list(cue_files.values()) + [[f] for f in music_files.values()]:
        for f in files:
            lines.append(f'[ext_resource type="AudioStream" path="{RES_PREFIX}{P.name}_pack/{f}" id="{f}"]')
    lines.append("")
    for name, files in cue_files.items():
        _, volume, jitter, cooldown, _ = CUES[name]
        refs = ", ".join(f'ExtResource("{f}")' for f in files)
        lines += [
            f'[sub_resource type="Resource" id="cue_{name}"]',
            'script = ExtResource("cue")',
            f"streams = Array[AudioStream]([{refs}])",
            f"volume_db = {float(volume)}",
            f"pitch_jitter = {jitter}",
            f"cooldown_msec = {cooldown}",
            "",
        ]
    cues = ", ".join(f'"{n}": SubResource("cue_{n}")' for n in cue_files)
    music = ", ".join(f'"{k}": ExtResource("{f}")' for k, f in music_files.items())
    lines += ["[resource]", 'script = ExtResource("bank")', f"cues = {{{cues}}}", f"music = {{{music}}}", ""]
    (folder / "sound_bank.tres").write_text("\n".join(lines))
    (folder / "LICENSE.txt").write_text("Generated by tools/gen_audio.py from synthesized waveforms only. CC0 / public domain.\n")


if __name__ == "__main__":
    for key in sys.argv[1:] or PROFILES:
        build_pack(PROFILES[key])
