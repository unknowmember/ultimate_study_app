class Flashcard {
  final String id;
  final String question;
  final String answer;

  Flashcard({required this.id, required this.question, required this.answer});

  Map<String, dynamic> toJson() => {'id': id, 'question': question, 'answer': answer};

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'],
        question: json['question'],
        answer: json['answer'],
      );
}

class TestResult {
  final String id;
  final DateTime date;
  final int totalQuestions;
  final int correctCount;
  final String mode; // 'trac_nhiem' hoặc 'text'
  final List<String> wrongQuestions; // Danh sách câu sai

  TestResult({
    required this.id,
    required this.date,
    required this.totalQuestions,
    required this.correctCount,
    required this.mode,
    required this.wrongQuestions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'mode': mode,
        'wrongQuestions': wrongQuestions,
      };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        id: json['id'],
        date: DateTime.parse(json['date']),
        totalQuestions: json['totalQuestions'],
        correctCount: json['correctCount'],
        mode: json['mode'],
        wrongQuestions: List<String>.from(json['wrongQuestions']),
      );
}

class FlashcardDeck {
  final String id;
  String title;
  List<Flashcard> cards;
  List<TestResult> history;

  FlashcardDeck({
    required this.id,
    required this.title,
    required this.cards,
    List<TestResult>? history,
  }) : history = history ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cards': cards.map((c) => c.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) => FlashcardDeck(
        id: json['id'],
        title: json['title'],
        cards: (json['cards'] as List).map((c) => Flashcard.fromJson(c)).toList(),
        history: json['history'] != null
            ? (json['history'] as List).map((h) => TestResult.fromJson(h)).toList()
            : [],
      );
}