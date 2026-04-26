import 'package:share_plus/share_plus.dart';

/// Centralised share text. Returns a download/use link appropriate
/// for the current platform. When the app is published these links
/// can be swapped without changing call sites.
class ShareHelper {
  static const String _webUrl = 'https://mulgundsunil1918.github.io/wardly/';

  // Switch to Play / App Store URLs once published.
  static String _platformLink() => _webUrl;

  static String message() {
    return 'Try Wardly — real-time clinical notes for ward teams.\n\n'
        '${_platformLink()}';
  }

  static Future<void> shareApp() async {
    await Share.share(message(), subject: 'Check out Wardly');
  }
}
