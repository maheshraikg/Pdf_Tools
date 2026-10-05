// Replaces placeholder puzzle pictures with freely licensed photographs
// from Wikimedia Commons, with attribution. Run from vesha_puzzles/:
//
//   dart run tool/fetch_photos.dart            # fetch, crop, write credits
//   dart run tool/fetch_photos.dart --dry-run  # only show what it would use
//   dart run tool/fetch_photos.dart --only y01_raja_vesha,c04_mallige
//
// Needs network access to commons.wikimedia.org and upload.wikimedia.org.
// For every candidate in tool/photo_sources.json the licence is read from
// the Commons API; only CC0, public domain, CC BY and CC BY-SA are used.
// The photo is cropped to between 3:4 and 4:3, scaled to at most 2048 px,
// saved over the puzzle's image, and a "credit" block (author, licence,
// source page, changes) is written into the pack's pack.json.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const api = 'https://commons.wikimedia.org/w/api.php';
const ua =
    'VeshaPuzzlesAssetTool/1.0 (https://github.com/maheshraikg/Pdf_Tools)';
final http = HttpClient()..userAgent = ua;

Future<Map<String, dynamic>> getJson(Map<String, String> q) async {
  final uri = Uri.parse(api)
      .replace(queryParameters: {...q, 'format': 'json', 'formatversion': '2'});
  final req = await http.getUrl(uri);
  final res = await req.close();
  if (res.statusCode != 200) {
    throw HttpException('HTTP ${res.statusCode} for $uri');
  }
  return jsonDecode(await res.transform(utf8.decoder).join())
      as Map<String, dynamic>;
}

Future<Uint8List> getBytes(String url) async {
  final res = await (await http.getUrl(Uri.parse(url))).close();
  if (res.statusCode != 200) {
    throw HttpException('HTTP ${res.statusCode} for $url');
  }
  final b = BytesBuilder();
  await for (final c in res) {
    b.add(c);
  }
  return b.takeBytes();
}

String stripHtml(String s) => s
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#039;', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

final okLicence = RegExp(
  r'^(CC0|Public domain|PD|CC BY(-SA)? \d\.\d|CC BY(-SA)?$)',
  caseSensitive: false,
);

class Candidate {
  Candidate(
    this.title,
    this.page,
    this.url,
    this.width,
    this.height,
    this.licence,
    this.licenceUrl,
    this.author,
  );
  final String title, page, url, licence, licenceUrl, author;
  final int width, height;
  double get aspect => width / height;

  /// Larger and closer to landscape is better.
  double get score => width * height * (aspect >= 1.0 ? 1.0 : 0.6);
}

Future<List<Candidate>> describe(List<String> titles) async {
  if (titles.isEmpty) return [];
  final r = await getJson({
    'action': 'query',
    'titles': titles.join('|'),
    'prop': 'imageinfo',
    'iiprop': 'url|size|mime|extmetadata',
    'iiurlwidth': '2048',
  });
  final out = <Candidate>[];
  for (final p in (r['query']?['pages'] as List? ?? const []).cast<Map>()) {
    final info = (p['imageinfo'] as List?)?.cast<Map>().firstOrNull;
    if (info == null) {
      stdout.writeln('    - ${p['title']}: not found on Commons');
      continue;
    }
    final meta = (info['extmetadata'] as Map?) ?? const {};
    String m(String k) => stripHtml('${(meta[k] as Map?)?['value'] ?? ''}');
    final licence = m('LicenseShortName');
    final mime = '${info['mime']}';
    final w = (info['width'] as num).toInt(),
        h = (info['height'] as num).toInt();
    final reason = !okLicence.hasMatch(licence)
        ? 'licence "$licence" not allowed'
        : !(mime == 'image/jpeg' || mime == 'image/png')
        ? 'type $mime'
        : (w < 1200 && h < 1200)
        ? 'too small ($w×$h)'
        : null;
    if (reason != null) {
      stdout.writeln('    - ${p['title']}: skipped, $reason');
      continue;
    }
    var author = m('Artist');
    if (author.isEmpty) author = m('Credit');
    out.add(
      Candidate(
        '${p['title']}',
        '${info['descriptionurl']}',
        '${info['thumburl'] ?? info['url']}',
        w,
        h,
        licence,
        m('LicenseUrl'),
        author.isEmpty ? 'Unknown (see source page)' : author,
      ),
    );
  }
  return out;
}

Future<List<String>> categoryFiles(String cat) async {
  final r = await getJson({
    'action': 'query',
    'list': 'categorymembers',
    'cmtitle': cat,
    'cmtype': 'file',
    'cmlimit': '50',
  });
  return [
    for (final m
        in (r['query']?['categorymembers'] as List? ?? const []).cast<Map>())
      '${m['title']}',
  ];
}

Future<Candidate?> pick(List<String> sources, Set<String> used) async {
  for (final s in sources) {
    stdout.writeln('  trying $s');
    List<Candidate> c;
    try {
      if (s.startsWith('Category:')) {
        final files = (await categoryFiles(s))
            .where((f) => !used.contains(f))
            .toList();
        c = [];
        for (var i = 0; i < files.length; i += 20) {
          c.addAll(
            await describe(files.sublist(i, (i + 20).clamp(0, files.length))),
          );
        }
        c.sort((a, b) => b.score.compareTo(a.score));
      } else {
        c = (await describe([s]))
            .where((x) => !used.contains(x.title))
            .toList();
      }
    } catch (e) {
      stdout.writeln('    ! $e');
      continue;
    }
    if (c.isNotEmpty) return c.first;
  }
  return null;
}

/// Crops to an aspect between 3:4 and 4:3 (keeping the upper-middle part
/// of tall photos, where faces usually are) and limits size to 2048 px.
img.Image fit(img.Image src) {
  var im = src;
  final a = im.width / im.height;
  if (a > 4 / 3) {
    final w = (im.height * 4 / 3).round();
    im = img.copyCrop(
      im,
      x: (im.width - w) ~/ 2,
      y: 0,
      width: w,
      height: im.height,
    );
  } else if (a < 3 / 4) {
    final h = (im.width * 4 / 3).round();
    im = img.copyCrop(
      im,
      x: 0,
      y: ((im.height - h) * 0.3).round(),
      width: im.width,
      height: h,
    );
  }
  if (im.width > 2048 || im.height > 2048) {
    im = im.width >= im.height
        ? img.copyResize(
            im,
            width: 2048,
            interpolation: img.Interpolation.cubic,
          )
        : img.copyResize(
            im,
            height: 2048,
            interpolation: img.Interpolation.cubic,
          );
  }
  return im;
}

Future<void> main(List<String> args) async {
  final dry = args.contains('--dry-run');
  final onlyIdx = args.indexOf('--only');
  final only = onlyIdx >= 0 ? args[onlyIdx + 1].split(',').toSet() : null;
  final sources =
      (jsonDecode(File('tool/photo_sources.json').readAsStringSync()) as Map)
        ..remove('_comment');
  final packs =
      (jsonDecode(File('assets/packs/index.json').readAsStringSync())['packs']
              as List)
          .cast<String>();
  final used = <String>{};
  final missing = <String>[];

  for (final packId in packs) {
    final packFile = File('assets/packs/$packId/pack.json');
    final pack =
        jsonDecode(packFile.readAsStringSync()) as Map<String, dynamic>;
    for (final p in (pack['puzzles'] as List).cast<Map<String, dynamic>>()) {
      final id = p['id'] as String;
      if (only != null && !only.contains(id)) continue;
      // Photos kept by puzzles outside this run are not reused.
      for (final c in (pack['puzzles'] as List).cast<Map>()) {
        final src = (c['credit'] as Map?)?['title'];
        if (src != null && only != null && !only.contains(c['id'])) {
          used.add('$src');
        }
      }
      stdout.writeln('$id:');
      final c = await pick(
        ((sources[id] as List?) ?? const []).cast<String>(),
        used,
      );
      if (c == null) {
        stdout.writeln(
          '  ✗ no suitable freely licensed photo; keeping current image',
        );
        missing.add(id);
        continue;
      }
      used.add(c.title);
      stdout.writeln(
        '  ✓ ${c.title} (${c.width}×${c.height}, ${c.licence}, ${c.author})',
      );
      if (dry) continue;
      final decoded = img.decodeImage(await getBytes(c.url));
      if (decoded == null) {
        stdout.writeln('  ✗ could not decode image');
        missing.add(id);
        continue;
      }
      final out = fit(decoded);
      File('assets/packs/$packId/${p['image']}')
          .writeAsBytesSync(img.encodeJpg(out, quality: 88));
      p['credit'] = {
        'title': c.title,
        'author': c.author,
        'licence': c.licence,
        'licenceUrl': c.licenceUrl,
        'source': c.page,
        'changes': 'Cropped to ${out.width}×${out.height} and resized',
      };
      p.remove('placeholder');
    }
    final allReal = (pack['puzzles'] as List).cast<Map>().every(
      (p) => p['credit'] != null,
    );
    pack['placeholder'] = !allReal;
    if (allReal) {
      pack['credits'] = {
        'artist': 'Photographs from Wikimedia Commons (see each picture)',
        'licence': 'Per picture: CC BY / CC BY-SA / CC0 / public domain',
        'year': '',
        'url': 'https://commons.wikimedia.org',
      };
    }
    if (!dry) {
      packFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(pack)}\n',
      );
    }
  }
  http.close();
  stdout.writeln(
    missing.isEmpty
        ? '\nAll puzzles have photos.'
        : '\nStill placeholder: ${missing.join(', ')}',
  );
}
