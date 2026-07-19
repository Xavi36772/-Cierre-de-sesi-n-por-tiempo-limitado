import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptedStorage {
  static const _tokenKey = 'auth_token';
  static const _lastInteractionKey = 'last_interaction_time';
  static const _inactivityTimeoutKey = 'inactivity_timeout_minutes';

  final FlutterSecureStorage _storage;

  EncryptedStorage()
      : _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveLastInteractionTime(DateTime time) async {
    await _storage.write(
      key: _lastInteractionKey,
      value: time.millisecondsSinceEpoch.toString(),
    );
  }

  Future<DateTime?> getLastInteractionTime() async {
    final value = await _storage.read(key: _lastInteractionKey);
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
  }

  Future<void> saveInactivityTimeout(int minutes) async {
    await _storage.write(key: _inactivityTimeoutKey, value: minutes.toString());
  }

  Future<int> getInactivityTimeout() async {
    final value = await _storage.read(key: _inactivityTimeoutKey);
    return value != null ? int.parse(value) : 5;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
