#!/usr/bin/env python3
"""Generates the KSPSTADK launcher, adaptive, notification and store icons.

Green → teal → blue → indigo gradient with a bold white "K" (Poppins Bold,
bundled in assets/fonts). Run: pip install pillow && python3 tool/make_icons.py
"""

import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
FONT = os.path.join(ROOT, "assets", "fonts", "Poppins-Bold.ttf")
STOPS = [(0.0, (15, 157, 88)), (0.35, (14, 165, 164)), (0.75, (37, 99, 235)), (1.0, (79, 70, 229))]
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size):
    """Diagonal multi-stop gradient."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            for (t0, c0), (t1, c1) in zip(STOPS, STOPS[1:]):
                if t <= t1:
                    px[x, y] = lerp(c0, c1, (t - t0) / (t1 - t0))
                    break
    return img


def draw_k(img, box_frac, color=(255, 255, 255, 255)):
    size = img.size[0]
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, int(size * box_frac))
    bbox = d.textbbox((0, 0), "K", font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((size - w) / 2 - bbox[0], (size - h) / 2 - bbox[1]), "K", font=font, fill=color)
    # Small accent dot (the site's rainbow), bottom-right of the letter.
    r = size * 0.045
    cx, cy = size / 2 + w / 2 + r * 0.6, size / 2 + h / 2 - r
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(251, 191, 36, 255))


def rounded(img, radius_frac):
    size = img.size[0]
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * radius_frac), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img.convert("RGBA"), (0, 0), mask)
    return out


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def main():
    big = gradient(1024)
    # Legacy launcher (48dp) + round.
    for name, k in DENSITIES.items():
        s = int(48 * k)
        icon = rounded(big.resize((s, s), Image.LANCZOS), 0.24)
        draw_k(icon, 0.62)
        save(icon, os.path.join(RES, "mipmap-%s" % name, "ic_launcher.png"))
        circle = big.resize((s, s), Image.LANCZOS).convert("RGBA")
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, s - 1, s - 1], fill=255)
        rc = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        rc.paste(circle, (0, 0), mask)
        draw_k(rc, 0.58)
        save(rc, os.path.join(RES, "mipmap-%s" % name, "ic_launcher_round.png"))
        # Adaptive foreground (108dp, letter inside the 66dp safe zone).
        fs = int(108 * k)
        fg = Image.new("RGBA", (fs, fs), (0, 0, 0, 0))
        draw_k(fg, 0.40)
        save(fg, os.path.join(RES, "mipmap-%s" % name, "ic_launcher_foreground.png"))
        # Adaptive background bitmap.
        save(big.resize((fs, fs), Image.LANCZOS), os.path.join(RES, "mipmap-%s" % name, "ic_launcher_background.png"))
        # Notification icon: white glyph on transparent (24dp).
        ns = int(24 * k)
        ni = Image.new("RGBA", (ns, ns), (0, 0, 0, 0))
        draw_k(ni, 0.9)
        save(ni, os.path.join(RES, "drawable-%s" % name, "ic_stat_notify.png"))

    adaptive = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""
    for n in ("ic_launcher.xml", "ic_launcher_round.xml"):
        p = os.path.join(RES, "mipmap-anydpi-v26", n)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w") as f:
            f.write(adaptive)

    store = rounded(big.resize((512, 512), Image.LANCZOS), 0.0)
    draw_k(store, 0.6)
    save(store, os.path.join(ROOT, "store", "icon-512.png"))
    # Feature graphic 1024x500.
    fg = gradient(1024).resize((1024, 500)).convert("RGBA")
    d = ImageDraw.Draw(fg)
    title = ImageFont.truetype(FONT, 110)
    sub = ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "NotoSansKannada-SemiBold.ttf"), 44)
    d.text((80, 140), "KSPSTADK", font=title, fill="white")
    kn = "ಶಿಕ್ಷಕರ ಅಧ್ಯಯನ ಸಾಮಗ್ರಿ"
    d.text((84, 290), kn, font=sub, fill=(235, 245, 255))
    # Noto Sans Kannada has no Latin glyphs: draw the Latin part in Poppins.
    x = 84 + d.textlength(kn, font=sub) + 16
    d.text((x, 292), "· LBA · PDF", font=ImageFont.truetype(FONT, 44), fill=(235, 245, 255))
    save(fg, os.path.join(ROOT, "store", "feature-graphic-1024x500.png"))
    print("icons written")


if __name__ == "__main__":
    main()
