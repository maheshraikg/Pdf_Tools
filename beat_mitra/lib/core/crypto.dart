/// Encryption helpers (all on device, no network).
///
/// * Password files (.beatmitra handover / full backup):
///   AES-256-GCM, key = PBKDF2-HMAC-SHA256(password, random 16-byte salt).
/// * Photos at rest: AES-256-GCM with a random device key kept in
///   flutter_secure_storage (Android Keystore backed).
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// File header: "BMITRA" + format version.
const List<int> _magic = [0x42, 0x4D, 0x49, 0x54, 0x52, 0x41];
const int _formatVersion = 1;

/// Default PBKDF2 iterations for password files.
const int defaultPbkdf2Iterations = 210000;

class WrongPasswordException implements Exception {
  @override
  String toString() => 'WrongPasswordException';
}

class NotABeatMitraFileException implements Exception {
  @override
  String toString() => 'NotABeatMitraFileException';
}

final _aes = AesGcm.with256bits();
final Random _rng = Random.secure();

Uint8List randomBytes(int n) => Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));

Future<SecretKey> deriveKey(String password, List<int> salt, int iterations) {
  final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
  return kdf.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
}

/// Encrypts [plain] with a key derived from [password].
/// Layout: magic(6) | ver(1) | iterations(4, BE) | salt(16) | nonce(12) | mac(16) | ciphertext.
Future<Uint8List> encryptWithPassword(
  List<int> plain,
  String password, {
  int iterations = defaultPbkdf2Iterations,
}) async {
  final salt = randomBytes(16);
  final key = await deriveKey(password, salt, iterations);
  final nonce = _aes.newNonce();
  final box = await _aes.encrypt(plain, secretKey: key, nonce: nonce);
  final out = BytesBuilder(copy: false)
    ..add(_magic)
    ..addByte(_formatVersion)
    ..add((ByteData(4)..setUint32(0, iterations)).buffer.asUint8List())
    ..add(salt)
    ..add(box.nonce)
    ..add(box.mac.bytes)
    ..add(box.cipherText);
  return out.toBytes();
}

/// True when [data] starts with the Beat Mitra header.
bool isBeatMitraFile(List<int> data) {
  if (data.length < _magic.length + 1) return false;
  for (var i = 0; i < _magic.length; i++) {
    if (data[i] != _magic[i]) return false;
  }
  return true;
}

Future<Uint8List> decryptWithPassword(List<int> data, String password) async {
  if (!isBeatMitraFile(data) || data.length < 6 + 1 + 4 + 16 + 12 + 16) {
    throw NotABeatMitraFileException();
  }
  var o = _magic.length;
  final ver = data[o++];
  if (ver != _formatVersion) throw NotABeatMitraFileException();
  final iterations = ByteData.sublistView(Uint8List.fromList(data.sublist(o, o + 4))).getUint32(0);
  o += 4;
  if (iterations < 1000 || iterations > 10000000) throw NotABeatMitraFileException();
  final salt = data.sublist(o, o + 16);
  o += 16;
  final nonce = data.sublist(o, o + 12);
  o += 12;
  final mac = data.sublist(o, o + 16);
  o += 16;
  final cipher = data.sublist(o);
  final key = await deriveKey(password, salt, iterations);
  try {
    final plain = await _aes.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
      secretKey: key,
    );
    return Uint8List.fromList(plain);
  } on SecretBoxAuthenticationError {
    throw WrongPasswordException();
  }
}

/// Encrypts with a raw 32-byte key. Layout: nonce(12) | mac(16) | ciphertext.
Future<Uint8List> encryptWithKey(List<int> plain, List<int> key) async {
  final box = await _aes.encrypt(plain, secretKey: SecretKey(key));
  return (BytesBuilder(copy: false)
        ..add(box.nonce)
        ..add(box.mac.bytes)
        ..add(box.cipherText))
      .toBytes();
}

Future<Uint8List> decryptWithKey(List<int> data, List<int> key) async {
  final box = SecretBox(data.sublist(28), nonce: data.sublist(0, 12), mac: Mac(data.sublist(12, 28)));
  return Uint8List.fromList(await _aes.decrypt(box, secretKey: SecretKey(key)));
}

/// PIN hashing for the app lock (PBKDF2, 100k iterations, random salt).
Future<String> hashPin(String pin, {List<int>? salt, int iterations = 100000}) async {
  final s = salt ?? randomBytes(16);
  final key = await deriveKey(pin, s, iterations);
  final bytes = await key.extractBytes();
  return '$iterations:${base64Encode(s)}:${base64Encode(bytes)}';
}

Future<bool> verifyPin(String pin, String stored) async {
  final parts = stored.split(':');
  if (parts.length != 3) return false;
  final it = int.tryParse(parts[0]) ?? 0;
  final again = await hashPin(pin, salt: base64Decode(parts[1]), iterations: it);
  return _constantTimeEquals(again, stored);
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var r = 0;
  for (var i = 0; i < a.length; i++) {
    r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return r == 0;
}
