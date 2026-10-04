import 'dart:convert';

import 'package:beat_mitra/core/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('password encryption round-trip', () async {
    final plain = utf8.encode('ರಮೇಶ್ 12/3 4th Cross — secret');
    final enc = await encryptWithPassword(plain, 'correct horse', iterations: 2000);
    expect(isBeatMitraFile(enc), isTrue);
    expect(utf8.decode(enc, allowMalformed: true).contains('Cross'), isFalse);
    final dec = await decryptWithPassword(enc, 'correct horse');
    expect(utf8.decode(dec), 'ರಮೇಶ್ 12/3 4th Cross — secret');
  });

  test('wrong password fails', () async {
    final enc = await encryptWithPassword([1, 2, 3], 'pw1', iterations: 2000);
    expect(() => decryptWithPassword(enc, 'pw2'), throwsA(isA<WrongPasswordException>()));
  });

  test('not a beat mitra file', () async {
    expect(() => decryptWithPassword([1, 2, 3, 4, 5, 6, 7, 8], 'x'), throwsA(isA<NotABeatMitraFileException>()));
  });

  test('tampered file fails', () async {
    final enc = await encryptWithPassword([1, 2, 3, 4], 'pw', iterations: 2000);
    enc[enc.length - 1] ^= 0xff;
    expect(() => decryptWithPassword(enc, 'pw'), throwsA(isA<WrongPasswordException>()));
  });

  test('raw key encryption round-trip', () async {
    final key = randomBytes(32);
    final enc = await encryptWithKey([9, 8, 7], key);
    expect(await decryptWithKey(enc, key), [9, 8, 7]);
  });

  test('PIN hash', () async {
    final h = await hashPin('1234', iterations: 1000);
    expect(await verifyPin('1234', h), isTrue);
    expect(await verifyPin('1235', h), isFalse);
  });
}
