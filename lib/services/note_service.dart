import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import '../utils/app_constants.dart';

class NoteService {
  final FirebaseFirestore _firestore;

  NoteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _firestore.collection(AppConstants.notesCollection);

  Stream<List<Note>> getAllNotes() {
    return _notes
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Note.fromFirestore).toList());
  }

  Stream<int> getAllUnacknowledgedCount() {
    return _notes
        .where('isAcknowledged', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Note>> getNotesByWard(String wardId) {
    return _notes
        .where('wardId', isEqualTo: wardId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Note.fromFirestore).toList());
  }

  Stream<List<Note>> getNotesByPatient(String patientId) {
    return _notes
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Note.fromFirestore).toList());
  }

  Stream<List<Note>> getUnacknowledgedNotes(String wardId) {
    return _notes
        .where('wardId', isEqualTo: wardId)
        .where('isAcknowledged', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Note.fromFirestore).toList());
  }

  Future<String> addNote(Note note) async {
    final ref = await _notes.add(note.toMap());
    return ref.id;
  }

  Future<void> updateNote(Note note) async {
    await _notes.doc(note.id).update({
      ...note.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> acknowledgeNote(String noteId, String acknowledgedBy) async {
    await _notes.doc(noteId).update({
      'isAcknowledged': true,
      'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _notes.doc(noteId).delete();
  }

  Stream<int> getUnacknowledgedCount(String wardId) {
    return _notes
        .where('wardId', isEqualTo: wardId)
        .where('isAcknowledged', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
