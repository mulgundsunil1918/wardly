import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import '../models/note_comment.dart';
import '../utils/app_constants.dart';
import 'metrics_service.dart';

class NoteService {
  final FirebaseFirestore _firestore;

  NoteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _firestore.collection(AppConstants.notesCollection);

  Stream<List<Note>> getNotesForWards(List<String> wardIds) {
    if (wardIds.isEmpty) return Stream.value(const []);
    return _notes
        .where('wardId', whereIn: wardIds)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Note.fromFirestore).toList());
  }

  Stream<int> getUnacknowledgedCountForWards(List<String> wardIds) {
    if (wardIds.isEmpty) return Stream.value(0);
    return _notes
        .where('wardId', whereIn: wardIds)
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
    MetricsService.bump('note',
        summary: '${note.authorName} → ${note.patientName}');
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
    MetricsService.bump('ack', summary: '$acknowledgedBy ack\'d a note');
  }

  Future<void> unacknowledgeNote(String noteId) async {
    await _notes.doc(noteId).update({
      'isAcknowledged': false,
      'acknowledgedBy': null,
      'acknowledgedAt': null,
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _notes.doc(noteId).delete();
  }

  CollectionReference<Map<String, dynamic>> _commentsRef(String noteId) =>
      _notes.doc(noteId).collection('comments');

  Stream<List<NoteComment>> commentsStream(String noteId) {
    return _commentsRef(noteId)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(NoteComment.fromFirestore).toList());
  }

  Future<void> addComment(String noteId, NoteComment comment) async {
    await _commentsRef(noteId).add(comment.toMap());
    MetricsService.bump('comment',
        summary: '${comment.authorName} replied');
  }

  Future<void> deleteComment(String noteId, String commentId) async {
    await _commentsRef(noteId).doc(commentId).delete();
  }

  Stream<int> getUnacknowledgedCount(String wardId) {
    return _notes
        .where('wardId', isEqualTo: wardId)
        .where('isAcknowledged', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
