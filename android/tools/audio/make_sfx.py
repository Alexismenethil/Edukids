"""Efectos de sonido y ambientes de EduKids, sintetizados con numpy.

Son sonidos cortos, suaves y afinados con la música del juego (mi menor): usan la pentatónica de
sol mayor (sol, la, si, re, mi), así cualquier efecto suena en armonía con la pista. Los timbres son
de madera y metal pequeño (kalimba, campanitas, cuerda pulsada), con un poco de sala.

    python3 tools/audio/make_sfx.py                # todo
    python3 tools/audio/make_sfx.py correct win    # solo algunos

Necesita numpy y ffmpeg. Escribe los efectos (.wav) en assets/audio/sfx y los ambientes (.ogg) en
assets/audio/ambience. Para cambiar
un sonido se edita su función y se vuelve a generar; el juego los pide por nombre (Sounds.play).
"""

from __future__ import annotations

import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
SFX = ROOT / "assets/audio/sfx"
AMBIENCE = ROOT / "assets/audio/ambience"

# Pentatónica de sol mayor (relativa de mi menor).
NOTE = {"E3": 164.81, "G3": 196.00, "A3": 220.00, "B3": 246.94, "D4": 293.66, "E4": 329.63, "G4": 392.00, "A4": 440.00,
        "B4": 493.88, "D5": 587.33, "E5": 659.26, "G5": 783.99, "A5": 880.00, "B5": 987.77, "D6": 1174.66,
        "E6": 1318.51, "G6": 1567.98, "A6": 1760.00, "B6": 1975.53}
RNG = np.random.default_rng(7)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(SR * seconds)) / SR


def place(buffer: np.ndarray, sound: np.ndarray, at: float, gain: float = 1.0) -> None:
    start = int(at * SR)
    end = min(len(buffer), start + len(sound))
    buffer[start:end] += sound[: end - start] * gain


def lowpass(x: np.ndarray, cutoff) -> np.ndarray:
    """Filtro de un polo; `cutoff` puede ser un número o una curva por muestra."""
    cut = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    alpha = 1.0 - np.exp(-2.0 * np.pi * cut / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x: np.ndarray, cutoff) -> np.ndarray:
    return x - lowpass(x, cutoff)


def fade(x: np.ndarray, attack: float = 0.003, release: float = 0.02) -> np.ndarray:
    a, r = int(attack * SR), int(release * SR)
    y = x.copy()
    if a > 0:
        y[:a] *= np.linspace(0.0, 1.0, a)
    if r > 0:
        y[-r:] *= np.linspace(1.0, 0.0, r)
    return y


def mallet(freq: float, seconds: float = 0.6, decay: float = 0.22, bright: float = 0.35) -> np.ndarray:
    """Lámina de kalimba: fundamental redonda, un armónico que se apaga pronto y un golpecito."""
    x = t(seconds)
    tone = np.sin(2 * np.pi * freq * x) * np.exp(-x / decay)
    tone += bright * np.sin(2 * np.pi * freq * 2.0 * x) * np.exp(-x / (decay * 0.35))
    tone += bright * 0.4 * np.sin(2 * np.pi * freq * 3.01 * x) * np.exp(-x / (decay * 0.16))
    click = lowpass(RNG.normal(0, 1, len(x)) * np.exp(-x / 0.004), 3500.0) * 0.18
    return fade(tone + click, 0.002, 0.03)


def bell(freq: float, seconds: float = 0.9, decay: float = 0.3) -> np.ndarray:
    """Campanita: parciales de metal pequeño, brillo corto."""
    x = t(seconds)
    tone = np.sin(2 * np.pi * freq * x) * np.exp(-x / decay)
    tone += 0.42 * np.sin(2 * np.pi * freq * 2.76 * x) * np.exp(-x / (decay * 0.5))
    tone += 0.2 * np.sin(2 * np.pi * freq * 5.4 * x) * np.exp(-x / (decay * 0.25))
    return fade(tone, 0.002, 0.04)


def pluck(freq: float, seconds: float = 1.0, damp: float = 0.996) -> np.ndarray:
    """Cuerda pulsada (Karplus-Strong), como un charango tocado suave."""
    n = int(SR * seconds)
    period = max(2, int(round(SR / freq)))
    line = lowpass(RNG.uniform(-1, 1, period), 5000.0)
    out = np.zeros(n)
    for i in range(n):
        value = line[i % period]
        out[i] = value
        nxt = line[(i + 1) % period]
        line[i % period] = damp * 0.5 * (value + nxt)
    return fade(out, 0.001, 0.05)


def chirp(f0: float, f1: float, seconds: float, decay: float, curve: float = 1.0) -> np.ndarray:
    """Tono que resbala de f0 a f1."""
    x = t(seconds)
    u = (x / seconds) ** curve
    freq = f0 + (f1 - f0) * u
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return fade(np.sin(phase) * np.exp(-x / decay), 0.003, 0.02)


def swish(seconds: float, f0: float, f1: float, body: float = 0.5) -> np.ndarray:
    """Soplo de aire: ruido que barre de f0 a f1 con forma de campana."""
    x = t(seconds)
    cut = f0 + (f1 - f0) * (x / seconds)
    noise = highpass(lowpass(RNG.normal(0, 1, len(x)), cut), 180.0)
    return noise * np.sin(np.pi * x / seconds) ** (1.0 / body) * 0.5


def thud(seconds: float = 0.2, f0: float = 150.0, f1: float = 58.0) -> np.ndarray:
    body = chirp(f0, f1, seconds, seconds * 0.35, 0.6)
    x = t(seconds)
    tap = lowpass(RNG.normal(0, 1, len(x)) * np.exp(-x / 0.012), 900.0) * 0.5
    return body + tap


def room(x: np.ndarray, wet: float = 0.14, seconds: float = 0.45) -> np.ndarray:
    """Un poco de sala: cola corta y clara, para que nada suene seco."""
    n = int(SR * seconds)
    tail = RNG.normal(0, 1, n) * np.exp(-np.arange(n) / (SR * seconds * 0.22))
    tail = lowpass(tail, 4200.0)
    tail[: int(0.008 * SR)] = 0.0
    tail /= np.sqrt(np.sum(tail ** 2))
    padded = np.concatenate([x, np.zeros(n)])
    wet_signal = np.convolve(x, tail)
    padded[: len(wet_signal)] += wet * wet_signal[: len(padded)]
    return padded


def finish(x: np.ndarray, peak_db: float = -7.0) -> np.ndarray:
    x = fade(x, 0.001, 0.05)
    peak = np.max(np.abs(x))
    return x / peak * 10 ** (peak_db / 20.0) if peak > 0 else x


def save(folder: Path, name: str, x: np.ndarray, ogg: bool = False) -> None:
    """Los efectos cortos se guardan en WAV (sin pérdida y pesan poco); los ambientes largos, en
    OGG estéreo, que empalma el bucle sin cortes."""
    folder.mkdir(parents=True, exist_ok=True)
    data = x if x.ndim == 2 else x[:, None]
    wav = folder / f"{name}.wav"
    with wave.open(str(wav), "wb") as handle:
        handle.setnchannels(data.shape[1])
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes((np.clip(data, -1, 1) * 32767).astype("<i2").tobytes())
    if ogg:
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav), "-c:a", "vorbis", "-strict", "-2", "-ac", "2",
                        "-q:a", "6", str(folder / f"{name}.ogg")], check=True)
        wav.unlink()


def arpeggio(notes, gap: float, voice=mallet, seconds: float = 0.7, tail: float = 0.6, **kwargs) -> np.ndarray:
    out = np.zeros(int(SR * (gap * len(notes) + seconds + tail)))
    for i, name in enumerate(notes):
        place(out, voice(NOTE[name], seconds, **kwargs), i * gap, 1.0 - 0.06 * i)
    return out


# --- Interfaz ------------------------------------------------------------------------------------

def tap() -> np.ndarray:
    return finish(room(mallet(NOTE["G5"], 0.16, 0.045, 0.2), 0.08, 0.2), -12.0)


def check() -> np.ndarray:
    return finish(room(arpeggio(["D5", "G5"], 0.07, seconds=0.35, decay=0.1, tail=0.1), 0.1), -10.0)


def card() -> np.ndarray:
    return finish(swish(0.26, 500.0, 2400.0, 0.7), -16.0)


def hint() -> np.ndarray:
    return finish(room(arpeggio(["B5", "E6"], 0.11, bell, 0.7, 0.2, decay=0.22), 0.16), -11.0)


def pop() -> np.ndarray:
    return finish(room(chirp(480.0, 1150.0, 0.09, 0.035, 0.7), 0.08, 0.2), -12.0)


def title() -> np.ndarray:
    out = np.zeros(int(SR * 3.0))
    for i, name in enumerate(["G4", "D5", "G5", "B5"]):
        place(out, mallet(NOTE[name], 2.0, 0.6, 0.25), 0.12 * i, 0.8)
    x = t(2.6)
    pad = sum(np.sin(2 * np.pi * NOTE[n] * x) for n in ("G4", "B4", "D5")) / 3.0
    pad *= np.minimum(1.0, x / 0.7) * np.exp(-np.maximum(0.0, x - 0.9) / 0.8)
    place(out, pad, 0.0, 0.22)
    place(out, bell(NOTE["G6"], 1.2, 0.5), 0.5, 0.25)
    return finish(room(out, 0.22, 0.7), -9.0)


# --- Respuestas ----------------------------------------------------------------------------------

def correct() -> np.ndarray:
    out = arpeggio(["G5", "B5", "D6"], 0.075, seconds=0.6, decay=0.2)
    place(out, bell(NOTE["G6"], 0.8, 0.28), 0.17, 0.22)
    return finish(room(out, 0.16), -8.0)


def streak() -> np.ndarray:
    out = arpeggio(["G5", "B5", "D6", "G6"], 0.065, seconds=0.7, decay=0.24, tail=1.0)
    for i, name in enumerate(["B6", "G6", "D6", "E6", "B6"]):
        place(out, bell(NOTE[name], 0.6, 0.2), 0.3 + i * 0.085, 0.16)
    return finish(room(out, 0.2, 0.6), -7.5)


def wrong() -> np.ndarray:
    # Dos notas graves y redondas que bajan: avisa sin regañar.
    out = np.zeros(int(SR * 0.9))
    place(out, mallet(NOTE["E4"], 0.4, 0.11, 0.12), 0.0)
    place(out, mallet(NOTE["B3"], 0.5, 0.15, 0.1), 0.13, 0.95)
    return finish(room(lowpass(out, 2200.0), 0.1), -10.0)


def life() -> np.ndarray:
    out = np.zeros(int(SR * 1.0))
    place(out, thud(0.18, 130.0, 60.0), 0.0, 0.6)
    place(out, mallet(NOTE["A4"], 0.45, 0.14, 0.15), 0.03, 0.7)
    place(out, mallet(NOTE["E4"], 0.6, 0.2, 0.12), 0.2, 0.7)
    return finish(room(out, 0.14), -9.0)


def win() -> np.ndarray:
    # Remate corto de fiesta: cuerda pulsada en la pentatónica y campanitas al final.
    out = np.zeros(int(SR * 3.4))
    for name, at in [("G4", 0.0), ("D5", 0.02), ("G5", 0.04), ("B5", 0.06)]:
        place(out, pluck(NOTE[name], 1.2), at, 0.5)
    melody = [("D5", 0.24), ("E5", 0.4), ("G5", 0.56), ("B5", 0.8), ("A5", 0.96), ("B5", 1.12), ("D6", 1.34)]
    for name, at in melody:
        place(out, pluck(NOTE[name], 1.0), at, 0.8)
        place(out, mallet(NOTE[name], 0.5, 0.16, 0.2), at, 0.3)
    for name, at in [("G4", 1.6), ("B4", 1.62), ("D5", 1.64), ("G5", 1.66), ("G6", 1.7)]:
        place(out, pluck(NOTE[name], 1.6), at, 0.55)
    for i, name in enumerate(["G6", "B6", "D6", "G6"]):
        place(out, bell(NOTE[name], 0.9, 0.3), 1.74 + i * 0.1, 0.2)
    return finish(room(out, 0.22, 0.7), -7.0)


def lose() -> np.ndarray:
    out = np.zeros(int(SR * 2.4))
    for i, name in enumerate(["E5", "D5", "B4", "G4", "E4"]):
        place(out, mallet(NOTE[name], 1.0, 0.36, 0.15), i * 0.2, 0.9 - 0.08 * i)
    return finish(room(lowpass(out, 3000.0), 0.24, 0.7), -9.0)


# --- Acción --------------------------------------------------------------------------------------

def hop() -> np.ndarray:
    out = np.zeros(int(SR * 0.4))
    place(out, chirp(290.0, 640.0, 0.16, 0.09, 0.8), 0.0, 0.8)
    place(out, swish(0.2, 700.0, 2600.0, 0.6), 0.02, 0.25)
    return finish(room(out, 0.08, 0.2), -11.0)


def whoosh() -> np.ndarray:
    return finish(room(swish(0.5, 300.0, 3800.0, 0.5), 0.1, 0.3), -10.0)


def land() -> np.ndarray:
    return finish(thud(0.16, 120.0, 55.0), -11.0)


def impact() -> np.ndarray:
    out = np.zeros(int(SR * 0.5))
    place(out, thud(0.22, 170.0, 52.0), 0.0)
    x = t(0.12)
    place(out, highpass(lowpass(RNG.normal(0, 1, len(x)) * np.exp(-x / 0.02), 3200.0), 500.0), 0.0, 0.35)
    place(out, mallet(NOTE["E3"], 0.3, 0.09, 0.1), 0.0, 0.5)
    return finish(room(out, 0.12), -8.0)


def splash() -> np.ndarray:
    out = np.zeros(int(SR * 0.9))
    x = t(0.5)
    spray = highpass(lowpass(RNG.normal(0, 1, len(x)), 5200.0 - 3600.0 * (x / 0.5)), 700.0) * np.exp(-x / 0.14)
    place(out, spray, 0.0, 0.5)
    place(out, thud(0.14, 190.0, 80.0), 0.0, 0.5)
    for _ in range(7):
        f = RNG.uniform(520.0, 1500.0)
        place(out, chirp(f, f * RNG.uniform(1.4, 1.9), RNG.uniform(0.035, 0.07), 0.03, 0.8), RNG.uniform(0.04, 0.5), RNG.uniform(0.2, 0.4))
    return finish(room(out, 0.12), -9.0)


def chomp() -> np.ndarray:
    out = np.zeros(int(SR * 0.4))
    place(out, chirp(330.0, 120.0, 0.1, 0.045, 0.6), 0.0)
    x = t(0.06)
    place(out, lowpass(RNG.normal(0, 1, len(x)) * np.exp(-x / 0.012), 1800.0), 0.0, 0.4)
    place(out, chirp(260.0, 150.0, 0.07, 0.03), 0.1, 0.45)
    return finish(room(out, 0.08, 0.2), -9.0)


def plank() -> np.ndarray:
    x = t(0.2)
    wood = (np.sin(2 * np.pi * 610.0 * x) + 0.5 * np.sin(2 * np.pi * 925.0 * x)) * np.exp(-x / 0.03)
    wood += lowpass(RNG.normal(0, 1, len(x)) * np.exp(-x / 0.005), 2600.0) * 0.4
    out = np.zeros(int(SR * 0.4))
    place(out, wood, 0.0)
    place(out, thud(0.12, 140.0, 70.0), 0.0, 0.4)
    return finish(room(out, 0.12), -9.0)


def star() -> np.ndarray:
    return finish(room(arpeggio(["D6", "G6"], 0.06, bell, 0.6, 0.2, decay=0.2), 0.16), -11.0)


def sparkle() -> np.ndarray:
    out = np.zeros(int(SR * 2.0))
    names = ["G6", "B6", "D6", "E6", "A6", "G6", "B6", "D6", "E6", "G6"]
    for i, name in enumerate(names):
        place(out, bell(NOTE[name], 0.6, 0.2), i * 0.09 + RNG.uniform(0.0, 0.03), 0.5 * (1.0 - i / 14.0))
    return finish(room(out, 0.22, 0.6), -11.0)


# --- Ambientes (bucles de 16 s) ----------------------------------------------------------------

LOOP = 16.0


def _loop_noise(seconds: float, cross: float = 1.0) -> np.ndarray:
    """Ruido que empalma su final con su comienzo."""
    n, c = int(SR * seconds), int(SR * cross)
    noise = RNG.normal(0, 1, n + c)
    ramp = np.linspace(0.0, 1.0, c)
    noise[:c] = noise[:c] * ramp + noise[n:] * (1.0 - ramp)
    return noise[:n]


def _swell(period_count: int, sharp: float = 1.0, phase: float = 0.0) -> np.ndarray:
    x = t(LOOP)
    return (0.5 + 0.5 * np.sin(2 * np.pi * period_count * x / LOOP + phase)) ** sharp


def _bird(f0: float, f1: float, notes: int, gap: float) -> np.ndarray:
    out = np.zeros(int(SR * (notes * gap + 0.2)))
    for i in range(notes):
        place(out, chirp(f0 * RNG.uniform(0.97, 1.03), f1 * RNG.uniform(0.97, 1.03), 0.07, 0.05, 0.7), i * gap, 1.0 - 0.1 * i)
    return out


def _stereo(left: np.ndarray, right: np.ndarray, peak_db: float) -> np.ndarray:
    data = np.stack([left, right], axis=1)
    return data / np.max(np.abs(data)) * 10 ** (peak_db / 20.0)


def ambience_sierra() -> np.ndarray:
    # Viento suave de la puna y, muy de vez en cuando, un pajarito lejano.
    sides = []
    for phase in (0.0, 1.3):
        wind = lowpass(_loop_noise(LOOP), 380.0 + 240.0 * _swell(2, 1.0, phase)) * (0.45 + 0.55 * _swell(1, 1.5, phase))
        for at, f in [(2.6, 3200.0), (9.4, 2700.0), (13.1, 3600.0)]:
            place(wind, _bird(f, f * 1.25, 3, 0.1), at + phase * 0.02, 0.06)
        sides.append(wind)
    return _stereo(sides[0], sides[1], -14.0)


def ambience_selva() -> np.ndarray:
    # Río constante al fondo, insectos muy finos y pájaros que se contestan.
    sides = []
    for index, phase in enumerate((0.0, 2.1)):
        # El río va grave y lejano (sin siseo) y respira despacio.
        river = highpass(lowpass(lowpass(_loop_noise(LOOP), 800.0), 1100.0), 220.0) * (0.55 + 0.45 * _swell(1, 1.0, phase)) * 0.6
        x = t(LOOP)
        insects = highpass(lowpass(_loop_noise(LOOP), 6400.0), 5200.0) * (0.5 + 0.5 * np.sin(2 * np.pi * 17.0 * x)) * _swell(2, 3.0, phase) * 0.035
        bed = river + insects
        calls = [(1.2, 2400.0, 1.5, 4, 0.12), (4.8, 3400.0, 0.8, 2, 0.16), (7.3, 1900.0, 1.3, 3, 0.2), (10.6, 3000.0, 1.4, 5, 0.09),
                 (13.4, 2200.0, 0.75, 2, 0.22)]
        for k, (at, f, bend, notes, gap) in enumerate(calls):
            if k % 2 == index or k == 0:
                place(bed, _bird(f, f * bend, notes, gap), at, 0.07)
        sides.append(bed)
    return _stereo(sides[0], sides[1], -14.0)


def ambience_costa() -> np.ndarray:
    # Olas que llegan y se retiran, con la espuma más brillante en la rompiente.
    sides = []
    for phase in (0.0, 0.35):
        swell = _swell(2, 2.2, phase)
        wave_body = lowpass(_loop_noise(LOOP), 350.0 + 1900.0 * swell) * (0.25 + 0.75 * swell)
        foam = highpass(lowpass(_loop_noise(LOOP), 6000.0), 2500.0) * _swell(2, 6.0, phase - 0.5) * 0.25
        bed = wave_body + foam
        for at, f in [(5.5, 2100.0), (12.2, 1900.0)]:
            place(bed, chirp(f, f * 0.72, 0.35, 0.2, 1.2), at, 0.035)
        sides.append(bed)
    return _stereo(sides[0], sides[1], -14.0)


SOUNDS = {name: globals()[name] for name in ["tap", "check", "card", "hint", "pop", "title", "correct", "streak", "wrong", "life",
                                               "win", "lose", "hop", "whoosh", "land", "impact", "splash", "chomp", "plank", "star",
                                               "sparkle"]}
BEDS = {"sierra": ambience_sierra, "selva": ambience_selva, "costa": ambience_costa}


if __name__ == "__main__":
    wanted = sys.argv[1:]
    for name, make in SOUNDS.items():
        if not wanted or name in wanted:
            save(SFX, f"sfx_{name}", make())
            print("sfx", name)
    for name, make in BEDS.items():
        if not wanted or name in wanted or "ambience" in wanted:
            save(AMBIENCE, f"amb_{name}", make(), True)
            print("ambiente", name)
