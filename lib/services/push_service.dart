import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_constants.dart';

/// Registers the device's FCM token under the signed-in user's doc so
/// a Cloud Function can fan out push notifications to ward members.
class PushService {
  static final FirebaseMessaging _msg = FirebaseMessaging.instance;
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// Call once after sign-in / sign-up.
  static Future<void> register() async {
    try {
      // Ask for permission (iOS + web). Android grants by default.
      await _msg.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String? token;
      if (kIsWeb) {
        // Web push requires a VAPID key. If not configured, this returns null.
        token = await _msg.getToken(
          vapidKey: const String.fromEnvironment('VAPID_KEY'),
        );
      } else {
        token = await _msg.getToken();
      }
      if (token == null || token.isEmpty) return;

      await _fs
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      // Refresh on rotation.
      _msg.onTokenRefresh.listen((newToken) async {
        try {
          await _fs
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .set({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
          }, SetOptions(merge: true));
        } catch (_) {}
      });

      // Foreground messages — show as in-app SnackBar via the app's
      // navigator key if you wire one up. For now just print to debug.
      FirebaseMessaging.onMessage.listen((m) {
        debugPrint('FCM foreground: ${m.notification?.title} — '
            '${m.notification?.body}');
      });
    } catch (e) {
      debugPrint('PushService.register failed: $e');
    }
  }

  /// Call on sign-out to remove the device's token from the user doc.
  static Future<void> unregister(String uid) async {
    try {
      final token = await _msg.getToken();
      if (token == null) return;
      await _fs
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
