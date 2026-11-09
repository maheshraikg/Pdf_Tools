#!/usr/bin/env python3
"""Generates the PLACEHOLDER audio shipped in assets/audio/.

Voice clips are synthesised with espeak-ng (robotic, but correct numbers);
sound effects are simple synthesised tones. Replace any file with a real
recording of the same name (see README "Replacing audio files").

Requires: espeak-ng (with the 'kn' voice), ffmpeg (libopus), numpy.
Usage:  python3 tool/gen_audio.py            (run from ganita_aata/)
"""
import os, subprocess, tempfile, wave
import numpy as np

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')

# Multiplier forms used when reciting tables in Kannada
# ("ಎರಡು ಒಂದ್ಲ ಎರಡು, ಎರಡು ಎರಡ್ಲ ನಾಲ್ಕು, ...").
KN_MULT = {1: 'ಒಂದ್ಲ', 2: 'ಎರಡ್ಲ', 3: 'ಮೂರ್ಲ', 4: 'ನಾಲ್ಕ್ಲ', 5: 'ಐದ್ಲ',
           6: 'ಆರ್ಲ', 7: 'ಏಳ್ಲ', 8: 'ಎಂಟ್ಲ', 9: 'ಒಂಬತ್ಲ', 10: 'ಹತ್ತ್ಲ'}


def encode(wav_path, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', wav_path, '-ac', '1',
                    '-ar', '24000', '-c:a', 'libopus', '-b:a', '16k',
                    '-application', 'voip', out_path], check=True)


def speak(text, voice, out_path, speed=140):
    with tempfile.NamedTemporaryFile(suffix='.wav') as t:
        subprocess.run(['espeak-ng', '-v', voice, '-s', str(speed), '-w',
                        t.name, text], check=True)
        encode(t.name, out_path)


def tone(out_path, notes, sr=24000, vol=0.5):
    """notes: list of (freq_start, freq_end, seconds)."""
    parts = []
    for f0, f1, dur in notes:
        n = int(sr * dur)
        f = np.linspace(f0, f1, n)
        ph = 2 * np.pi * np.cumsum(f) / sr
        env = np.minimum(1, np.linspace(0, 30, n)) * np.exp(-np.linspace(0, 4, n))
        parts.append(np.sin(ph) * env)
    sig = (np.concatenate(parts) * vol * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix='.wav') as t:
        with wave.open(t.name, 'wb') as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
            w.writeframes(sig.tobytes())
        encode(t.name, out_path)


def noise_pop(out_path, sr=24000):
    n = int(sr * 0.12)
    sig = np.random.default_rng(1).uniform(-1, 1, n) * np.exp(-np.linspace(0, 9, n))
    sig = (sig * 0.6 * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix='.wav') as t:
        with wave.open(t.name, 'wb') as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
            w.writeframes(sig.tobytes())
        encode(t.name, out_path)


def main():
    for n in range(0, 101):
        speak(str(n), 'en', f'{OUT}/en/n_{n}.ogg')
        speak(str(n), 'kn', f'{OUT}/kn/n_{n}.ogg')
    for a in range(2, 21):
        for b in range(1, 11):
            speak(f'{a} times {b} is {a * b}', 'en', f'{OUT}/en/tables/t{a}_{b}.ogg')
            speak(f'{a} {KN_MULT[b]} {a * b}', 'kn', f'{OUT}/kn/tables/t{a}_{b}.ogg')
    s = f'{OUT}/sfx'
    tone(f'{s}/correct.ogg', [(880, 880, 0.09), (1320, 1320, 0.18)])
    tone(f'{s}/wrong.ogg', [(330, 260, 0.25)], vol=0.35)
    noise_pop(f'{s}/pop.ogg')
    tone(f'{s}/coin.ogg', [(988, 988, 0.07), (1319, 1319, 0.2)])
    tone(f'{s}/badge.ogg', [(523, 523, 0.12), (659, 659, 0.12), (784, 784, 0.12), (1047, 1047, 0.35)])
    tone(f'{s}/chest.ogg', [(392, 784, 0.35), (1047, 1047, 0.25)])
    tone(f'{s}/tap.ogg', [(660, 660, 0.04)], vol=0.25)


if __name__ == '__main__':
    main()
