#!/usr/bin/env python3
"""Draws the placeholder launcher icon (+ − × ÷ on a mango-orange tile).

Writes android/app/src/main/res/mipmap-*/ic_launcher.png and docs/icon_512.png.
Replace those PNGs with real artwork when it is ready (same names and sizes).
Usage: python3 tool/gen_icon.py   (run from ganita_aata/; needs Pillow)
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), '..')
SIZES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
COLORS = [(255, 107, 107), (77, 150, 255), (107, 203, 119), (155, 93, 229)]


def draw(size):
    s = 4 * size  # supersample
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=(255, 122, 0))
    m = int(s * 0.12)
    d.rounded_rectangle([m, m, s - m, s - m], radius=int(s * 0.16), fill=(255, 255, 255))
    w = int(s * 0.075)  # stroke
    cells = [(0.32, 0.32), (0.68, 0.32), (0.32, 0.68), (0.68, 0.68)]
    r = s * 0.12
    for i, (cx, cy) in enumerate(cells):
        cx, cy, c = cx * s, cy * s, COLORS[i]
        if i == 0:  # +
            d.rectangle([cx - r, cy - w / 2, cx + r, cy + w / 2], fill=c)
            d.rectangle([cx - w / 2, cy - r, cx + w / 2, cy + r], fill=c)
        elif i == 1:  # −
            d.rectangle([cx - r, cy - w / 2, cx + r, cy + w / 2], fill=c)
        elif i == 2:  # ×
            k = r * 0.8
            d.line([cx - k, cy - k, cx + k, cy + k], fill=c, width=w)
            d.line([cx - k, cy + k, cx + k, cy - k], fill=c, width=w)
        else:  # ÷
            d.rectangle([cx - r, cy - w / 2, cx + r, cy + w / 2], fill=c)
            for dy in (-r * 0.75, r * 0.75):
                d.ellipse([cx - w * 0.7, cy + dy - w * 0.7, cx + w * 0.7, cy + dy + w * 0.7], fill=c)
    return img.resize((size, size), Image.LANCZOS)


def main():
    for name, px in SIZES.items():
        out = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', f'mipmap-{name}', 'ic_launcher.png')
        draw(px).save(out)
    os.makedirs(os.path.join(ROOT, 'docs'), exist_ok=True)
    draw(512).save(os.path.join(ROOT, 'docs', 'icon_512.png'))


if __name__ == '__main__':
    main()
