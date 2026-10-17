"""Synthesises Waqt's built-in alert sounds (no recordings, no licences).

    python3 tool/sounds/gen_sounds.py   # needs numpy and ffmpeg

Writes android/app/src/main/res/raw/waqt_chime.ogg and waqt_bell.ogg.
"""
import os, subprocess, tempfile, wave
import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'android/app/src/main/res/raw')


def bell(freq, dur, partials, decay):
    t = np.arange(int(SR * dur)) / SR
    tone = np.zeros_like(t)
    for ratio, amp, d in partials:
        tone += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t * decay * d)
    attack = np.minimum(1, t / 0.004)
    return tone * attack


def place(track, sound, at):
    i = int(at * SR)
    end = min(len(track), i + len(sound))
    track[i:end] += sound[: end - i]


def write(name, track):
    track = track / np.max(np.abs(track)) * 0.8
    fade = int(0.5 * SR)
    track[-fade:] *= np.linspace(1, 0, fade)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        path = f.name
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((track * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', path,
                    '-c:a', 'libvorbis', '-q:a', '4',
                    os.path.join(OUT, name + '.ogg')], check=True)
    os.remove(path)


# Chime: a gentle rising and falling phrase on soft glass-like bells.
glass = [(1, 1.0, 1.0), (2.0, 0.35, 1.6), (3.0, 0.12, 2.4), (4.2, 0.05, 3.5)]
notes = [523.25, 659.25, 783.99, 1046.5, 783.99, 659.25]  # C E G C' G E
chime = np.zeros(int(SR * 12))
for rep in range(2):
    for i, f in enumerate(notes):
        place(chime, bell(f, 4, glass, 1.1), rep * 5.5 + i * 0.55)
write('waqt_chime', chime)

# Bell: three slow strikes of a deep temple bell (inharmonic partials).
deep = [(0.5, 0.6, 0.5), (1, 1.0, 0.8), (1.19, 0.5, 1.0), (1.56, 0.4, 1.3),
        (2.0, 0.3, 1.6), (2.51, 0.2, 2.0), (3.01, 0.1, 2.6)]
bells = np.zeros(int(SR * 14))
for i in range(3):
    place(bells, bell(220, 8, deep, 0.6), i * 3.5)
write('waqt_bell', bells)
print('ok')
