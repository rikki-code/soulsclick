"""Builds the recorded combat cues (view/packs/audio_pack/default_pack/sfx_rec/) from Kenney CC0 packs with ffmpeg.

usage: python3 tools/sfx_prep.py <kenney_dir>
<kenney_dir> holds the unzipped "Impact Sounds" pack in imp/ and "RPG Audio" in rpg/ (see audio_pack/LICENSES.md).
Keep downloads outside the project; afterwards run tools/gen_audio.py and `godot --headless --path . --import`.
"""
import subprocess, sys, pathlib, re, math, array, cmath
SRC = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/private/tmp/kenney_dl")
I = SRC / "imp/Audio"; R = SRC / "rpg/Audio"
OUT = pathlib.Path(__file__).resolve().parent.parent / "view/packs/audio_pack/default_pack/sfx_rec"
OUT.mkdir(exist_ok=True)
WORK = pathlib.Path("/private/tmp/kenney_work"); WORK.mkdir(exist_ok=True)
for f in OUT.glob("*"): f.unlink()
def imp(n): return I / f"impact{n}.ogg"
def rpg(n): return R / f"{n}.ogg"
# name -> list of recipes; recipe = list of (file, filter, delay_ms, gain_db)
def L(f, filt="", delay=0, gain=0): return (f, filt, delay, gain)
S = {
 "attack_1": [L(imp("Punch_heavy_000")), L(imp("Wood_heavy_001"), "", 0, -3), L(imp("Metal_heavy_002"), "lowpass=f=3500", 0, -11)],
 "attack_2": [L(imp("Soft_heavy_001")), L(imp("Wood_heavy_003"), "", 0, -3), L(imp("Metal_heavy_003"), "lowpass=f=3500", 0, -11)],
 "attack_3": [L(imp("Wood_heavy_004")), L(imp("Punch_heavy_002"), "", 0, -2), L(imp("Metal_heavy_000"), "lowpass=f=3500", 0, -12)],
 "hit_1": [L(imp("Soft_heavy_000"), "lowpass=f=3500"), L(imp("Punch_heavy_001"), "lowpass=f=2500", 0, -3)],
 "hit_2": [L(imp("Punch_heavy_000"), "lowpass=f=3000"), L(imp("Soft_heavy_002"), "lowpass=f=2500", 0, -2)],
 "block_1": [L(imp("Wood_heavy_000")), L(imp("Metal_light_000"), "lowpass=f=4000", 0, -12)],
 "block_2": [L(imp("Wood_heavy_002")), L(imp("Metal_light_001"), "lowpass=f=4000", 0, -12)],
 "parry_1": [L(imp("Metal_light_002"))],
 "parry_2": [L(imp("Metal_light_004"))],
 "parry_3": [L(imp("Metal_light_003"))],
 "perfect_parry_1": [L(imp("Metal_light_003")), L(imp("Metal_medium_003"), "", 0, -4), L(imp("Bell_heavy_002"), "volume=1", 25, -9)],
 "guard_break_1": [L(imp("Wood_heavy_001")), L(imp("Punch_heavy_003"), "", 0, -2), L(imp("Metal_heavy_001"), "lowpass=f=3500", 0, -9), L(imp("Mining_001"), "", 60, -8)],
 "guard_break_2": [L(imp("Wood_heavy_003")), L(imp("Punch_heavy_001"), "", 0, -2), L(imp("Metal_heavy_003"), "lowpass=f=3500", 0, -9), L(imp("Mining_000"), "", 60, -8)],
 "enemy_telegraph_1": [L(rpg("drawKnife1"))],
 "enemy_telegraph_2": [L(rpg("drawKnife2"))],
 "enemy_telegraph_3": [L(rpg("drawKnife3"))],
 "telegraph_heavy_1": [L(rpg("drawKnife3"), "asetrate=44100*0.72,aresample=44100,lowpass=f=5000"), L(rpg("clothBelt"), "asetrate=44100*0.8,aresample=44100", 150, -3)],
 "telegraph_heavy_2": [L(rpg("drawKnife2"), "asetrate=44100*0.7,aresample=44100,lowpass=f=5000"), L(rpg("beltHandle2"), "asetrate=44100*0.8,aresample=44100", 200, -3)],
 "feint_1": [L(rpg("cloth3"), "atempo=1.5,highpass=f=500")],
 "feint_2": [L(rpg("cloth2"), "atempo=1.5,highpass=f=500")],
}
TONAL = ("parry", "perfect_parry", "attack", "block", "guard_break", "enemy_telegraph", "telegraph_heavy")
CHORD = (0, 3, 7, 12)  # A minor triad (A, C, E) as semitones above A, wrapped at the octave
def fft(x):
    n = len(x)
    if n == 1: return x
    e = fft(x[0::2]); o = fft(x[1::2])
    t = [cmath.exp(-2j*math.pi*k/n) * o[k] for k in range(n//2)]
    return [e[k] + t[k] for k in range(n//2)] + [e[k] - t[k] for k in range(n//2)]
def dominant_hz(wavfile, n=8192, lo=100, hi=2500):
    """Strongest spectral peak (Hann window, parabolic interpolation) of the first n samples after the onset."""
    raw = subprocess.run(["ffmpeg","-v","error","-i",str(wavfile),"-f","s16le","-ac","1","-ar","44100","-"],capture_output=True).stdout
    pcm = array.array("h"); pcm.frombytes(raw)
    top = max(abs(v) for v in pcm)
    st = next(i for i, v in enumerate(pcm) if abs(v) > 0.3 * top)
    seg = list(pcm[st:st+n]); seg += [0] * (n - len(seg))
    spec = fft([v * (0.5 - 0.5*math.cos(2*math.pi*i/n)) for i, v in enumerate(seg)])
    mag = [abs(c) for c in spec[:n//2]]
    k0 = int(lo*n/44100); k1 = int(hi*n/44100)
    k = max(range(k0, k1), key=lambda i: mag[i])
    a, b, c = (math.log(mag[k+d] + 1e-9) for d in (-1, 0, 1))
    off = 0.5 * (a - c) / (a - 2*b + c) if a - 2*b + c else 0
    return (k + off) * 44100 / n
def shift_to_chord(hz):
    """Semitone shift (|s| <= 2) that moves hz to the nearest A / C / E."""
    rel = (12 * math.log2(hz / 440)) % 12
    return min((t - rel for t in CHORD), key=abs)
def peak_of(wavfile):
    r = subprocess.run(["ffmpeg","-nostats","-i",str(wavfile),"-af","volumedetect","-f","null","-"],capture_output=True,text=True).stderr
    return float(re.search(r"max_volume: (-?[\d.]+) dB", r).group(1))
for name, layers in S.items():
    cmd = ["ffmpeg","-v","error","-y"]; fc = []
    for i,(f,filt,d,g) in enumerate(layers):
        cmd += ["-i", str(f)]
        chain = ["aformat=sample_rates=44100:channel_layouts=mono"]
        if filt and filt != "volume=1": chain.append(filt)
        if g: chain.append(f"volume={g}dB")
        if d: chain.append(f"adelay={d}")
        fc.append(f"[{i}]" + ",".join(chain) + f"[a{i}]")
    ins = "".join(f"[a{i}]" for i in range(len(layers)))
    fc.append(f"{ins}amix=inputs={len(layers)}:normalize=0:duration=longest,aformat=sample_rates=44100:channel_layouts=mono[o]")
    tmp = WORK/(name+".wav")
    subprocess.run(cmd+["-filter_complex",";".join(fc),"-map","[o]",str(tmp)],check=True)
    if name.startswith(TONAL):
        hz = dominant_hz(tmp); semis = shift_to_chord(hz); r = 2 ** (semis / 12)
        print(f"  {name}: {hz:.0f} Hz -> shift {semis:+.2f} st")
        tuned = tmp.with_name(name + "_t.wav")
        subprocess.run(["ffmpeg","-v","error","-y","-i",str(tmp),"-af",f"asetrate=44100*{r:.6f},aresample=44100,atempo={1/r:.6f}",str(tuned)],check=True)
        tmp = tuned
    tgt = -3.0 if name.startswith(("enemy_tele","telegraph","feint")) else -1.0
    gain = tgt - peak_of(tmp)
    subprocess.run(["ffmpeg","-v","error","-y","-i",str(tmp),"-af",f"volume={gain}dB,afade=t=out:st=0:d=0.001" if False else f"volume={gain}dB","-c:a","pcm_s16le",str(OUT/(name+".wav"))],check=True)
    print(name, round(gain,1))
