#!/usr/bin/env python3
"""Generates assets/data/strokes.json: auto-derived pen paths for each letter.

The Mallige font has no stroke data, so each glyph is rendered, thinned to a
one-pixel skeleton and traced into polylines. Strokes start at the left-most
free end (Tulu is written left to right) and follow the straightest path
through junctions. The result is a *guide* for animation, not a verified
stroke order.

Coordinates are normalised to the glyph's ink bounding box (0..1), so the
app can map them onto the glyph however it is laid out.

Usage: python3 tool/gen_strokes.py   (needs pillow, scikit-image, numpy)
"""
import json
import math
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from skimage.morphology import skeletonize

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / 'assets/fonts/mallige_v1.4.ttf'
OUT = ROOT / 'assets/data/strokes.json'
SIZE = 400

# Kannada → Tulu map, read from the Dart source so there is one truth.
dart = (ROOT / 'lib/lipi/tulu_lipi.dart').read_text()
MAP = {int(a, 16): int(b, 16)
       for a, b in re.findall(r'0x(0C[0-9A-F]{2}): 0x(11[0-9A-F]{3})', dart)}
LETTERS = re.findall(r"LipiLetter\(\s*'([^']+)'", dart)


def to_tulu(kn):
    return ''.join(chr(MAP.get(ord(c), ord(c))) for c in kn)


def render(text):
    img = Image.new('L', (SIZE, SIZE), 0)
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(str(FONT), int(SIZE * 0.55))
    bb = d.textbbox((0, 0), text, font=f)
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    d.text(((SIZE - w) / 2 - bb[0], (SIZE - h) / 2 - bb[1]), text, font=f,
           fill=255)
    return np.array(img) > 127


NB = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]


def neighbours(sk, p):
    y, x = p
    return [(y + dy, x + dx) for dy, dx in NB
            if 0 <= y + dy < sk.shape[0] and 0 <= x + dx < sk.shape[1]
            and sk[y + dy, x + dx]]


def edges_of(sk):
    """Splits the skeleton into edges between nodes (ends / junctions)."""
    pts = set(zip(*np.nonzero(sk)))
    deg = {p: len(neighbours(sk, p)) for p in pts}
    nodes = {p for p in pts if deg[p] != 2}
    seen = set()
    edges = []

    def walk(a, b):
        path = [a, b]
        prev, cur = a, b
        while cur not in nodes:
            nxt = [n for n in neighbours(sk, cur) if n != prev
                   and frozenset((cur, n)) not in seen]
            if not nxt:
                break
            seen.add(frozenset((cur, nxt[0])))
            prev, cur = cur, nxt[0]
            path.append(cur)
        return path

    for n in nodes:
        for m in neighbours(sk, n):
            key = frozenset((n, m))
            if key in seen:
                continue
            seen.add(key)
            edges.append(walk(n, m))
    # Pure loops (no nodes at all).
    rest = pts - {p for e in edges for p in e}
    while rest:
        start = min(rest, key=lambda p: (p[1], p[0]))
        nb = neighbours(sk, start)
        path = [start]
        prev, cur = start, nb[0] if nb else start
        while cur != start and cur in rest:
            path.append(cur)
            nxt = [n for n in neighbours(sk, cur) if n != prev and n in rest]
            if not nxt:
                break
            prev, cur = cur, nxt[0]
        path.append(start)
        rest -= set(path)
        edges.append(path)
    return edges, deg


def length(path):
    return sum(math.dist(path[i], path[i + 1]) for i in range(len(path) - 1))


def prune(edges, deg, min_len):
    """Removes short spurs that end in a free end."""
    out = []
    for e in edges:
        free = deg.get(e[0], 2) == 1 or deg.get(e[-1], 2) == 1
        both_free = deg.get(e[0], 2) == 1 and deg.get(e[-1], 2) == 1
        if free and not both_free and length(e) < min_len:
            continue
        out.append(e)
    return out


def direction(path, at_end, n=8):
    seg = path[-n:] if at_end else path[:n][::-1]
    (y0, x0), (y1, x1) = seg[0], seg[-1]
    return math.atan2(y1 - y0, x1 - x0)


def chain(edges):
    """Greedily joins edges into long strokes, left-most free end first."""
    remaining = [list(e) for e in edges]
    ends = {}
    for e in remaining:
        for p in (e[0], e[-1]):
            ends[p] = ends.get(p, 0) + 1
    strokes = []
    while remaining:
        # Prefer starting at a free end (used once), left-most then top-most.
        cands = []
        for i, e in enumerate(remaining):
            for rev in (False, True):
                s = e[-1] if rev else e[0]
                free = ends.get(s, 0) == 1 and s != (e[0] if rev else e[-1])
                cands.append((0 if free else 1, s[1], s[0], i, rev))
        _, _, _, i, rev = min(cands)
        cur = remaining.pop(i)
        if rev:
            cur.reverse()
        stroke = cur
        while True:
            tip = stroke[-1]
            heading = direction(stroke, True)
            best = None
            for j, e in enumerate(remaining):
                for rev in (False, True):
                    s = e[-1] if rev else e[0]
                    if math.dist(s, tip) > 4.5:
                        continue
                    cand = e[::-1] if rev else e
                    turn = abs((direction(cand, False) + math.pi - heading
                                + math.pi) % (2 * math.pi) - math.pi)
                    turn = abs(math.pi - turn)
                    if best is None or turn < best[0]:
                        best = (turn, j, cand)
            # A pen keeps going through junctions unless it must reverse.
            if best is None or best[0] > math.radians(150):
                break
            remaining.pop(best[1])
            stroke = stroke + best[2][1:]
        strokes.append(stroke)
    return strokes


def merge_short(strokes, min_len):
    """Joins short connector strokes onto a stroke they touch."""
    changed = True
    while changed:
        changed = False
        for i, a in enumerate(strokes):
            if length(a) >= min_len:
                continue
            for j, b in enumerate(strokes):
                if i == j:
                    continue
                if math.dist(b[-1], a[0]) <= 4.5:
                    strokes[j] = b + a[1:]
                elif math.dist(b[-1], a[-1]) <= 4.5:
                    strokes[j] = b + a[::-1][1:]
                elif math.dist(a[-1], b[0]) <= 4.5:
                    strokes[j] = a + b[1:]
                elif math.dist(a[0], b[0]) <= 4.5:
                    strokes[j] = a[::-1] + b[1:]
                else:
                    continue
                strokes.pop(i)
                changed = True
                break
            if changed:
                break
    return strokes


def rdp(pts, eps):
    if len(pts) < 3:
        return pts
    a, b = np.array(pts[0], float), np.array(pts[-1], float)
    ab = b - a
    n = np.linalg.norm(ab)
    dists = [abs(ab[0] * (p[1] - a[1]) - ab[1] * (p[0] - a[0])) / n if n
             else math.dist(p, pts[0]) for p in pts]
    i = int(np.argmax(dists))
    if dists[i] > eps:
        return rdp(pts[:i + 1], eps)[:-1] + rdp(pts[i:], eps)
    return [pts[0], pts[-1]]


def strokes_for(kn):
    ink = render(to_tulu(kn))
    ys, xs = np.nonzero(ink)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    sk = skeletonize(ink)
    edges, deg = edges_of(sk)
    edges = prune(edges, deg, min_len=0.07 * max(x1 - x0, y1 - y0))
    # Tiny edges inside junction clusters are bridged by the chaining step.
    edges = [e for e in edges if length(e) >= 4 or e[0] == e[-1]]
    chained = chain(edges)
    strokes = merge_short([s for s in chained if length(s) > 4],
                          0.15 * max(x1 - x0, y1 - y0))
    # Keep isolated dots (e.g. the centre of ಠ) as one-point strokes.
    for d in (s for s in chained if length(s) <= 4):
        if all(math.dist(d[0], p) > 12 for t in strokes for p in t):
            strokes.append([d[len(d) // 2]])
    # Order strokes: left to right by starting x (ties: top first).
    strokes.sort(key=lambda s: (min(p[1] for p in s) // 30, s[0][0]))
    w, h = max(x1 - x0, 1), max(y1 - y0, 1)
    out = []
    for s in strokes:
        pts = rdp([(p[1], p[0]) for p in s], 1.2)
        out.append([[round((x - x0) / w, 3), round((y - y0) / h, 3)]
                    for x, y in pts])
    return out


def main():
    data = {kn: strokes_for(kn) for kn in LETTERS}
    OUT.write_text(json.dumps(
        {'note': 'Auto-generated pen paths (skeleton of the Mallige glyph). '
                 'Not a verified stroke order.',
         'letters': data}, ensure_ascii=False, separators=(',', ':')))
    print(f'{len(data)} letters, '
          f'{sum(len(v) for v in data.values())} strokes -> {OUT}')


if __name__ == '__main__':
    main()
