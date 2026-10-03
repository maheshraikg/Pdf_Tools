import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'crypto.dart';
import 'services/secret_store.dart';

/// App lock: PIN (hashed with PBKDF2, kept in secure storage) and optional
/// fingerprint / face unlock. Locks on start and after [timeout] in the
/// background.
class AppLock extends ChangeNotifier {
  AppLock(this._store, {LocalAuthentication? auth}) : _auth = auth; // ignore: prefer_initializing_formals

  final SecretStore _store;
  final LocalAuthentication? _auth;
  static const _pinKey = 'beat_mitra_pin_v1';

  bool _locked = true;
  bool _hasPin = false;
  DateTime? _pausedAt;
  int _failed = 0;
  DateTime? _blockedUntil;

  bool get locked => _locked && _hasPin;
  bool get hasPin => _hasPin;
  DateTime? get blockedUntil => _blockedUntil;

  Future<void> init() async {
    _hasPin = (await _store.read(_pinKey)) != null;
    _locked = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _store.write(_pinKey, await hashPin(pin));
    _hasPin = true;
    _locked = false;
    notifyListeners();
  }

  Future<bool> checkPin(String pin) async {
    final stored = await _store.read(_pinKey);
    if (stored == null) return false;
    return verifyPin(pin, stored);
  }

  /// Returns true on success. After 5 wrong PINs, waits 30 s.
  Future<bool> unlockWithPin(String pin) async {
    if (_blockedUntil != null && DateTime.now().isBefore(_blockedUntil!)) return false;
    if (await checkPin(pin)) {
      _failed = 0;
      _blockedUntil = null;
      _locked = false;
      notifyListeners();
      return true;
    }
    _failed++;
    if (_failed >= 5) {
      _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
      _failed = 0;
    }
    notifyListeners();
    return false;
  }

  Future<bool> canUseBiometric() async {
    final a = _auth;
    if (a == null) return false;
    try {
      return await a.isDeviceSupported() && await a.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> unlockWithBiometric(String reason) async {
    final a = _auth;
    if (a == null) return false;
    try {
      final ok = await a.authenticate(localizedReason: reason, biometricOnly: true);
      if (ok) {
        _locked = false;
        notifyListeners();
      }
      return ok;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  void lockNow() {
    _locked = true;
    notifyListeners();
  }

  void onPaused() => _pausedAt = DateTime.now();

  void onResumed(Duration timeout) {
    final p = _pausedAt;
    _pausedAt = null;
    if (p != null && DateTime.now().difference(p) >= timeout && _hasPin) {
      _locked = true;
      notifyListeners();
    }
  }

  Future<void> removePin() async {
    await _store.delete(_pinKey);
    _hasPin = false;
    notifyListeners();
  }
}
