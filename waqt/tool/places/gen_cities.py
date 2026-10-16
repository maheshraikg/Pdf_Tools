"""Builds assets/cities.tsv.gz from GeoNames data (CC BY 4.0, geonames.org).

    pip download geonamescache --no-deps && unzip geonamescache-*.whl
    python3 tool/places/gen_cities.py <path to geonamescache/data>

Keeps every city of 15,000+ people, and towns of 1,000+ in South India
and the Gulf. Lines (tab separated):
    #C  country code  country name
    #A  CC.admin1     region name (India states only)
    name  other names (;)  Malayalam name  CC  admin1  lat  lon  tz  population
"""
import gzip, json, os, re, sys

data = sys.argv[1]
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
cities = json.load(open(os.path.join(data, 'cities1000.json'))).values()
countries = json.load(open(os.path.join(data, 'countries.json'))).values()

INDIA = {
    '01': 'Andaman and Nicobar', '02': 'Andhra Pradesh', '03': 'Assam',
    '05': 'Chandigarh', '07': 'Delhi', '09': 'Gujarat', '10': 'Haryana',
    '11': 'Himachal Pradesh', '12': 'Jammu and Kashmir', '13': 'Kerala',
    '14': 'Lakshadweep', '16': 'Maharashtra', '17': 'Manipur',
    '18': 'Meghalaya', '19': 'Karnataka', '20': 'Nagaland', '21': 'Odisha',
    '22': 'Puducherry', '23': 'Punjab', '24': 'Rajasthan', '25': 'Tamil Nadu',
    '26': 'Tripura', '28': 'West Bengal', '29': 'Sikkim',
    '30': 'Arunachal Pradesh', '31': 'Mizoram', '33': 'Goa', '34': 'Bihar',
    '35': 'Madhya Pradesh', '36': 'Uttar Pradesh', '37': 'Chhattisgarh',
    '38': 'Jharkhand', '39': 'Uttarakhand', '40': 'Telangana', '41': 'Ladakh',
    '52': 'Dadra and Nagar Haveli and Daman and Diu',
}
SOUTH_INDIA = {'13', '14', '19', '22', '25'}
GULF = {'SA', 'AE', 'OM', 'QA', 'KW', 'BH'}
ML = re.compile('[ഀ-ൿ]')
LATIN = re.compile(r"^[A-Z][a-z]+(?:[ -][A-Za-z][a-z]+)*$")


def keep(c):
    if c['population'] >= 15000:
        return True
    if c['countrycode'] == 'IN' and c['admin1code'] in SOUTH_INDIA:
        return True
    return c['countrycode'] in GULF and c['population'] >= 1000


rows = []
for c in cities:
    if not keep(c) or not c['timezone']:
        continue
    alts = []
    if c['population'] >= 100000:
        for a in c['alternatenames']:
            if LATIN.match(a) and a != c['name'] and a not in alts:
                alts.append(a)
            if len(alts) == 6:
                break
    ml = next((a for a in c['alternatenames'] if ML.search(a) and ' ' not in a), '')
    rows.append((
        -c['population'], c['name'], ';'.join(alts), ml.replace('‌', ''),
        c['countrycode'], c['admin1code'] or '',
        '%.4f' % c['latitude'], '%.4f' % c['longitude'], c['timezone'],
        str(c['population']),
    ))
rows.sort()
used = {r[4] for r in rows}
lines = [f"#C\t{c['iso']}\t{c['name']}" for c in countries if c['iso'] in used]
lines += [f'#A\tIN.{k}\t{v}' for k, v in INDIA.items()]
lines += ['\t'.join(r[1:]) for r in rows]
out = os.path.join(root, 'assets', 'cities.tsv.gz')
with gzip.open(out, 'wt', encoding='utf-8', compresslevel=9) as f:
    f.write('\n'.join(lines) + '\n')
print(len(rows), 'places,', os.path.getsize(out) // 1024, 'KB')
