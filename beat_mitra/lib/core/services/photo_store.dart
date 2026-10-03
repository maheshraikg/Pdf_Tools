import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto.dart';
import 'secret_store.dart';

/// Stores place photos as AES-GCM encrypted JPEGs (≤ 200 KB before
/// encryption) in app-private storage. They never reach the gallery and are
/// excluded from Android cloud backup (see AndroidManifest / backup rules).
abstract class PhotoStore {
  /// Compresses, encrypts and saves. Returns the stored file name.
  Future<String> saveFromCamera(String tempPath);
  Future<String> saveBytes(Uint8List jpeg);
  Future<Uint8List?> load(String name);
  Future<void> delete(String name);
  Future<void> deleteAll();
}

const int maxPhotoBytes = 200 * 1024;

class DevicePhotoStore implements PhotoStore {
  DevicePhotoStore(this._secrets);
  final SecretStore _secrets;
  static const _keyName = 'beat_mitra_photo_key_v1';
  List<int>? _key;
  Directory? _dir;
  final _cache = <String, Uint8List>{};

  Future<List<int>> _getKey() async {
    if (_key != null) return _key!;
    var k = await _secrets.read(_keyName);
    if (k == null) {
      k = base64Encode(randomBytes(32));
      await _secrets.write(_keyName, k);
    }
    return _key = base64Decode(k);
  }

  Future<Directory> _photoDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'photos'));
    if (!d.existsSync()) d.createSync(recursive: true);
    return _dir = d;
  }

  /// Re-encode until the JPEG is ≤ 200 KB.
  static Future<Uint8List> compressToLimit(String path) async {
    var quality = 80;
    var size = 1280;
    Uint8List? out;
    for (var i = 0; i < 6; i++) {
      out = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: size,
        minHeight: size,
        quality: quality,
        keepExif: false,
      );
      if (out == null) break;
      if (out.length <= maxPhotoBytes) return out;
      quality = (quality - 12).clamp(30, 90);
      size = (size * 0.8).round();
    }
    if (out == null) throw const FileSystemException('Could not compress photo');
    return out;
  }

  @override
  Future<String> saveFromCamera(String tempPath) async {
    final jpeg = await compressToLimit(tempPath);
    try {
      File(tempPath).deleteSync(); // remove the camera's temporary copy
    } catch (_) {}
    return saveBytes(jpeg);
  }

  @override
  Future<String> saveBytes(Uint8List jpeg) async {
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${randomBytes(4).map((b) => b.toRadixString(16)).join()}.enc';
    final enc = await encryptWithKey(jpeg, await _getKey());
    await File(p.join((await _photoDir()).path, name)).writeAsBytes(enc, flush: true);
    _remember(name, jpeg);
    return name;
  }

  void _remember(String name, Uint8List bytes) {
    _cache.remove(name);
    _cache[name] = bytes;
    while (_cache.length > 40) {
      _cache.remove(_cache.keys.first);
    }
  }

  @override
  Future<Uint8List?> load(String name) async {
    final c = _cache[name];
    if (c != null) return c;
    final f = File(p.join((await _photoDir()).path, p.basename(name)));
    if (!f.existsSync()) return null;
    try {
      final bytes = await decryptWithKey(await f.readAsBytes(), await _getKey());
      _remember(name, bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String name) async {
    _cache.remove(name);
    final f = File(p.join((await _photoDir()).path, p.basename(name)));
    if (f.existsSync()) await f.delete();
  }

  @override
  Future<void> deleteAll() async {
    _cache.clear();
    final d = await _photoDir();
    if (d.existsSync()) await d.delete(recursive: true);
    _dir = null;
    await _secrets.delete(_keyName);
    _key = null;
  }
}

/// In-memory store for tests.
class MemoryPhotoStore implements PhotoStore {
  final Map<String, Uint8List> files = {};
  var _n = 0;
  @override
  Future<String> saveFromCamera(String tempPath) async => saveBytes(Uint8List(0));
  @override
  Future<String> saveBytes(Uint8List jpeg) async {
    final name = 'p${_n++}.enc';
    files[name] = jpeg;
    return name;
  }

  @override
  Future<Uint8List?> load(String name) async => files[name];
  @override
  Future<void> delete(String name) async => files.remove(name);
  @override
  Future<void> deleteAll() async => files.clear();
}
