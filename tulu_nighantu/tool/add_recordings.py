#!/usr/bin/env python3
"""Adds native-speaker recordings to the app.

Usage:  python3 tool/add_recordings.py <folder-with-audio-files>

Name each file after what is spoken, any of:
  * a dictionary word id:          w025.m4a       (ನೀರ್)
  * the Kannada-script text:       ನೀರ್.m4a, ಕ.m4a, ಐತಾರ.mp3
Supported: .m4a .mp3 .ogg .opus .wav (short clips, ideally < 100 KB).

Files are copied to assets/audio/ under safe ASCII names and listed in
assets/audio/index.json, which the app reads (Speaker.speak).
"""
import hashlib
import json
import pathlib
import shutil
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parent.parent
AUDIO = ROOT / 'assets' / 'audio'
EXTS = {'.m4a', '.mp3', '.ogg', '.opus', '.wav'}


def main(src: str) -> None:
    words = json.loads((ROOT / 'assets/data/words.json').read_text('utf-8'))
    by_id = {w['id']: w['tulu'] for w in words['words']}
    index_path = AUDIO / 'index.json'
    index = json.loads(index_path.read_text('utf-8'))
    files = index.setdefault('files', {})
    added = 0
    for f in sorted(pathlib.Path(src).iterdir()):
        if f.suffix.lower() not in EXTS:
            continue
        stem = unicodedata.normalize('NFC', f.stem.strip())
        text = by_id.get(stem, stem)
        if not any('ಀ' <= c <= '೿' for c in text):
            print(f'skip {f.name}: not a word id or Kannada text')
            continue
        name = 'r_' + hashlib.sha1(text.encode()).hexdigest()[:10] + f.suffix.lower()
        shutil.copyfile(f, AUDIO / name)
        files[text] = name
        added += 1
        print(f'{f.name} -> {text} ({name})')
    index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2) + '\n', 'utf-8')
    print(f'{added} recording(s) added.')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
