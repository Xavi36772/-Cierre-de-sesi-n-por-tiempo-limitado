import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptedStorage {
  static const _tokenKey = 'auth_token';
  static const _fcmTokenKey = 'fcm_token';
  static const _lastInteractionKey = 'last_interaction_time';
  static const _inactivityTimeoutKey = 'inactivity_timeout_minutes';

  static const _creditCardKey = 'sensitive_credit_card';
  static const _ssnKey = 'sensitive_ssn';
  static const _bankAccountKey = 'sensitive_bank_account';
  static const _pinCodeKey = 'sensitive_pin_code';
  static const _addressKey = 'sensitive_address';

  final FlutterSecureStorage _storage;

  EncryptedStorage() : _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async =>
      _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() async => _storage.read(key: _tokenKey);
  Future<void> deleteToken() async => _storage.delete(key: _tokenKey);

  Future<void> saveFcmToken(String token) async =>
      _storage.write(key: _fcmTokenKey, value: token);
  Future<String?> getFcmToken() async => _storage.read(key: _fcmTokenKey);

  Future<void> saveLastInteractionTime(DateTime time) async =>
      _storage.write(key: _lastInteractionKey, value: time.millisecondsSinceEpoch.toString());
  Future<DateTime?> getLastInteractionTime() async {
    final value = await _storage.read(key: _lastInteractionKey);
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
  }

  Future<void> saveInactivityTimeout(int minutes) async =>
      _storage.write(key: _inactivityTimeoutKey, value: minutes.toString());
  Future<int> getInactivityTimeout() async {
    final value = await _storage.read(key: _inactivityTimeoutKey);
    return value != null ? int.parse(value) : 5;
  }

  Future<void> saveCreditCard(String value) async =>
      _storage.write(key: _creditCardKey, value: value);
  Future<String?> getCreditCard() async => _storage.read(key: _creditCardKey);

  Future<void> saveSsn(String value) async =>
      _storage.write(key: _ssnKey, value: value);
  Future<String?> getSsn() async => _storage.read(key: _ssnKey);

  Future<void> saveBankAccount(String value) async =>
      _storage.write(key: _bankAccountKey, value: value);
  Future<String?> getBankAccount() async => _storage.read(key: _bankAccountKey);

  Future<void> savePinCode(String value) async =>
      _storage.write(key: _pinCodeKey, value: value);
  Future<String?> getPinCode() async => _storage.read(key: _pinCodeKey);

  Future<void> saveAddress(String value) async =>
      _storage.write(key: _addressKey, value: value);
  Future<String?> getAddress() async => _storage.read(key: _addressKey);

  Future<void> deleteSensitiveData() async {
    await Future.wait([
      _storage.delete(key: _creditCardKey),
      _storage.delete(key: _ssnKey),
      _storage.delete(key: _bankAccountKey),
      _storage.delete(key: _pinCodeKey),
      _storage.delete(key: _addressKey),
    ]);
  }

  Future<void> clearAll() async => _storage.deleteAll();
}
