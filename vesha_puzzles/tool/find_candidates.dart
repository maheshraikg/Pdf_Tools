// Searches Wikimedia Commons and Openverse for freely licensed photos for
// each puzzle (tool/photo_search.json) and writes, for review:
//   docs/photo_candidates/<puzzle>.jpg   contact sheet, numbered thumbnails
//   docs/photo_candidates/candidates.json  number → source, licence, author
// Only CC0, public domain, CC BY and CC BY-SA are listed. Run in CI by
// .github/workflows/vesha-photos.yml (needs open network access).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const ua =
    'VeshaPuzzlesAssetTool/1.0 (https://github.com/maheshraikg/Pdf_Tools)';
final http = HttpClient()..userAgent = ua;
final okLicence = RegExp(
  r'^(cc0|pdm|public domain|by|by-sa|cc by(-sa)?( \d\.\d)?)$',
  caseSensitive: false,
);

Future<Object?> getJson(Uri uri) async {
  final res = await (await http.getUrl(uri)).close();
  final body = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode} $uri');
  return jsonDecode(body);
}

Future<Uint8List> getBytes(String url) async {
  final res = await (await http.getUrl(Uri.parse(url))).close();
  if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode} $url');
  final b = BytesBuilder();
  await for (final c in res) {
    b.add(c);
  }
  return b.takeBytes();
}

String strip(String s) =>
    s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

class Cand {
  Cand(
    this.source,
    this.id,
    this.thumb,
    this.width,
    this.height,
    this.licence,
    this.author,
    this.page,
    this.title,
  );
  final String source, id, thumb, licence, author, page, title;
  final int width, height;
  Map<String, Object> toJson() => {
    'source': source,
    'id': id,
    'width': width,
    'height': height,
    'licence': licence,
    'author': author,
    'page': page,
    'title': title,
  };
}

Future<List<Cand>> commons(String q) async {
  final r = await getJson(
    Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'generator': 'search',
      'gsrsearch': '$q filetype:bitmap',
      'gsrnamespace': '6',
      'gsrlimit': '15',
      'prop': 'imageinfo',
      'iiprop': 'url|size|mime|extmetadata',
      'iiurlwidth': '480',
    }),
  ) as Map;
  final out = <Cand>[];
  for (final p
      in ((r['query'] as Map?)?['pages'] as List? ?? const []).cast<Map>()) {
    final info = (p['imageinfo'] as List?)?.cast<Map>().firstOrNull;
    if (info == null) continue;
    final meta = (info['extmetadata'] as Map?) ?? const {};
    String m(String k) => strip('${(meta[k] as Map?)?['value'] ?? ''}');
    final lic = m('LicenseShortName');
    final w = (info['width'] as num).toInt(),
        h = (info['height'] as num).toInt();
    if (!okLicence.hasMatch(lic.replaceAll(RegExp(r' \d\.\d$'), '')) &&
        !lic.toLowerCase().startsWith('cc by')) {
      continue;
    }
    if (w < 1400 && h < 1400) continue;
    out.add(
      Cand(
        'commons',
        '${p['title']}',
        '${info['thumburl']}',
        w,
        h,
        lic,
        m('Artist').isEmpty ? m('Credit') : m('Artist'),
        '${info['descriptionurl']}',
        '${p['title']}',
      ),
    );
  }
  return out;
}

Future<List<Cand>> openverse(String q) async {
  final r = await getJson(
    Uri.https('api.openverse.org', '/v1/images/', {
      'q': q,
      'license_type': 'commercial,modification',
      'size': 'large',
      'page_size': '20',
    }),
  ) as Map;
  final out = <Cand>[];
  for (final x in (r['results'] as List? ?? const []).cast<Map>()) {
    final lic = '${x['license']}'.toLowerCase();
    if (!['cc0', 'pdm', 'by', 'by-sa'].contains(lic)) continue;
    final w = (x['width'] as num?)?.toInt() ?? 0,
        h = (x['height'] as num?)?.toInt() ?? 0;
    if (w < 1400 && h < 1400) continue;
    final licName = switch (lic) {
      'cc0' => 'CC0 1.0',
      'pdm' => 'Public domain',
      _ => 'CC ${lic.toUpperCase()} ${x['license_version'] ?? ''}'.trim(),
    };
    out.add(
      Cand(
        'openverse',
        '${x['id']}',
        '${x['thumbnail'] ?? x['url']}',
        w,
        h,
        licName,
        '${x['creator'] ?? 'Unknown'}',
        '${x['foreign_landing_url'] ?? ''}',
        '${x['title'] ?? ''}',
      ),
    );
  }
  return out;
}

Future<void> main() async {
  final searches = (jsonDecode(
    File('tool/photo_search.json').readAsStringSync(),
  ) as Map).cast<String, dynamic>();
  final dir = Directory('docs/photo_candidates')..createSync(recursive: true);
  final all = <String, List<Map<String, Object>>>{};
  for (final e in searches.entries) {
    final seen = <String>{};
    final cands = <Cand>[];
    for (final q in (e.value as List).cast<String>()) {
      for (final f in [commons, openverse]) {
        try {
          for (final c in await f(q)) {
            if (seen.add('${c.source}:${c.id}')) cands.add(c);
          }
        } catch (err) {
          stdout.writeln('  ${e.key} "$q": $err');
        }
      }
    }
    final picked = cands.take(16).toList();
    // Contact sheet: 4 columns of 360×270 tiles, numbered.
    const tw = 360, th = 270, cols = 4;
    final rows = ((picked.length + cols - 1) ~/ cols).clamp(1, 4);
    final sheet = img.Image(width: cols * tw, height: rows * th);
    img.fill(sheet, color: img.ColorRgb8(40, 40, 40));
    final list = <Map<String, Object>>[];
    for (var i = 0; i < picked.length; i++) {
      try {
        final im = img.decodeImage(await getBytes(picked[i].thumb));
        if (im == null) continue;
        final fit = im.width / im.height > tw / th
            ? img.copyResize(im, width: tw - 6)
            : img.copyResize(im, height: th - 6);
        final x = (i % cols) * tw, y = (i ~/ cols) * th;
        img.compositeImage(sheet, fit, dstX: x + 3, dstY: y + 3);
        img.fillRect(
          sheet,
          x1: x + 3,
          y1: y + 3,
          x2: x + 40,
          y2: y + 30,
          color: img.ColorRgb8(0, 0, 0),
        );
        img.drawString(
          sheet,
          '${i + 1}',
          font: img.arial24,
          x: x + 8,
          y: y + 4,
          color: img.ColorRgb8(255, 220, 0),
        );
        list.add({'n': i + 1, ...picked[i].toJson()});
      } catch (err) {
        stdout.writeln('  thumb ${picked[i].id}: $err');
      }
    }
    File('${dir.path}/${e.key}.jpg')
        .writeAsBytesSync(img.encodeJpg(sheet, quality: 80));
    all[e.key] = list;
    stdout.writeln('${e.key}: ${list.length} candidates');
  }
  File('${dir.path}/candidates.json')
      .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(all));
  http.close();
}
