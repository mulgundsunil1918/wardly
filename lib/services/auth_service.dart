import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../utils/app_constants.dart';

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
        await _users.doc(user.uid).set({
          'name': user.displayName ?? (user.email ?? 'User').split('@').first,
          'email': user.email ?? '',
          'role': 'doctor',
          'wardId': '',
          'wardIds': <String>[],
          'avatarUrl': user.photoURL,
          'createdAt': Timestamp.fromDate(now),
        });
      }
      final fresh = await _users.doc(user.uid).get();
      return AppUser.fromFirestore(fresh);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
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
