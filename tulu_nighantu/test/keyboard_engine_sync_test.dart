import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_nighantu/lipi/composer.dart';
import 'package:tulu_nighantu/lipi/tulu_lipi.dart';

/// The Android system keyboard (Kotlin) has its own copy of the conversion
/// table and editing rules; this keeps it identical to the Dart version.
void main() {
  final kt = File(
    'android/app/src/main/kotlin/com/kspstadk/tulu_nighantu/keyboard/'
    'TuluEngine.kt',
  ).readAsStringSync();

  String unescape(String s) => s.replaceAllMapped(
    RegExp(r'\\u([0-9A-Fa-f]{4})'),
    (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
  );

  test('Kotlin map equals the Dart conversion for every key', () {
    final block = kt.substring(
      kt.indexOf('val MAP'),
      kt.indexOf('private val'),
    );
    final pairs = RegExp(r'0x([0-9A-Fa-f]+) to 0x([0-9A-Fa-f]+)')
        .allMatches(block)
        .toList();
    expect(pairs.length, greaterThan(60));
    for (final m in pairs) {
      final from = int.parse(m[1]!, radix: 16);
      final to = int.parse(m[2]!, radix: 16);
      expect(
        TuluLipi.fromKannada(String.fromCharCode(from)),
        String.fromCharCode(to),
        reason: from.toRadixString(16),
      );
    }
    // Every Kannada code point the Dart side maps is in the Kotlin map.
    final kotlinKeys = {for (final m in pairs) int.parse(m[1]!, radix: 16)};
    for (var c = 0x0C80; c <= 0x0CFF; c++) {
      final s = String.fromCharCode(c);
      final mapped = TuluLipi.fromKannada(s);
      if (mapped != s && mapped.runes.length == 1) {
        expect(kotlinKeys, contains(c), reason: c.toRadixString(16));
      }
    }
  });

  test('Kotlin vowel-sign row equals the Dart one', () {
    final block = kt.substring(
      kt.indexOf('val VOWEL_SIGNS'),
      kt.indexOf('fun normalize'),
    );
    final signs = RegExp(r'"((?:\\u[0-9A-Fa-f]{4})+)"')
        .allMatches(block)
        .map((m) => unescape(m[1]!))
        .toList();
    expect(signs, kVowelSigns);
  });
}
