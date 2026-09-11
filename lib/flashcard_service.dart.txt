import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashcardsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _flashcardsRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('flashcards');
  }

  CollectionReference? get _historyRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('flashcard_history');
  }

  // Stream danh sách bộ thẻ
  Stream<QuerySnapshot>? getDeckStream() {
    return _flashcardsRef?.orderBy('createdAt', descending: true).snapshots();
  }

  // Thêm bộ thẻ mới
  Future<DocumentReference?> addDeck(Map<String, dynamic> deckData) async {
    if (_flashcardsRef == null) return null;
    return await _flashcardsRef!.add({
      ...deckData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Thêm/Cập nhật thẻ vào bộ có sẵn
  Future<void> appendCardsToDeck(String deckId, List<Map<String, String>> newCards) async {
    if (_flashcardsRef == null) return;
    final docRef = _flashcardsRef!.doc(deckId);
    final doc = await docRef.get();
    if (doc.exists) {
      final existingCards = List<Map<String, dynamic>>.from(doc.get('cards') ?? []);
      existingCards.addAll(newCards);
      await docRef.update({'cards': existingCards});
    }
  }

  // Xóa bộ thẻ
  Future<void> deleteDeck(String deckId) async {
    if (_flashcardsRef == null) return;
    await _flashcardsRef!.doc(deckId).delete();
  }

  // Lưu lịch sử làm bài Test lên Cloud
  Future<void> saveTestHistory(Map<String, dynamic> historyData) async {
    if (_historyRef == null) return;
    await _historyRef!.add({
      ...historyData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Parser dữ liệu từ file/chuỗi TXT định dạng "Câu hỏi : Đáp án"
  static Map<String, dynamic> parseTxtContent(String title, String content) {
    List<Map<String, String>> cards = parseTxtOnlyCards(content);
    return {
      'title': title,
      'cards': cards,
    };
  }

  static List<Map<String, String>> parseTxtOnlyCards(String content) {
    List<Map<String, String>> cards = [];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        final q = parts[0].trim();
        final a = parts.sublist(1).join(':').trim();
        if (q.isNotEmpty && a.isNotEmpty) {
          cards.add({'question': q, 'answer': a});
        }
      }
    }
    return cards;
  }
}

typedef FlashcardService = FlashcardsService;