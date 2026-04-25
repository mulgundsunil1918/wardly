import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Centralised share text. Returns a download/use link appropriate
/// for the current platform. When the app is published these links
/// can be swapped without changing call sites.
class ShareHelper {
  static const String _webUrl = 'https://mulgundsunil1918.github.io/wardly/';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.wardly.app';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/wardly/id0000000000';
  // App is not yet on Play Store / App Store. Until it ships there,
  // every platform shares the website link. Switch to the store URLs
  // by uncommenting the platform branch below once published.
  static String _platformLink() {
    return _webUrl;
    // if (kIsWeb) return _webUrl;
    // switch (defaultTargetPlatform) {
    //   case TargetPlatform.android: return _playStoreUrl;
    //   case TargetPlatform.iOS: return _appStoreUrl;
    //   default: return _webUrl;
    // }
  }

  static String message() {
    return 'Try Wardly — real-time clinical notes for ward teams.\n\n'
        '${_platformLink()}';
  }

  static Future<void> shareApp() async {
    await Share.share(message(), subject: 'Check out Wardly');
  }
}
