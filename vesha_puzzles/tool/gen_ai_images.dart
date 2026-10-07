// Generates puzzle pictures and guide portraits with Google's image
// models through the Gemini API. Run from vesha_puzzles/ with the key in
// the environment (never commit it):
//
//   GEMINI_API_KEY=... dart run tool/gen_ai_images.dart [--only id,id] [--model NAME] [--variants N]
//
// Prompts and the shared style are in tool/ai_prompts.json. Puzzles are
// generated at 4:3 and written over assets/packs/<pack>/images/<id>.jpg;
// with --variants N (N>1) candidates are written to build/ai/ instead so a
// person can choose. Each puzzle gets a "credit" block in pack.json
// stating it is AI-generated and with which model. Generated cultural
// imagery still needs the expert review in docs/CONTENT_TO_REVIEW.md.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const base = 'https://generativelanguage.googleapis.com/v1beta/models';

Future<Map<String, dynamic>> post(
  String url,
  Map<String, Object?> body,
  String key,
) async {
  final c = HttpClient();
  final req = await c.postUrl(Uri.parse(url));
  req.headers
    ..contentType = ContentType.json
    ..set('x-goog-api-key', key);
  req.write(jsonEncode(body));
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  c.close();
  if (res.statusCode != 200) {
    throw HttpException(
      'HTTP ${res.statusCode}: ${text.length > 400 ? text.substring(0, 400) : text}',
    );
  }
  return jsonDecode(text) as Map<String, dynamic>;
}

/// Returns image bytes from an Imagen model (`:predict`) or a Gemini
/// image model (`:generateContent`), depending on the model name.
Future<List<Uint8List>> generate(
  String model,
  String prompt,
  String aspect,
  int n,
  String key,
) async {
  if (model.startsWith('imagen')) {
    final r = await post('$base/$model:predict', {
      'instances': [
        {'prompt': prompt},
      ],
      'parameters': {
        'sampleCount': n,
        'aspectRatio': aspect,
        'personGeneration': 'allow_all',
      },
    }, key);
    return [
      for (final p in (r['predictions'] as List? ?? const []).cast<Map>())
        if (p['bytesBase64Encoded'] != null)
          base64Decode(p['bytesBase64Encoded'] as String),
    ];
  }
  final out = <Uint8List>[];
  for (var i = 0; i < n; i++) {
    final r = await post('$base/$model:generateContent', {
      'contents': [
        {
          'parts': [
            {'text': '$prompt Aspect ratio $aspect.'},
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['IMAGE'],
        'imageConfig': {'aspectRatio': aspect},
      },
    }, key);
    for (final c in (r['candidates'] as List? ?? const []).cast<Map>()) {
      for (final p
          in ((c['content'] as Map?)?['parts'] as List? ?? const [])
              .cast<Map>()) {
        final d = (p['inlineData'] ?? p['inline_data']) as Map?;
        if (d?['data'] != null) out.add(base64Decode(d!['data'] as String));
      }
    }
  }
  return out;
}

img.Image fitTo(img.Image im, int w, int h) {
  final a = w / h;
  if (im.width / im.height > a) {
    final cw = (im.height * a).round();
    im = img.copyCrop(
      im,
      x: (im.width - cw) ~/ 2,
      y: 0,
      width: cw,
      height: im.height,
    );
  } else if (im.width / im.height < a) {
    final ch = (im.width / a).round();
    im = img.copyCrop(
      im,
      x: 0,
      y: (im.height - ch) ~/ 2,
      width: im.width,
      height: ch,
    );
  }
  return img.copyResize(
    im,
    width: w,
    height: h,
    interpolation: img.Interpolation.cubic,
  );
}

Future<void> main(List<String> args) async {
  final key = Platform.environment['GEMINI_API_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('Set GEMINI_API_KEY in the environment.');
    exit(2);
  }
  String? arg(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final model = arg('--model') ?? 'imagen-4.0-generate-001';
  final variants = int.tryParse(arg('--variants') ?? '1') ?? 1;
  final only = arg('--only')?.split(',').toSet();
  final prompts = jsonDecode(
    File('tool/ai_prompts.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final style = prompts['_style'] as String;
  final failed = <String>[];

  // Puzzles.
  final packs =
      (jsonDecode(File('assets/packs/index.json').readAsStringSync())['packs']
              as List)
          .cast<String>();
  for (final packId in packs) {
    final f = File('assets/packs/$packId/pack.json');
    final pack = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final p in (pack['puzzles'] as List).cast<Map<String, dynamic>>()) {
      final id = p['id'] as String;
      final subject = (prompts['puzzles'] as Map)[id] as String?;
      if (subject == null || (only != null && !only.contains(id))) continue;
      stdout.write('$id … ');
      try {
        final imgs = await generate(
          model,
          '$subject $style',
          '4:3',
          variants,
          key,
        );
        if (imgs.isEmpty) {
          throw StateError('no image returned (possibly filtered)');
        }
        for (var i = 0; i < imgs.length; i++) {
          final decoded = img.decodeImage(imgs[i])!;
          final out = fitTo(decoded, 2048, 1536);
          final path = variants > 1
              ? 'build/ai/${id}_v${i + 1}.jpg'
              : 'assets/packs/$packId/${p['image']}';
          File(path)
            ..parent.createSync(recursive: true)
            ..writeAsBytesSync(img.encodeJpg(out, quality: 88));
        }
        if (variants == 1) {
          p['credit'] = {
            'title': id,
            'author': 'AI-generated illustration ($model)',
            'licence': 'Generated for Vesha Puzzles',
            'source': 'tool/ai_prompts.json',
            'changes': 'Resized to 2048×1536',
          };
        }
        stdout.writeln('ok (${imgs.length})');
      } catch (e) {
        stdout.writeln('FAILED: $e');
        failed.add(id);
      }
    }
    if (variants == 1) {
      pack['placeholder'] = (pack['puzzles'] as List).cast<Map>().any(
        (p) => p['credit'] == null,
      );
      f.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(pack)}\n',
      );
    }
  }

  // Guide portraits (square, opaque on a cream background).
  for (final e in (prompts['guide'] as Map).entries) {
    if (only != null && !only.contains(e.key)) continue;
    stdout.write('${e.key} … ');
    try {
      final imgs = await generate(model, e.value as String, '1:1', 1, key);
      if (imgs.isEmpty) throw StateError('no image returned');
      final out = fitTo(img.decodeImage(imgs.first)!, 768, 768);
      File('assets/guide/${e.key}.png')
          .writeAsBytesSync(img.encodePng(out, level: 9));
      stdout.writeln('ok');
    } catch (err) {
      stdout.writeln('FAILED: $err');
      failed.add(e.key);
    }
  }
  stdout.writeln(failed.isEmpty ? 'All done.' : 'Failed: ${failed.join(', ')}');
}
