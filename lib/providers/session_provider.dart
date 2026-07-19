import 'package:flutter/foundation.dart';
import '../services/encrypted_storage.dart';
import '../services/inactivity_service.dart';
import '../services/fcm_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class SessionProvider extends ChangeNotifier {
  final EncryptedStorage _storage = EncryptedStorage();
  final InactivityService _inactivityService = InactivityService();
  final FcmService _fcmService = FcmService();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  int _inactivityTimeoutMinutes = 5;

  String? _creditCard;
  String? _ssn;
  String? _bankAccount;
  String? _pinCode;
  String? _address;
  bool _sensitiveDataLoaded = false;

  AuthStatus get status => _status;
  String? get token => _token;
  int get inactivityTimeoutMinutes => _inactivityTimeoutMinutes;
  InactivityService get inactivityService => _inactivityService;
  FcmService get fcmService => _fcmService;

  String? get creditCard => _creditCard;
  String? get ssn => _ssn;
  String? get bankAccount => _bankAccount;
  String? get pinCode => _pinCode;
  String? get address => _address;
  bool get sensitiveDataLoaded => _sensitiveDataLoaded;
  bool get hasSensitiveData =>
      _creditCard != null ||
      _ssn != null ||
      _bankAccount != null ||
      _pinCode != null ||
      _address != null;

  Future<void> tryAutoLogin() async {
    final token = await _storage.getToken();
    final lastInteraction = await _storage.getLastInteractionTime();
    final timeout = await _storage.getInactivityTimeout();

    _inactivityTimeoutMinutes = timeout;

    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (lastInteraction != null) {
      final elapsed = DateTime.now().difference(lastInteraction);
      if (elapsed.inMinutes >= timeout) {
        await _logout();
        return;
      }
    }

    _token = token;
    _status = AuthStatus.authenticated;
    notifyListeners();
    _initFcm();
    _startInactivityMonitoring();
    _loadSensitiveData();
  }

  Future<void> login(String username, String password) async {
    final fakeToken =
        'token_${username}_${DateTime.now().millisecondsSinceEpoch}';
    _token = fakeToken;
    await _storage.saveToken(fakeToken);
    await _storage.saveInactivityTimeout(_inactivityTimeoutMinutes);
    _status = AuthStatus.authenticated;
    notifyListeners();
    _initFcm();
    _startInactivityMonitoring();
    _seedSensitiveData();
  }

  Future<void> _initFcm() async {
    await _fcmService.initialize();
    _fcmService.onSensitiveDataWiped = () {
      _clearSensitiveDataInMemory();
      notifyListeners();
    };
  }

  Future<void> _seedSensitiveData() async {
    await _storage.saveCreditCard('4532-1234-5678-9012');
    await _storage.saveSsn('123-45-6789');
    await _storage.saveBankAccount('MX12 3456 7890 1234 5678');
    await _storage.savePinCode('9876');
    await _storage.saveAddress('Calle Principal #123, Col. Centro, CP 45000');
    _creditCard = '4532-1234-5678-9012';
    _ssn = '123-45-6789';
    _bankAccount = 'MX12 3456 7890 1234 5678';
    _pinCode = '9876';
    _address = 'Calle Principal #123, Col. Centro, CP 45000';
    _sensitiveDataLoaded = true;
    notifyListeners();
  }

  Future<void> _loadSensitiveData() async {
    _creditCard = await _storage.getCreditCard();
    _ssn = await _storage.getSsn();
    _bankAccount = await _storage.getBankAccount();
    _pinCode = await _storage.getPinCode();
    _address = await _storage.getAddress();
    _sensitiveDataLoaded = true;
    notifyListeners();
  }

  void _clearSensitiveDataInMemory() {
    _creditCard = null;
    _ssn = null;
    _bankAccount = null;
    _pinCode = null;
    _address = null;
  }

  Future<void> logout() async {
    _inactivityService.stop();
    await _storage.clearAll();
    _token = null;
    _clearSensitiveDataInMemory();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _logout() async {
    _inactivityService.stop();
    await _storage.clearAll();
    _token = null;
    _clearSensitiveDataInMemory();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> remoteWipeData() async {
    await _fcmService.deleteSensitiveDataLocally();
    _clearSensitiveDataInMemory();
    notifyListeners();
  }

  void _startInactivityMonitoring() {
    _inactivityService.configure(
      timeout: Duration(minutes: _inactivityTimeoutMinutes),
      onTimeout: () async {
        await _logout();
      },
    );
    _inactivityService.start();
  }

  void registerInteraction() {
    if (_status == AuthStatus.authenticated) {
      _inactivityService.registerInteraction();
      _storage.saveLastInteractionTime(DateTime.now());
    }
  }

  void updateInactivityTimeout(int minutes) {
    _inactivityTimeoutMinutes = minutes;
    _storage.saveInactivityTimeout(minutes);
    if (_status == AuthStatus.authenticated) {
      _inactivityService.configure(
        timeout: Duration(minutes: minutes),
        onTimeout: () async {
          await _logout();
        },
      );
      _inactivityService.registerInteraction();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _inactivityService.dispose();
    super.dispose();
  }
}
