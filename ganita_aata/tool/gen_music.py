#!/usr/bin/env python3
"""Composes the two ORIGINAL background-music loops in assets/audio/music/.

menu.ogg – calm, 96 BPM; game.ogg – bright and bouncy, 120 BPM. Both are
seamless 8-bar loops (marimba melody, plucked bass, soft chords, shaker and
a gentle kick) in C major, chords C–Am–F–G. No samples are used, so there
are no licence questions. Replace the files with real recordings of the same
name to change the music (see README).

Requires numpy and ffmpeg (libopus). Usage: python3 tool/gen_music.py
"""
import os, subprocess, tempfile, wave
import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio', 'music')
NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def hz(name):
    """'C5' → frequency."""
    n, octave = name[:-1], int(name[-1])
    semis = NOTE[n[0]] + (1 if n.endswith('#') else 0) + (octave - 4) * 12 - 9
    return 440.0 * 2 ** (semis / 12)


def env(n, attack, decay):
    t = np.arange(n) / SR
    return np.minimum(1, t / attack) * np.exp(-t / decay)


def marimba(f, dur, vol=1.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    s = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 4 * f * t) * np.exp(-t / 0.05)
    return vol * s * env(n, 0.003, 0.32)


def bell(f, dur, vol=1.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    s = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * 2.01 * f * t) + 0.15 * np.sin(2 * np.pi * 3 * f * t)
    return vol * s * env(n, 0.004, 0.5)


def pluck_bass(f, dur, vol=1.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    ph = (f * t) % 1
    tri = 4 * np.abs(ph - 0.5) - 1
    return vol * (0.7 * tri + 0.3 * np.sin(2 * np.pi * f * t)) * env(n, 0.005, 0.25)


def kick(dur=0.25, vol=1.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = 110 * np.exp(-t / 0.05) + 45
    return vol * np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.001, 0.09)


def shaker(dur=0.08, vol=1.0, seed=0):
    n = int(SR * dur)
    x = np.random.default_rng(seed).uniform(-1, 1, n)
    x = np.diff(x, prepend=0)  # brighten
    return vol * x * env(n, 0.004, 0.025)


CHORDS = [['C4', 'E4', 'G4'], ['A3', 'C4', 'E4'], ['F3', 'A3', 'C4'], ['G3', 'B3', 'D4']]
BASS = ['C3', 'A2', 'F2', 'G2']

# Melodies: (beat offset in bar, note, length in beats); 8 bars.
MELODY_GAME = [
    [(0, 'E5', 1), (1, 'G5', 1), (2, 'A5', .5), (2.5, 'G5', .5), (3, 'E5', 1)],
    [(0, 'C5', 1), (1, 'E5', .5), (1.5, 'D5', .5), (2, 'C5', 1), (3, 'A4', 1)],
    [(0, 'A4', .5), (0.5, 'C5', .5), (1, 'F5', 1), (2, 'E5', .5), (2.5, 'D5', .5), (3, 'C5', 1)],
    [(0, 'D5', 1), (1, 'G5', 1), (2, 'B4', 1), (3, 'D5', 1)],
    [(0, 'G5', .5), (0.5, 'A5', .5), (1, 'G5', .5), (1.5, 'E5', .5), (2, 'C6', 1), (3, 'G5', 1)],
    [(0, 'E5', 1), (1, 'A5', .5), (1.5, 'G5', .5), (2, 'E5', 1), (3, 'C5', 1)],
    [(0, 'F5', .5), (0.5, 'E5', .5), (1, 'D5', .5), (1.5, 'C5', .5), (2, 'A4', 1), (3, 'C5', 1)],
    [(0, 'D5', .5), (0.5, 'E5', .5), (1, 'G5', 1), (2, 'D5', 1), (3, 'G4', 1)],
]
MELODY_MENU = [
    [(0, 'E5', 1.5), (1.5, 'D5', .5), (2, 'C5', 2)],
    [(0, 'C5', 1), (1, 'E5', 1), (2, 'A4', 2)],
    [(0, 'A4', 1), (1, 'C5', 1), (2, 'F5', 1.5), (3.5, 'E5', .5)],
    [(0, 'D5', 2), (2, 'B4', 1), (3, 'D5', 1)],
    [(0, 'G5', 1.5), (1.5, 'E5', .5), (2, 'C5', 2)],
    [(0, 'E5', 1), (1, 'A5', 1), (2, 'G5', 2)],
    [(0, 'F5', 1), (1, 'E5', 1), (2, 'C5', 1.5), (3.5, 'A4', .5)],
    [(0, 'D5', 1), (1, 'B4', 1), (2, 'G4', 2)],
]


def render(bpm, melody, busy):
    beat = 60 / bpm
    bars = len(melody)
    total = int(SR * beat * 4 * bars)
    tail = int(SR * 2)
    mix = np.zeros(total + tail)

    def add(sig, at_beat):
        i = int(at_beat * beat * SR)
        mix[i:i + len(sig)] += sig

    for b in range(bars):
        base = b * 4
        ch = CHORDS[b % 4]
        # Bass on 1 and 3 (and an octave pop on the "and" of 4 when busy).
        add(pluck_bass(hz(BASS[b % 4]), beat * 1.5, 0.55), base)
        add(pluck_bass(hz(BASS[b % 4]), beat * 1.5, 0.45), base + 2)
        if busy:
            add(pluck_bass(hz(BASS[b % 4]) * 2, beat * .5, 0.25), base + 3.5)
        # Soft chord plucks on the off-beats.
        for off in ([0.5, 1.5, 2.5, 3.5] if busy else [1, 3]):
            for k, n in enumerate(ch):
                add(marimba(hz(n), beat, 0.13), base + off + k * 0.015)
        # Melody (bells on top for sparkle).
        for at, n, ln in melody[b]:
            add(marimba(hz(n), beat * ln + 0.3, 0.42), base + at)
            add(bell(hz(n) * 2, beat * ln, 0.06 if busy else 0.09), base + at)
        # Percussion.
        add(kick(vol=0.6 if busy else 0.4), base)
        add(kick(vol=0.5 if busy else 0.3), base + 2)
        steps = 8 if busy else 4
        for s in range(steps):
            add(shaker(vol=(0.1 if s % 2 else 0.06) * (1 if busy else 0.7), seed=b * 8 + s), base + s * 4 / steps)

    # Seamless loop: fold the tail back onto the start.
    mix[:tail] += mix[total:total + tail]
    mix = mix[:total]
    mix /= np.max(np.abs(mix)) / 0.8
    return mix


def save(sig, name):
    os.makedirs(OUT, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix='.wav') as t:
        with wave.open(t.name, 'wb') as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
            w.writeframes((sig * 32767).astype(np.int16).tobytes())
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', t.name, '-c:a', 'libopus', '-b:a', '40k',
                        os.path.join(OUT, name)], check=True)


if __name__ == '__main__':
    save(render(96, MELODY_MENU, busy=False), 'menu.ogg')
    save(render(120, MELODY_GAME, busy=True), 'game.ogg')
