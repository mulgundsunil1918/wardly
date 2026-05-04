import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/app_user.dart';
import '../utils/app_constants.dart';
import 'metrics_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get firebaseUser => _auth.currentUser;

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<AppUser?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<AppUser?> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? wardId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    await user.updateDisplayName(name);

    final now = DateTime.now();
    final data = {
      'name': name,
      'email': email.trim(),
      'role': role,
      'wardId': wardId ?? '',
      'wardIds': wardId != null && wardId.isNotEmpty ? [wardId] : <String>[],
      'avatarUrl': null,
      'createdAt': Timestamp.fromDate(now),
    };
    await _users.doc(user.uid).set(data);
    MetricsService.bump('user', summary: 'New account: $name');

    final doc = await _users.doc(user.uid).get();
    return AppUser.fromFirestore(doc);
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      UserCredential cred;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        cred = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }
      final user = cred.user;
      if (user == null) return null;

      final doc = await _users.doc(user.uid).get();
      if (!doc.exists) {
        final now = DateTime.now();
        final displayName =
            user.displayName ?? (user.email ?? 'User').split('@').first;
        await _users.doc(user.uid).set({
          'name': displayName,
          'email': user.email ?? '',
          'role': 'doctor',
          'wardId': '',
          'wardIds': <String>[],
          'avatarUrl': user.photoURL,
          'createdAt': Timestamp.fromDate(now),
        });
        // First-time Google sign-in is also a new account → bump userCount
        // so the public dashboard tally stays honest.
        MetricsService.bump('user',
            summary: 'New Google account: $displayName');
      }
      final fresh = await _users.doc(user.uid).get();
      return AppUser.fromFirestore(fresh);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Apple — iOS-only. Apple App Review rejects apps that
  /// offer third-party social sign-in (Google, in our case) but not
  /// Apple Sign-In, so this exists purely to satisfy that requirement
  /// on iOS. Android raises a runtime error if called there.
  Future<AppUser?> signInWithApple() async {
    if (kIsWeb) {
      throw UnsupportedError('Sign in with Apple is iOS-only.');
    }
    if (!Platform.isIOS) {
      throw UnsupportedError('Sign in with Apple is iOS-only.');
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauth = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      // We don't generate a nonce — sign_in_with_apple's helper will
      // sign the request natively. Apple may return null for email on
      // subsequent sign-ins (it's only sent the FIRST time the user
      // grants access), so we synthesise a display name if missing.
    );
    final cred = await _auth.signInWithCredential(oauth);
    final user = cred.user;
    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) {
      final now = DateTime.now();
      final composed = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ').trim();
      final displayName = composed.isNotEmpty
          ? composed
          : (user.displayName ??
              (user.email ?? 'Apple user').split('@').first);
      await _users.doc(user.uid).set({
        'name': displayName,
        'email': user.email ?? credential.email ?? '',
        'role': 'doctor',
        'wardId': '',
        'wardIds': <String>[],
        'avatarUrl': user.photoURL,
        'createdAt': Timestamp.fromDate(now),
      });
      MetricsService.bump('user',
          summary: 'New Apple account: $displayName');
    }
    final fresh = await _users.doc(user.uid).get();
    return AppUser.fromFirestore(fresh);
  }

  Future<void> sendPasswordReset(String email) async {
    // Pinning the action settings so the email link is predictable:
    // Firebase hosts the reset form itself at
    //   https://wardly-24081996.firebaseapp.com/__/auth/action?...
    // and after the user enters a new password, redirects them to the
    // `url` below. The url just has to be on the project's authorised
    // domains list (the firebaseapp.com domain is always whitelisted).
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
      actionCodeSettings: ActionCodeSettings(
        url: 'https://wardly-24081996.firebaseapp.com',
        handleCodeInApp: false,
        androidPackageName: 'com.wardly.app',
        androidInstallApp: false,
        androidMinimumVersion: '1',
      ),
    );
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarEmoji,
    String? specialty,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (avatarEmoji != null) updates['avatarEmoji'] = avatarEmoji;
    if (specialty != null) updates['specialty'] = specialty;
    if (updates.isEmpty) return;
    await _users.doc(user.uid).update(updates);
    if (name != null) {
      await user.updateDisplayName(name);
    }
  }

  Stream<AppUser?> userStream(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromFirestore(doc) : null,
        );
  }
}
