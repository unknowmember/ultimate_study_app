import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/countdown_item.dart';

class CountdownService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference? get _userCol {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('countdowns');
  }

  static Future<List<CountdownItem>> loadCountdowns() async {
    final col = _userCol;
    if (col == null) return [];

    try {
      final snapshot = await col.get();
      return snapshot.docs.map((doc) {
        return CountdownItem.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> saveCountdowns(List<CountdownItem> items) async {
    final col = _userCol;
    if (col == null) return false;

    try {
      final batch = _db.batch();
      final oldDocs = await col.get();
      for (var doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }

      for (var item in items) {
        batch.set(col.doc(item.id), item.toJson());
      }

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }
}