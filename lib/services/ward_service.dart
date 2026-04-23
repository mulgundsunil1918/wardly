import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/ward.dart';
import '../utils/app_constants.dart';

class WardService {
  final FirebaseFirestore _firestore;

  WardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _wards =>
      _firestore.collection(AppConstants.wardsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<List<Ward>> getAllWards() {
    return _wards.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(Ward.fromFirestore).toList(),
        );
  }

  Future<Ward?> getWard(String wardId) async {
    final doc = await _wards.doc(wardId).get();
    if (!doc.exists) return null;
    return Ward.fromFirestore(doc);
  }

  Future<String> addWard(Ward ward) async {
    final ref = await _wards.add(ward.toMap());
    return ref.id;
  }

  Future<void> updateWard(Ward ward) async {
    await _wards.doc(ward.id).update(ward.toMap());
  }

  Stream<List<AppUser>> getWardStaff(String wardId) {
    return _users
        .where('wardId', isEqualTo: wardId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(AppUser.fromFirestore).toList());
  }
}
