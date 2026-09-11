import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _notesRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('notes');
  }

  Stream<QuerySnapshot>? getNotesStream() {
    return _notesRef?.orderBy('updatedAt', descending: true).snapshots();
  }

  Future<void> addNote({
    required String title,
    required String content,
    required List<String> tags,
    required int colorValue,
  }) async {
    if (_notesRef == null) return;
    await _notesRef!.add({
      'title': title,
      'content': content,
      'tags': tags,
      'colorValue': colorValue,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNote({
    required String docId,
    required String title,
    required String content,
    required List<String> tags,
    required int colorValue,
  }) async {
    if (_notesRef == null) return;
    await _notesRef!.doc(docId).update({
      'title': title,
      'content': content,
      'tags': tags,
      'colorValue': colorValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String docId) async {
    if (_notesRef == null) return;
    await _notesRef!.doc(docId).delete();
  }
}