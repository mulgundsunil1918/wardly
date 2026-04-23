import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import '../utils/app_constants.dart';

class PatientService {
  final FirebaseFirestore _firestore;

  PatientService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _patients =>
      _firestore.collection(AppConstants.patientsCollection);

  Stream<List<Patient>> getAllActivePatients() {
    return _patients
        .where('isActive', isEqualTo: true)
        .orderBy('admittedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Patient.fromFirestore).toList());
  }

  Stream<List<Patient>> getPatientsByWard(String wardId) {
    return _patients
        .where('wardId', isEqualTo: wardId)
        .where('isActive', isEqualTo: true)
        .orderBy('admittedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Patient.fromFirestore).toList());
  }

  Future<Patient?> getPatient(String patientId) async {
    final doc = await _patients.doc(patientId).get();
    if (!doc.exists) return null;
    return Patient.fromFirestore(doc);
  }

  Future<String> addPatient(Patient patient) async {
    final ref = await _patients.add(patient.toMap());
    return ref.id;
  }

  Future<void> updatePatient(Patient patient) async {
    await _patients.doc(patient.id).update(patient.toMap());
  }

  Future<void> dischargePatient(String patientId) async {
    await _patients.doc(patientId).update({'isActive': false});
  }

  Future<void> deletePatient(String patientId) async {
    await _patients.doc(patientId).delete();
  }

  Stream<int> getPatientCount(String wardId) {
    return _patients
        .where('wardId', isEqualTo: wardId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
