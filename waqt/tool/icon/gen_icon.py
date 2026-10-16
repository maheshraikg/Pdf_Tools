"""Builds the Azan Time launcher icon.

    pip install cairosvg pillow && python3 tool/icon/gen_icon.py

When tool/icon/source.png (the square artwork) exists, the coloured icon is
made from it: the artwork sits in the adaptive icon's safe zone and a
blurred, enlarged copy of it fills the edges, so any launcher mask
(circle, squircle, teardrop) shows no seam. Otherwise the vector design
below is used. The themed (monochrome) and status-bar icons always use the
vector silhouette, since Android allows them only one colour.

Writes the adaptive icon (background, foreground and Android 13 themed
monochrome layers as vector drawables), legacy PNGs for Android 7, and
docs/icon/ (SVG + 512 px Play Store icon). Coordinates are in the 108 dp
adaptive-icon canvas; everything visible sits in the central 66 dp circle.
"""
import os
import cairosvg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RES = os.path.join(ROOT, 'android/app/src/main/res')
DOCS = os.path.join(ROOT, 'docs/icon')

EMERALD_DARK, EMERALD, TEAL = '#03291F', '#0B5D46', '#138A6E'
GOLD_LIGHT, GOLD, GOLD_DARK = '#F7E3A3', '#E2B84B', '#B98A22'

# Onion dome on a drum, crescent finial, clock face cut into the dome.
DOME = ('M33,72 C33,61 37,55 43.5,50.5 C49,46.6 52.6,42.5 54,35 '
        'C55.4,42.5 59,46.6 64.5,50.5 C71,55 75,61 75,72 Z')
DRUM = 'M30.5,72 h47 a1.8,1.8 0 0 1 1.8,1.8 v3.4 a1.8,1.8 0 0 1 -1.8,1.8 h-47 a1.8,1.8 0 0 1 -1.8,-1.8 v-3.4 a1.8,1.8 0 0 1 1.8,-1.8 Z'
SPIRE = 'M53.1,27.6 h1.8 v8.4 h-1.8 Z'
# Crescent with its horns up (as on dome finials): the outer circle minus
# a smaller circle set higher, drawn as two arcs between their crossings.
def _crescent(cx=54.0, cy=23.4, r1=5.4, dy=-2.6, r2=4.7):
    import math
    # Crossing points of the two circles (centres on one vertical line).
    d = -dy
    a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    h = math.sqrt(r1 * r1 - a * a)
    y = cy - a
    left, right = (cx - h, y), (cx + h, y)
    return (f'M{left[0]:.3f},{left[1]:.3f} '
            f'A{r1},{r1} 0 1 0 {right[0]:.3f},{right[1]:.3f} '
            f'A{r2},{r2} 0 1 1 {left[0]:.3f},{left[1]:.3f} Z')


CRESCENT = _crescent()
FACE_C, FACE_R = (54, 61.5), 8.6
FACE = (f'M{FACE_C[0]},{FACE_C[1]-FACE_R} a{FACE_R},{FACE_R} 0 1 0 0.001,0 Z')
HANDS = ('M53.15,61.5 V55.2 a0.85,0.85 0 0 1 1.7,0 V61.5 Z '        # hour
         'M54,60.7 H59.6 a0.8,0.8 0 0 1 0,1.6 H54 Z')                # minute
HUB = 'M54,60.1 a1.4,1.4 0 1 0 0.001,0 Z'
TICKS = ' '.join(
    f'M{x - 0.6},{y - 0.6} h1.2 v1.2 h-1.2 Z'
    for x, y in [(54, 54.4), (61.1, 61.5), (54, 68.6), (46.9, 61.5)])

# Faint eight-pointed star behind the dome (background layer).
STAR = ('M54,13 L62.2,34.2 L83,25 L73.8,45.8 L95,54 L73.8,62.2 L83,83 '
        'L62.2,73.8 L54,95 L45.8,73.8 L25,83 L34.2,62.2 L13,54 L34.2,45.8 '
        'L25,25 L45.8,34.2 Z')


# The drawing spans y 13.2-79 and x 28.7-79.3; scale it into the 66 dp
# safe circle, centred.
SCALE, PIVOT_Y = 0.82, 48.0
SHIFT_Y = 54 - PIVOT_Y + 1


def svg(full=True, shape='square', view='9 9 90 90'):
    """Preview / PNG source. shape: square (Play), rounded or circle."""
    clip = {
        'square': '',
        'rounded': '<clipPath id="m"><rect x="9" y="9" width="90" height="90" rx="20"/></clipPath>',
        'circle': '<clipPath id="m"><circle cx="54" cy="54" r="45"/></clipPath>',
    }[shape]
    use_clip = ' clip-path="url(#m)"' if clip else ''
    tf = (f'translate(0 {SHIFT_Y}) translate(54 {PIVOT_Y}) scale({SCALE}) '
          f'translate(-54 -{PIVOT_Y})')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="{EMERALD_DARK}"/><stop offset="0.55" stop-color="{EMERALD}"/><stop offset="1" stop-color="{TEAL}"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="{GOLD_LIGHT}"/><stop offset="0.6" stop-color="{GOLD}"/><stop offset="1" stop-color="{GOLD_DARK}"/></linearGradient>
<radialGradient id="glow" cx="0.5" cy="0.42" r="0.5">
<stop offset="0" stop-color="#FFFFFF" stop-opacity="0.16"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
{clip}
</defs>
<g{use_clip}>
<rect width="108" height="108" fill="url(#bg)"/>
<path d="{STAR}" fill="#FFFFFF" fill-opacity="0.05"/>
<rect width="108" height="108" fill="url(#glow)"/>
<g transform="{tf}">
<path d="{CRESCENT}" fill="url(#gold)" fill-rule="evenodd"/>
<path d="{SPIRE}" fill="url(#gold)"/>
<path d="{DOME}" fill="url(#gold)"/>
<path d="{DRUM}" fill="url(#gold)"/>
<path d="{FACE}" fill="{EMERALD_DARK}"/>
<path d="{TICKS}" fill="{GOLD_LIGHT}"/>
<path d="{HANDS}" fill="{GOLD_LIGHT}"/>
<path d="{HUB}" fill="{GOLD_LIGHT}"/>
</g>
</g></svg>'''


AAPT = 'xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt"'


def grad(attr, x1, y1, x2, y2, stops):
    items = ''.join(f'<item android:offset="{o}" android:color="{c}"/>' for o, c in stops)
    return (f'<aapt:attr name="{attr}"><gradient android:type="linear" '
            f'android:startX="{x1}" android:startY="{y1}" android:endX="{x2}" '
            f'android:endY="{y2}">{items}</gradient></aapt:attr>')


def vector(body, fit=False):
    if fit:
        body = (f'<group android:pivotX="54" android:pivotY="{PIVOT_Y}" '
                f'android:scaleX="{SCALE}" android:scaleY="{SCALE}" '
                f'android:translateY="{SHIFT_Y:.2f}">\n{body}\n</group>')
    return (f'<?xml version="1.0" encoding="utf-8"?>\n<!-- Generated by tool/icon/gen_icon.py -->\n'
            f'<vector {AAPT} android:width="108dp" android:height="108dp" '
            f'android:viewportWidth="108" android:viewportHeight="108">\n{body}\n</vector>\n')


def path(d, fill=None, gradient=None, alpha=None, evenodd=False):
    a = f' android:pathData="{d}"'
    if fill:
        a += f' android:fillColor="{fill}"'
    if alpha is not None:
        a += f' android:fillAlpha="{alpha}"'
    if evenodd:
        a += ' android:fillType="evenOdd"'
    if gradient:
        return f'<path{a}>{gradient}</path>'
    return f'<path{a}/>'


def gold():
    return grad('android:fillColor', 54, 18, 54, 80,
                [(0, GOLD_LIGHT), (0.6, GOLD), (1, GOLD_DARK)])


def write(rel, text):
    p = os.path.join(RES, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w').write(text)


def main():
    write('drawable/ic_launcher_background.xml', vector('\n'.join([
        path('M0,0h108v108h-108z', gradient=grad(
            'android:fillColor', 0, 0, 108, 108,
            [(0, EMERALD_DARK), (0.55, EMERALD), (1, TEAL)])),
        path(STAR, fill='#FFFFFF', alpha='0.05'),
    ])))
    write('drawable/ic_launcher_foreground.xml', vector('\n'.join([
        path(CRESCENT, gradient=gold(), evenodd=True),
        path(SPIRE, gradient=gold()),
        path(DOME, gradient=gold()),
        path(DRUM, gradient=gold()),
        path(FACE, fill=EMERALD_DARK),
        path(TICKS, fill=GOLD_LIGHT),
        path(HANDS, fill=GOLD_LIGHT),
        path(HUB, fill=GOLD_LIGHT),
    ]), fit=True))
    # Themed icon: one colour, the clock face cut out of the dome.
    write('drawable/ic_launcher_monochrome.xml', vector('\n'.join([
        path(CRESCENT, fill='#FFFFFFFF', evenodd=True),
        path(SPIRE, fill='#FFFFFFFF'),
        path(DOME + ' ' + FACE, fill='#FFFFFFFF', evenodd=True),
        path(DRUM, fill='#FFFFFFFF'),
        path(TICKS + ' ' + HANDS + ' ' + HUB, fill='#FFFFFFFF'),
    ]), fit=True))
    # Status-bar icon: the same silhouette, white, filling 24 dp.
    stat = (f'<?xml version="1.0" encoding="utf-8"?>\n<!-- Generated by tool/icon/gen_icon.py -->\n'
            f'<vector {AAPT} android:width="24dp" android:height="24dp" '
            f'android:viewportWidth="64" android:viewportHeight="64">\n'
            f'<group android:translateX="-22" android:translateY="-16.5">\n'
            + '\n'.join([
                path(CRESCENT, fill='#FFFFFFFF', evenodd=True),
                path(SPIRE, fill='#FFFFFFFF'),
                path(DOME + ' ' + FACE, fill='#FFFFFFFF', evenodd=True),
                path(DRUM, fill='#FFFFFFFF'),
                path(TICKS + ' ' + HANDS + ' ' + HUB, fill='#FFFFFFFF'),
            ]) + '\n</group>\n</vector>\n')
    write('drawable/ic_stat_waqt.xml', stat)
    adaptive = ('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@drawable/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
                '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
                '</adaptive-icon>\n')
    write('mipmap-anydpi-v26/ic_launcher.xml', adaptive)
    write('mipmap-anydpi-v26/ic_launcher_round.xml', adaptive)

    # Android 7.x launchers use the PNGs.
    for folder, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                         ('xxhdpi', 144), ('xxxhdpi', 192)]:
        d = os.path.join(RES, f'mipmap-{folder}')
        os.makedirs(d, exist_ok=True)
        cairosvg.svg2png(bytestring=svg(shape='rounded').encode(), write_to=f'{d}/ic_launcher.png',
                         output_width=size, output_height=size)
        cairosvg.svg2png(bytestring=svg(shape='circle').encode(), write_to=f'{d}/ic_launcher_round.png',
                         output_width=size, output_height=size)

    if os.path.exists(SOURCE):
        raster_icon()

    os.makedirs(DOCS, exist_ok=True)
    open(f'{DOCS}/icon.svg', 'w').write(svg())
    if os.path.exists(SOURCE):
        from PIL import Image
        Image.open(SOURCE).convert('RGB').resize((512, 512), Image.LANCZOS).save(
            f'{DOCS}/icon-512.png')
    else:
        cairosvg.svg2png(bytestring=svg().encode(), write_to=f'{DOCS}/icon-512.png',
                         output_width=512, output_height=512)
    print('ok')


SOURCE = os.path.join(ROOT, 'tool/icon/source.png')
DENSITIES = [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]
# Share of the 108 dp canvas the artwork takes (66 dp: the safe zone).
ART = 66 / 108


def _layers(px):
    """Background and foreground bitmaps of a px x px adaptive icon."""
    from PIL import Image, ImageDraw, ImageFilter
    src = Image.open(SOURCE).convert('RGB')
    src = src.resize((min(src.size),) * 2, Image.LANCZOS)
    # Background: a smooth blend of the artwork's corner colours, so the
    # edges continue its own background.
    w = src.size[0]
    k = max(4, w // 16)

    def avg(x, y):
        return src.crop((x, y, x + k, y + k)).resize((1, 1), Image.BOX).getpixel((0, 0))

    tl, tr = avg(0, 0), avg(w - k, 0)
    bl, br = avg(0, w - k), avg(w - k, w - k)
    corners = Image.new('RGB', (2, 2))
    for xy, c in [((0, 0), tl), ((1, 0), tr), ((0, 1), bl), ((1, 1), br)]:
        corners.putpixel(xy, c)
    bg = corners.resize((px, px), Image.BILINEAR).filter(
        ImageFilter.GaussianBlur(px * 0.02))
    a = round(px * ART)
    art = src.resize((a, a), Image.LANCZOS).convert('RGBA')
    # Feather the artwork's square edge into the background.
    feather = max(2, round(a * 0.04))
    m = Image.new('L', (a, a), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        (feather, feather, a - 1 - feather, a - 1 - feather),
        radius=feather * 2, fill=255)
    art.putalpha(m.filter(ImageFilter.GaussianBlur(feather / 2)))
    fg = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    off = (px - a) // 2
    fg.paste(art, (off, off), art)
    return bg, fg


def raster_icon():
    from PIL import Image, ImageDraw
    for folder, scale in DENSITIES:
        px = round(108 * scale)
        bg, fg = _layers(px)
        d = os.path.join(RES, f'mipmap-{folder}')
        os.makedirs(d, exist_ok=True)
        bg.save(f'{d}/ic_launcher_background.png')
        fg.save(f'{d}/ic_launcher_foreground.png')
        # Legacy icons (Android 7): the central 72 dp, masked.
        full = bg.convert('RGBA')
        full.alpha_composite(fg)
        c = round(px / 6)
        legacy = full.crop((c, c, px - c, px - c)).resize(
            (round(48 * scale), round(48 * scale)), Image.LANCZOS)
        for name, shape in [('ic_launcher', 'rounded'), ('ic_launcher_round', 'circle')]:
            m = Image.new('L', legacy.size, 0)
            dr = ImageDraw.Draw(m)
            w = legacy.size[0] - 1
            if shape == 'circle':
                dr.ellipse((0, 0, w, w), fill=255)
            else:
                dr.rounded_rectangle((0, 0, w, w), radius=round(w * 0.22), fill=255)
            out = legacy.copy()
            out.putalpha(m)
            out.save(f'{d}/{name}.png')
    for f in ['ic_launcher_background.xml', 'ic_launcher_foreground.xml']:
        p = os.path.join(RES, 'drawable', f)
        if os.path.exists(p):
            os.remove(p)
    adaptive = ('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
                '</adaptive-icon>\n')
    for n in ['ic_launcher.xml', 'ic_launcher_round.xml']:
        open(os.path.join(RES, 'mipmap-anydpi-v26', n), 'w').write(adaptive)


if __name__ == '__main__':
    main()
