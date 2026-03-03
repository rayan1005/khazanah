import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initialize notifications and save FCM token
  Future<void> initialize(String userId) async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFcmToken(userId, token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveFcmToken(userId, newToken);
    });
  }

  Future<void> _saveFcmToken(String userId, String token) async {
    await _db.collection(FirestorePaths.users).doc(userId).update({
      'fcmToken': token,
    });
  }

  /// Handle foreground messages
  void onForegroundMessage(void Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  /// Handle background message tap
  void onMessageOpenedApp(void Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  /// Get initial message (app opened from terminated state via notification)
  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }
}
