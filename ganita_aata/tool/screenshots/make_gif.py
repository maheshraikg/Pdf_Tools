#!/usr/bin/env python3
"""Assembles build/anim/f_*.png into docs/preview.gif (run from ganita_aata/)."""
import glob
from PIL import Image

frames = [Image.open(f).convert('RGB').resize((240, 516)) for f in sorted(glob.glob('build/anim/f_*.png'))]
pal = [f.quantize(colors=96, method=Image.Quantize.MEDIANCUT) for f in frames]
pal[0].save('docs/preview.gif', save_all=True, append_images=pal[1:], duration=80, loop=0, optimize=True)
print(len(frames), 'frames')
