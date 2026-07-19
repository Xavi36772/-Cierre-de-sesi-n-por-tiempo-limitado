import 'package:flutter/foundation.dart';
import '../services/encrypted_storage.dart';
import '../services/inactivity_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class SessionProvider extends ChangeNotifier {
  final EncryptedStorage _storage = EncryptedStorage();
  final InactivityService _inactivityService = InactivityService();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  int _inactivityTimeoutMinutes = 5;

  AuthStatus get status => _status;
  String? get token => _token;
  int get inactivityTimeoutMinutes => _inactivityTimeoutMinutes;
  InactivityService get inactivityService => _inactivityService;

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
    _startInactivityMonitoring();
  }

  Future<void> login(String username, String password) async {
    final fakeToken = 'token_${username}_${DateTime.now().millisecondsSinceEpoch}';
    _token = fakeToken;
    await _storage.saveToken(fakeToken);
    await _storage.saveInactivityTimeout(_inactivityTimeoutMinutes);
    _status = AuthStatus.authenticated;
    notifyListeners();
    _startInactivityMonitoring();
  }

  Future<void> logout() async {
    _inactivityService.stop();
    await _storage.clearAll();
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _logout() async {
    _inactivityService.stop();
    await _storage.clearAll();
    _token = null;
    _status = AuthStatus.unauthenticated;
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
