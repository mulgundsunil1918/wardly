import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../main.dart' show navigatorKey, scaffoldMessengerKey;
import '../providers/notification_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

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
      // Show notifications even when app is in foreground (iOS).
      await _msg.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String? token;
      try {
        if (kIsWeb) {
          token = await _msg.getToken(
            vapidKey: const String.fromEnvironment('VAPID_KEY'),
          );
        } else {
          token = await _msg.getToken();
        }
      } catch (e) {
        // APNs token not available yet (simulator or APNs not configured).
        debugPrint('PushService: FCM token unavailable — $e');
        return;
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

      // Foreground messages — save to inbox + show in-app banner.
      _foregroundMsgSub = FirebaseMessaging.onMessage.listen((m) {
        final title = m.notification?.title ?? '';
        final body  = m.notification?.body  ?? '';
        if (title.isEmpty && body.isEmpty) return;
        // Save to notification inbox.
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ctx.read<NotificationProvider>().add(title, body);
        }
        // Show banner via the global scaffold messenger key.
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                if (body.isNotEmpty)
                  Text(body,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
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
