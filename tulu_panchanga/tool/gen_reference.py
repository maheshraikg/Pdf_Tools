"""Writes test/fixtures/swisseph_reference.json: reference values from the
Swiss Ephemeris (pyswisseph, Moshier mode — no data files needed) used by
test/astro_test.dart to check the pure-Dart engine.

    pip install pyswisseph
    python tool/gen_reference.py
"""
import json
import random

import swisseph as swe

FL = swe.FLG_MOSEPH | swe.FLG_NONUT
swe.set_sid_mode(swe.SIDM_LAHIRI)
random.seed(42)

MANGALURU = (74.8560, 12.9141, 0.0)  # lon, lat, alt


def lon(jd, body, sid=False):
    f = FL | (swe.FLG_SIDEREAL if sid else 0)
    return swe.calc_ut(jd, body, f)[0][0]


positions = []
for _ in range(300):
    jd = random.uniform(swe.julday(1950, 1, 1, 0.0), swe.julday(2100, 1, 1, 0.0))
    positions.append({
        'jd': jd,
        'sunTrop': lon(jd, swe.SUN),
        'moonTrop': lon(jd, swe.MOON),
        'sunSid': lon(jd, swe.SUN, True),
        'moonSid': lon(jd, swe.MOON, True),
    })


def crossing(f, lo, hi):
    """Bisection for f increasing through 0 on [lo, hi] (f wraps at 360)."""
    def g(t):
        v = f(t) % 360
        return v - 360 if v > 180 else v
    for _ in range(60):
        mid = (lo + hi) / 2
        if g(mid) < 0:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def elong(jd):
    return lon(jd, swe.MOON) - lon(jd, swe.SUN)


# Tithi boundaries through 2026-2027 (every 12° of elongation).
tithis = []
t = swe.julday(2026, 1, 1, 0.0)
end = swe.julday(2028, 1, 1, 0.0)
while t < end:
    e = elong(t) % 360
    k = int(e // 12) + 1
    target = (k * 12) % 360
    step = 0.05
    t1 = t
    while True:
        t2 = t1 + step
        d1 = (elong(t1) - target) % 360
        d2 = (elong(t2) - target) % 360
        if d1 > 300 and d2 < 60:
            break
        t1 = t2
    jd = crossing(lambda x: elong(x) - target, t1, t1 + step)
    tithis.append({'jd': jd, 'tithi': k % 30})  # index of tithi starting
    t = jd + 1e-4

# Sankrantis (sidereal Sun crossing multiples of 30°), 2026-2027.
sankrantis = []
t = swe.julday(2026, 1, 1, 0.0)
while t < end:
    s = lon(t, swe.SUN, True)
    k = int(s // 30) + 1
    target = (k * 30) % 360
    t1 = t
    while not ((lon(t1, swe.SUN, True) - target) % 360 > 300 and
               (lon(t1 + 1, swe.SUN, True) - target) % 360 < 60):
        t1 += 1
    jd = crossing(lambda x: lon(x, swe.SUN, True) - target, t1, t1 + 1)
    sankrantis.append({'jd': jd, 'rashi': k % 12})
    t = jd + 1

# Sunrise/sunset in Mangaluru: upper limb with refraction, and disc centre
# without refraction.
risesets = []
for i in range(0, 730, 7):
    jd0 = swe.julday(2026, 1, 1, 0.0) + i - 5.5 / 24  # local midnight IST
    row = {'jd0': jd0}
    for key, flag in (('', 0),
                      ('Centre', swe.BIT_DISC_CENTER | swe.BIT_NO_REFRACTION)):
        r = swe.rise_trans(jd0, swe.SUN, swe.CALC_RISE | flag,
                           MANGALURU, 1013.25, 15.0, swe.FLG_MOSEPH)[1][0]
        s = swe.rise_trans(jd0, swe.SUN, swe.CALC_SET | flag,
                           MANGALURU, 1013.25, 15.0, swe.FLG_MOSEPH)[1][0]
        row['rise' + key] = r
        row['set' + key] = s
    m = swe.rise_trans(jd0, swe.MOON, swe.CALC_RISE, MANGALURU, 1013.25, 15.0,
                       swe.FLG_MOSEPH)[1][0]
    row['moonrise'] = m
    risesets.append(row)

json.dump({
    'positions': positions,
    'tithis': tithis,
    'sankrantis': sankrantis,
    'risesets': risesets,
}, open('test/fixtures/swisseph_reference.json', 'w'), indent=0)
print(len(positions), len(tithis), len(sankrantis), len(risesets))
