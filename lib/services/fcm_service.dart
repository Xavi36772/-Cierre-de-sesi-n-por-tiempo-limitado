import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/encrypted_storage.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final EncryptedStorage _storage = EncryptedStorage();
  FirebaseMessaging? _messaging;

  String? _currentFcmToken;
  void Function()? onSensitiveDataWiped;

  String? get currentFcmToken => _currentFcmToken;

  Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('FCM not available: $e');
      return;
    }

    try {
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Permiso de notificaciones denegado');
        return;
      }

      _currentFcmToken = await _messaging!.getToken();
      if (_currentFcmToken != null) {
        await _storage.saveFcmToken(_currentFcmToken!);
      }

      _messaging!.onTokenRefresh.listen((newToken) async {
        _currentFcmToken = newToken;
        await _storage.saveFcmToken(newToken);
      });

      FirebaseMessaging.onMessage.listen(_handleMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    if (data['action'] == 'remote_wipe') {
      _performRemoteWipe(data);
    }
  }

  Future<void> _performRemoteWipe(Map<String, dynamic> data) async {
    final targetUserId = data['user_id'] as String?;
    final currentToken = await _storage.getToken();

    if (targetUserId == null || currentToken == null) return;

    if (currentToken.contains(targetUserId)) {
      await _storage.deleteSensitiveData();
      onSensitiveDataWiped?.call();
    }
  }

  Future<void> deleteSensitiveDataLocally() async {
    await _storage.deleteSensitiveData();
  }
}
