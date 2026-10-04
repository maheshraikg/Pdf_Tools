"""Draws the launcher icon (sunrise over the horizon, Tulunadu red/yellow)
into android/app/src/main/res/mipmap-*/ic_launcher.png.  pip install pillow"""
import math
from PIL import Image, ImageDraw

RED, GOLD, CREAM = (179, 38, 30), (242, 201, 76), (255, 248, 230)
SIZES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}


def draw(n):
    s = 4 * n  # supersample
    im = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * 0.22, fill=RED)
    cx, hy, r = s / 2, s * 0.64, s * 0.24
    for i in range(12):  # rays
        a = math.pi + i * math.pi / 11
        x1, y1 = cx + math.cos(a) * r * 1.25, hy + math.sin(a) * r * 1.25
        x2, y2 = cx + math.cos(a) * r * 1.6, hy + math.sin(a) * r * 1.6
        d.line([x1, y1, x2, y2], fill=GOLD, width=int(s * 0.035))
    d.pieslice([cx - r, hy - r, cx + r, hy + r], 180, 360, fill=GOLD)
    d.rectangle([s * 0.14, hy, s * 0.86, hy + s * 0.04], fill=CREAM)
    for k, w in ((0.1, 0.5), (0.18, 0.3)):  # water lines
        y = hy + s * k
        d.rectangle([cx - s * w / 2, y, cx + s * w / 2, y + s * 0.025],
                    fill=CREAM)
    return im.resize((n, n), Image.LANCZOS)


for name, n in SIZES.items():
    draw(n).save(f'android/app/src/main/res/mipmap-{name}/ic_launcher.png')
draw(512).save('docs/icon_512.png')
