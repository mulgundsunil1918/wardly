import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

/// Centralised share text. Returns a download/use link appropriate
/// for the current platform. When the app is published these links
/// can be swapped without changing call sites.
class ShareHelper {
  static const String _webUrl = 'https://mulgundsunil1918.github.io/wardly/';

  // Switch to Play / App Store URLs once published.
  static String _platformLink() => _webUrl;

  static String _baseMessage() =>
      'Try Wardly — real-time clinical notes for ward teams.';

  static String message() => '${_baseMessage()}\n\n${_platformLink()}';

  /// Returns a personalised share message including the signed-in user's
  /// name and (if set) specialty.
  static Future<String> personalisedMessage() async {
    final uid = fba.FirebaseAuth.instance.currentUser?.uid;
    String? name;
    String? specialty;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();
        name = data?['name'] as String?;
        specialty = data?['specialty'] as String?;
      } catch (_) {}
    }
    final byLine = (name != null && name.trim().isNotEmpty)
        ? (specialty != null && specialty.trim().isNotEmpty
            ? '\nFrom Dr. ${name.trim()} · ${specialty.trim()}'
            : '\nFrom ${name.trim()}')
        : '';
    return '${_baseMessage()}$byLine\n\n${_platformLink()}';
  }

  static Future<void> shareApp() async {
    final msg = await personalisedMessage();
    await Share.share(msg, subject: 'Check out Wardly');
  }
}
