#!/usr/bin/env python3
"""Generates the PLACEHOLDER audio shipped in assets/audio/.

Voice clips are synthesised with espeak-ng (robotic, but correct numbers);
sound effects are simple synthesised tones. Replace any file with a real
recording of the same name (see README "Replacing audio files").

Requires: espeak-ng (with the 'kn' voice), ffmpeg (libopus), numpy.
Usage:  python3 tool/gen_audio.py [lang ...]   (run from ganita_aata/)
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
                    '-ar', '24000', '-c:a', 'libopus', '-b:a', '12k',
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


# How a table line is read in each language: (a, b, a×b) → text.
TABLE_LINE = {
    'en': lambda a, b, c: f'{a} times {b} is {c}',
    'kn': lambda a, b, c: f'{a} {KN_MULT[b]} {c}',
    'hi': lambda a, b, c: f'{a} गुणा {b} बराबर {c}',
    'mr': lambda a, b, c: f'{a} गुणिले {b} बरोबर {c}',
    'ta': lambda a, b, c: f'{a} பெருக்கல் {b} சமம் {c}',
    'te': lambda a, b, c: f'{a} ఇంటూ {b} సమానం {c}',
    'ml': lambda a, b, c: f'{a} ഗുണം {b} സമം {c}',
    'bn': lambda a, b, c: f'{a} গুণ {b} সমান {c}',
    'gu': lambda a, b, c: f'{a} ગુણ્યા {b} બરાબર {c}',
    'pa': lambda a, b, c: f'{a} ਗੁਣਾ {b} ਬਰਾਬਰ {c}',
    'or': lambda a, b, c: f'{a} ଗୁଣନ {b} ସମାନ {c}',
    'ur': lambda a, b, c: f'{a} ضرب {b} برابر {c}',
}


def voice(lang):
    """Numbers 0–100 and every table line (2–20 × 1–10) for one language."""
    for n in range(0, 101):
        speak(str(n), lang, f'{OUT}/{lang}/n_{n}.ogg')
    for a in range(2, 21):
        for b in range(1, 11):
            speak(TABLE_LINE[lang](a, b, a * b), lang, f'{OUT}/{lang}/tables/t{a}_{b}.ogg')


def synth_sfx():
    """The synthesised effects (wrong, pop, tap). correct/coin/badge/chest/win
    are Kenney Music Jingles (CC0) copied into assets/audio/sfx/."""
    s = f'{OUT}/sfx'
    tone(f'{s}/wrong.ogg', [(330, 260, 0.25)], vol=0.35)
    noise_pop(f'{s}/pop.ogg')
    tone(f'{s}/tap.ogg', [(660, 660, 0.04)], vol=0.25)


def main(langs=None):
    for lang in langs or TABLE_LINE:
        voice(lang)


if __name__ == '__main__':
    import sys
    args = sys.argv[1:]
    if '--sfx' in args:
        synth_sfx()
        args.remove('--sfx')
    # Optional: language codes to (re)generate, e.g. `gen_audio.py hi ta`.
    main(args or None)
