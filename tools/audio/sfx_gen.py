"""Alamat Defense sound-effect generator (B175). Writes .ogg files Roblox accepts (also .mp3 / .wav).

  py tools/audio/sfx_gen.py synth <preset> [--seed N] [--variants K] [--out DIR]   offline procedural synth
  py tools/audio/sfx_gen.py eleven "<prompt>" [--seconds 1.5] [--name X] [--out DIR] AI text-to-SFX (ElevenLabs)
  py tools/audio/sfx_gen.py pack [--place lobby|game|all] [--only A,B] [--out DIR]   one file per SoundService slot
  py tools/audio/sfx_gen.py upload <file> [--name X]                                  Roblox Open Cloud upload
  py tools/audio/sfx_gen.py list                                                      presets + slot map

Keys (environment variables, never committed): ELEVENLABS_API_KEY (eleven), ROBLOX_API_KEY + ROBLOX_CREATOR_ID
(upload; Open Cloud key with the Assets write scope; creator = your user id). Without keys only synth/pack work.
Default output: "Claude outputs/sfx/". Wiring = paste the SoundId on the Sound named after the slot under
SoundService (docs/systems/match-audio.md, ui-feedback.md) -- never a code change. Skill: .claude/skills/game-sfx.
Needs: py -m pip install numpy soundfile
"""
import argparse
import json
import os
import sys
import time
import urllib.request
import uuid
from pathlib import Path

import numpy as np
import soundfile as sf

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Claude outputs" / "sfx"


# ================================================================ synth building blocks
def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, a=0.005, d=0.0, s=1.0, r=0.05, sec=None):
    """ADSR envelope over n samples (times in seconds; sustain level s)."""
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(0, n - a_n - d_n - r_n)
    e = np.concatenate([np.linspace(0, 1, max(1, a_n)), np.linspace(1, s, max(1, d_n)), np.full(s_n, s),
                        np.linspace(s, 0, max(1, r_n))])
    return np.pad(e, (0, max(0, n - len(e))))[:n]


def osc(freq, sec, wave="sine", vib=0.0, vib_hz=6.0):
    """freq: number or array (pitch sweep). Phase-accumulated so sweeps are clean."""
    n = int(SR * sec)
    f = np.full(n, float(freq)) if np.isscalar(freq) else np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(freq)), freq)
    if vib:
        f = f * (1 + vib * np.sin(2 * np.pi * vib_hz * t_axis(sec)[:n]))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if wave == "sine":
        return np.sin(ph)
    if wave == "square":
        return np.sign(np.sin(ph)) * 0.6
    if wave == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    if wave == "tri":
        return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1) - 1) - 1
    raise ValueError(wave)


def noise(sec, rng):
    return rng.uniform(-1, 1, int(SR * sec))


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be an array (filter sweep)."""
    c = np.full(len(x), float(cutoff)) if np.isscalar(cutoff) else np.interp(np.linspace(0, 1, len(x)), np.linspace(0, 1, len(cutoff)), cutoff)
    a = 1 - np.exp(-2 * np.pi * c / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def mix(*parts):
    n = max(len(p) for p in parts)
    return sum(np.pad(p, (0, n - len(p))) for p in parts)


def at(x, sec):
    """Delay a sound by sec (for sequences)."""
    return np.pad(x, (int(SR * sec), 0))


def note(semi, base=440.0):
    return base * 2 ** (semi / 12)


def tone(freq, sec, wave="sine", a=0.003, r=0.08, vol=1.0, **k):
    x = osc(freq, sec, wave, **k)
    return x * env(len(x), a=a, r=r) * vol


def finish(x, peak_db=-1.0, fade=0.004):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * 10 ** (peak_db / 20)
    f = int(fade * SR)
    if f and len(x) > 2 * f:
        x[:f] *= np.linspace(0, 1, f)
        x[-f:] *= np.linspace(1, 0, f)
    return x.astype(np.float32)


# ================================================================ presets (seeded: same seed = same sound)
def P_click(r):   # short wooden tick + tiny chime: UI press
    return mix(highpass(noise(0.03, r), 1500) * env(int(SR * 0.03), a=0.001, r=0.025) * 0.6,
               tone(note(r.integers(14, 18)), 0.07, "tri", r=0.06, vol=0.5))


def P_hover(r):   # very soft high blip
    return tone(note(r.integers(19, 23)), 0.06, "sine", a=0.004, r=0.05, vol=0.35)


def P_open(r):    # rising two-note chime
    return mix(tone(note(7), 0.12, "tri"), at(tone(note(12), 0.2, "tri", r=0.15), 0.06))


def P_close(r):   # falling two-note chime
    return mix(tone(note(12), 0.1, "tri"), at(tone(note(5), 0.18, "tri", r=0.14), 0.05))


def P_confirm(r):  # bright major third + fifth
    return mix(tone(note(12), 0.25, "tri", r=0.2), at(tone(note(16), 0.25, "tri", r=0.2), 0.05),
               at(tone(note(19), 0.35, "sine", r=0.3), 0.1))


def P_cancel(r):
    return mix(tone(note(5), 0.12, "square", vol=0.4), at(tone(note(0), 0.18, "square", r=0.15, vol=0.4), 0.07))


def P_error(r):   # low double buzz
    b = lowpass(osc(note(-17), 0.12, "saw"), 1800) * env(int(SR * 0.12), r=0.04)
    return mix(b, at(b, 0.15))


def P_coin(r):    # classic coin: two fast high notes
    return mix(tone(note(r.integers(22, 25)), 0.06, "square", vol=0.5), at(tone(note(29), 0.3, "square", r=0.25, vol=0.5), 0.06))


def P_cash(r):    # coin shower
    return mix(*[at(tone(note(int(r.integers(24, 34))), 0.12, "tri", r=0.1, vol=0.5), k * 0.045 + r.uniform(0, 0.02)) for k in range(7)])


def P_levelup(r):  # rising arpeggio + sparkle
    seq = [0, 4, 7, 12, 16, 19, 24]
    return mix(*[at(tone(note(s + 3), 0.22, "tri", r=0.18, vol=0.7), i * 0.06) for i, s in enumerate(seq)],
               at(P_sparkle(r), 0.35))


def P_sparkle(r):  # high random shimmer
    return mix(*[at(tone(note(int(r.integers(28, 40))), 0.18, "sine", r=0.16, vol=0.3), r.uniform(0, 0.35)) for _ in range(10)])


def P_reward_pop(r):  # pop + chime
    pop = osc(np.linspace(900, 250, 50), 0.05, "sine") * env(int(SR * 0.05), r=0.04)
    return mix(pop, at(tone(note(19), 0.3, "tri", r=0.25, vol=0.6), 0.03), at(P_sparkle(r) * 0.6, 0.05))


def P_summon_charge(r):  # rising magical swell (2 s)
    sec = 2.0
    sweep = osc(np.geomspace(110, 880, 64), sec, "saw", vib=0.01)
    sw = lowpass(sweep, np.geomspace(300, 6000, 64)) * env(int(SR * sec), a=1.6, r=0.3) * 0.6
    air = lowpass(noise(sec, r), np.geomspace(500, 8000, 64)) * env(int(SR * sec), a=1.8, r=0.2) * 0.3
    return mix(sw, air, at(P_sparkle(r), 1.4))


def P_summon_burst(r):  # boom + shimmer chord
    return mix(P_explosion(r) * 0.7, *[tone(note(s + 3), 1.2, "tri", r=1.0, vol=0.45) for s in (0, 7, 12, 16)], at(P_sparkle(r), 0.05))


def P_reveal(r):   # glittering major chord swell (rare unit reveal)
    return mix(*[at(tone(note(s), 1.4, "sine", a=0.15, r=1.0, vol=0.5, vib=0.004), i * 0.08) for i, s in enumerate((0, 4, 7, 12, 16))],
               at(P_sparkle(r), 0.2))


def P_announce(r):  # little fanfare
    seq = [(0, 0.0, 0.14), (0, 0.15, 0.14), (7, 0.3, 0.5)]
    return mix(*[at(tone(note(s - 5), d, "square", r=0.08, vol=0.5) + tone(note(s + 7 - 5), d, "tri", r=0.08, vol=0.4), t0) for s, t0, d in seq])


def P_reel_tick(r):  # slot-reel tick
    return highpass(noise(0.025, r), 2500) * env(int(SR * 0.025), a=0.001, r=0.02)


def P_land(r):     # heavy thunk + bell (trait lands)
    thunk = lowpass(osc(np.linspace(180, 60, 40), 0.25, "sine"), 900) * env(int(SR * 0.25), r=0.2)
    return mix(thunk, at(tone(note(12), 0.6, "sine", r=0.5, vol=0.4), 0.02))


def P_wave_tick(r):  # countdown tick
    return tone(note(12), 0.08, "square", r=0.06, vol=0.4)


def P_next_wave(r):  # war horn-ish: detuned saws, low-passed
    sec = 1.1
    h = mix(osc(note(-21), sec, "saw", vib=0.006, vib_hz=5), osc(note(-21) * 1.006, sec, "saw"), osc(note(-14), sec, "saw") * 0.5)
    return lowpass(h, np.linspace(600, 2200, 16)) * env(int(SR * sec), a=0.12, r=0.35)


def P_boss_warning(r):  # low pulsing alarm x3
    one = lowpass(osc(np.linspace(note(-24), note(-28), 20), 0.45, "saw"), 1200) * env(int(SR * 0.45), a=0.02, r=0.1)
    return mix(*[at(one, k * 0.55) for k in range(3)], lowpass(noise(1.6, r), 200) * 0.25)


def P_unit_placed(r):  # ground thud + small chime
    thud = lowpass(noise(0.15, r), 400) * env(int(SR * 0.15), a=0.002, r=0.12) * 1.2
    return mix(thud, at(tone(note(16), 0.2, "tri", r=0.15, vol=0.4), 0.03))


def P_unit_invalid(r):
    return lowpass(osc(note(-20), 0.22, "square"), 1500) * env(int(SR * 0.22), r=0.05) * 0.6


def P_enemy_killed(r):  # soft pop + puff
    pop = osc(np.linspace(r.uniform(500, 700), 120, 30), 0.08, "sine") * env(int(SR * 0.08), r=0.06)
    puff = lowpass(noise(0.12, r), 2500) * env(int(SR * 0.12), r=0.1) * 0.4
    return mix(pop, puff)


def P_explosion(r):
    sec = 1.2
    n = lowpass(noise(sec, r), np.geomspace(5000, 150, 32)) * env(int(SR * sec), a=0.002, d=0.1, s=0.5, r=0.9)
    boom = osc(np.geomspace(120, 35, 32), sec, "sine") * env(int(SR * sec), a=0.002, r=0.8)
    return mix(n, boom * 0.9)


def P_fireball(r):  # whoosh + crackle impact
    sec = 0.7
    whoosh = lowpass(noise(sec, r), np.concatenate([np.geomspace(300, 4000, 16), np.geomspace(4000, 400, 16)])) * env(int(SR * sec), a=0.25, r=0.3)
    crack = at(highpass(noise(0.25, r), 1500) * env(int(SR * 0.25), r=0.2) * 0.5, 0.45)
    return mix(whoosh, crack)


def P_magic_cast(r):  # shimmer sweep up
    sec = 0.8
    sw = osc(np.geomspace(400, 2400, 32), sec, "sine", vib=0.02, vib_hz=12) * env(int(SR * sec), a=0.05, r=0.4) * 0.6
    return mix(sw, P_sparkle(r) * 0.7)


def P_victory(r):  # major fanfare arpeggio + chord
    seq = [0, 4, 7, 12]
    lead = mix(*[at(tone(note(s), 0.18, "square", r=0.1, vol=0.45), i * 0.12) for i, s in enumerate(seq)])
    chord = at(mix(*[tone(note(s), 1.2, "tri", a=0.02, r=0.9, vol=0.45) for s in (0, 4, 7, 12)]), 0.5)
    return mix(lead, chord, at(P_sparkle(r), 0.55))


def P_defeat(r):  # slow minor descent
    seq = [7, 3, 0, -5]
    return mix(*[at(tone(note(s - 5), 0.45, "tri", a=0.02, r=0.35, vol=0.55, vib=0.006), i * 0.32) for i, s in enumerate(seq)])


PRESETS = {k[2:]: v for k, v in globals().items() if k.startswith("P_")}

# SoundService slot -> preset (slot names from the GameAudio / LobbyAudio [DIAG] lists). BGM is not synthesized.
SLOTS = {
    "lobby": {"Click": "click", "Hover": "hover", "Open": "open", "Close": "close", "Confirm": "confirm",
              "Cancel": "cancel", "Error": "error", "HotbarClick": "click", "HotbarHover": "hover", "Sell": "coin",
              "LevelUp": "levelup", "RewardPop": "reward_pop", "SummonCharge": "summon_charge",
              "SummonBurst": "summon_burst", "ALReveal": "reveal", "TraitGoodReveal": "reveal",
              "TraitLand": "land", "TraitReelTick": "reel_tick", "AdminAnnounce": "announce"},
    "game": {"Atk_Explosion": "explosion", "Atk_Fireball": "fireball", "Atk_MagicCast": "magic_cast",
             "BossWarning": "boss_warning", "CashFarm": "coin", "CashWave": "cash", "Defeat": "defeat",
             "EnemyKilled": "enemy_killed", "NextWave": "next_wave", "UnitInvalid": "unit_invalid",
             "UnitPlaced": "unit_placed", "Victory": "victory", "WaveTick": "wave_tick"},
}


def write(x, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    fmt = path.suffix.lstrip(".").upper()
    if fmt == "OGG":
        sf.write(str(path), x, SR, format="OGG", subtype="VORBIS")
    elif fmt == "MP3":
        sf.write(str(path), x, SR, format="MP3", subtype="MPEG_LAYER_III")
    else:
        sf.write(str(path), x, SR, subtype="PCM_16")
    return path


def synth(preset, seed=1):
    if preset not in PRESETS:
        sys.exit("unknown preset '%s' -- try: %s" % (preset, ", ".join(sorted(PRESETS))))
    return finish(PRESETS[preset](np.random.default_rng(seed)))


# ================================================================ ElevenLabs text-to-sound-effects (AI)
def eleven(prompt, seconds=None, influence=0.4):
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        sys.exit("ELEVENLABS_API_KEY is not set (elevenlabs.io > Profile > API keys; the free tier includes SFX credits)")
    body = {"text": prompt, "prompt_influence": influence}
    if seconds:
        body["duration_seconds"] = max(0.5, min(22.0, float(seconds)))
    req = urllib.request.Request("https://api.elevenlabs.io/v1/sound-generation", data=json.dumps(body).encode(),
                                 headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()  # mp3 bytes


# ================================================================ Roblox Open Cloud upload (optional)
def upload(path, name):
    key, creator = os.environ.get("ROBLOX_API_KEY"), os.environ.get("ROBLOX_CREATOR_ID")
    if not (key and creator):
        sys.exit("set ROBLOX_API_KEY (Open Cloud, Assets read+write) and ROBLOX_CREATOR_ID (your user id) -- or upload "
                 "by hand: Studio > Asset Manager > Bulk Import")
    path = Path(path)
    meta = {"assetType": "Audio", "displayName": name[:50], "description": "Alamat Defense SFX",
            "creationContext": {"creator": {"userId": str(creator)}}}
    ctype = {"ogg": "audio/ogg", "mp3": "audio/mpeg", "wav": "audio/wav"}[path.suffix.lstrip(".").lower()]
    b = "----sfx" + uuid.uuid4().hex
    data = (f"--{b}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n{json.dumps(meta)}\r\n"
            f"--{b}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{path.name}\"\r\n"
            f"Content-Type: {ctype}\r\n\r\n").encode() + path.read_bytes() + f"\r\n--{b}--\r\n".encode()
    req = urllib.request.Request("https://apis.roblox.com/assets/v1/assets", data=data,
                                 headers={"x-api-key": key, "Content-Type": "multipart/form-data; boundary=" + b})
    op = json.loads(urllib.request.urlopen(req, timeout=120).read())
    for _ in range(30):  # poll the long-running operation
        if op.get("done"):
            return op.get("response", {}).get("assetId"), op
        time.sleep(2)
        r = urllib.request.Request("https://apis.roblox.com/assets/v1/" + op["path"], headers={"x-api-key": key})
        op = json.loads(urllib.request.urlopen(r, timeout=60).read())
    return None, op


# ================================================================ CLI
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["synth", "eleven", "pack", "upload", "list"])
    ap.add_argument("arg", nargs="?")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--variants", type=int, default=1)
    ap.add_argument("--seconds", type=float)
    ap.add_argument("--name")
    ap.add_argument("--place", default="all")
    ap.add_argument("--only")
    ap.add_argument("--fmt", default="ogg", choices=["ogg", "mp3", "wav"])
    ap.add_argument("--out", default=str(OUT))
    a = ap.parse_args()
    out = Path(a.out)
    if a.mode == "list":
        print("presets:", ", ".join(sorted(PRESETS)))
        for place, slots in SLOTS.items():
            print(place + ":", ", ".join("%s<-%s" % kv for kv in slots.items()))
    elif a.mode == "synth":
        for k in range(a.variants):
            p = write(synth(a.arg, a.seed + k), out / ("%s_%d.%s" % (a.name or a.arg, a.seed + k, a.fmt)))
            print(p)
    elif a.mode == "pack":
        only = set(a.only.split(",")) if a.only else None
        for place, slots in SLOTS.items():
            if a.place not in ("all", place):
                continue
            for slot, preset in slots.items():
                if only and slot not in only:
                    continue
                print(write(synth(preset, a.seed), out / place / ("%s.%s" % (slot, a.fmt))))
    elif a.mode == "eleven":
        name = a.name or "".join(c if c.isalnum() else "_" for c in a.arg)[:40]
        p = out / "eleven" / (name + ".mp3")
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(eleven(a.arg, a.seconds))
        print(p)
    elif a.mode == "upload":
        asset, op = upload(a.arg, a.name or Path(a.arg).stem)
        print("rbxassetid://%s" % asset if asset else json.dumps(op, indent=1))


if __name__ == "__main__":
    main()
