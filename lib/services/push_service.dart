import 'dart:async';

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

  // Hold onto the FCM stream subscriptions so a re-register doesn't
  // stack a second listener on top of an already-running one (which is
  // exactly what happened before — every login appended another live
  // listener that never cancelled).
  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _foregroundMsgSub;

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

      // Cancel any prior subscriptions before rewiring — sign-in twice in
      // one session shouldn't leave two listeners running.
      await _tokenRefreshSub?.cancel();
      await _foregroundMsgSub?.cancel();

      // Refresh on rotation.
      _tokenRefreshSub = _msg.onTokenRefresh.listen((newToken) async {
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
      _foregroundMsgSub = FirebaseMessaging.onMessage.listen((m) {
        debugPrint('FCM foreground: ${m.notification?.title} — '
            '${m.notification?.body}');
      });
    } catch (e) {
      debugPrint('PushService.register failed: $e');
    }
  }

  /// Call on sign-out to remove the device's token from the user doc and
  /// tear down the FCM listeners we set up in [register].
  static Future<void> unregister(String uid) async {
    try {
      await _tokenRefreshSub?.cancel();
      await _foregroundMsgSub?.cancel();
      _tokenRefreshSub = null;
      _foregroundMsgSub = null;

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
