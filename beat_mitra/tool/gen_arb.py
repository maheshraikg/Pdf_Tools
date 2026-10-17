"""Generates lib/core/l10n/app_{en,kn,hi}.arb from tool/strings.py."""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from strings import S, INT_PARAMS

out_dir = os.path.join(os.path.dirname(__file__), "..", "lib", "core", "l10n")
os.makedirs(out_dir, exist_ok=True)
for i, lang in enumerate(["en", "kn", "hi"]):
    arb = {"@@locale": lang}
    for key, texts in S.items():
        text = texts[i]
        arb[key] = text
        params = re.findall(r"\{(\w+)\}", texts[0])
        if lang == "en" and params:
            arb["@" + key] = {"placeholders": {p: {"type": "int" if p in INT_PARAMS else "String"} for p in dict.fromkeys(params)}}
        # Every translation must use the same placeholders.
        assert set(re.findall(r"\{(\w+)\}", text)) == set(params), (lang, key)
    with open(os.path.join(out_dir, f"app_{lang}.arb"), "w", encoding="utf-8") as f:
        json.dump(arb, f, ensure_ascii=False, indent=2)
        f.write("\n")
print(f"{len(S)} strings x 3 languages")
