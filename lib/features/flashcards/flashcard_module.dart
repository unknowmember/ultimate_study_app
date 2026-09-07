import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/flashcard_service.dart';
import '../../core/study_module.dart';

class FlashcardModule implements StudyModule {
  @override
  String get id => 'flashcards';

  @override
  String get title => 'Flashcards';

  @override
  IconData get icon => Icons.style_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) {
    return const FlashcardDeckManagerScreen();
  }
}

class FlashcardDeckManagerScreen extends StatefulWidget {
  const FlashcardDeckManagerScreen({super.key});

  @override
  State<FlashcardDeckManagerScreen> createState() => _FlashcardDeckManagerScreenState();
}

class _FlashcardDeckManagerScreenState extends State<FlashcardDeckManagerScreen> {
  final FlashcardsService _service = FlashcardsService();

  // Dialog Xóa bộ thẻ
  void _confirmDeleteDeck(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa bộ thẻ "$title" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteDeck(id);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog Tạo bộ thẻ mới (Thủ công / TXT)
 // Dialog Tạo bộ thẻ mới chuẩn UI yêu cầu
  void _showCreateDeckDialog() {
    final titleController = TextEditingController();
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final txtController = TextEditingController();

    // Danh sách lưu tạm các thẻ thêm thủ công
    final List<Map<String, String>> manualCards = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tạo bộ Flashcard mới'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Tên bộ thẻ
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên bộ thẻ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    // 2. Khu vực nhập từng thẻ (Box Câu hỏi + Box Đáp án + Nút + Thêm)
                    const Text('1. Thêm từng thẻ thủ công:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Câu hỏi',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: answerController,
                      decoration: const InputDecoration(
                        labelText: 'Câu trả lời',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('+ Thêm thẻ'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900),
                        onPressed: () {
                          final q = questionController.text.trim();
                          final a = answerController.text.trim();
                          if (q.isNotEmpty && a.isNotEmpty) {
                            setDialogState(() {
                              manualCards.add({'question': q, 'answer': a});
                              questionController.clear();
                              answerController.clear();
                            });
                          }
                        },
                      ),
                    ),

                    // Hiển thị danh sách thẻ thủ công đã thêm
                    if (manualCards.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Đã thêm ${manualCards.length} thẻ thủ công', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                      // Thay thế đoạn Container bị lỗi bằng đoạn này:
Container(
  constraints: const BoxConstraints(maxHeight: 100), // Đã sửa: dùng constraints thay vì maxHeight
  margin: const EdgeInsets.only(top: 4),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade300), 
    borderRadius: BorderRadius.circular(4),
  ),
  child: ListView.builder(
    shrinkWrap: true,
    itemCount: manualCards.length,
    itemBuilder: (context, index) {
      return ListTile(
        dense: true,
        title: Text(manualCards[index]['question']!, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(manualCards[index]['answer']!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16, color: Colors.red),
          onPressed: () {
            setDialogState(() {
              manualCards.removeAt(index);
            });
          },
        ),
      );
    },
  ),
),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),

                    // 3. Khu vực nhập TXT thủ công
                    const Text('2. Hoặc nhập danh sách từ file TXT:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: txtController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Định dạng:\nCâu hỏi 1 : Đáp án 1\nCâu hỏi 2 : Đáp án 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  // Parse phần TXT
                  final txtCards = FlashcardsService.parseTxtOnlyCards(txtController.text);

                  // Gộp thẻ thủ công + thẻ TXT
                  final allCards = [...manualCards, ...txtCards];

                  if (allCards.isNotEmpty) {
                    await _service.addDeck({
                      'title': title,
                      'cards': allCards,
                    });
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Tạo bộ thẻ'),
              ),
            ],
          );
        },
      ),
    );
  }
  // Dialog Nhập bổ sung thẻ từ TXT vào bộ sẵn có
  // Dialog Nhập bổ sung thẻ vào bộ sẵn có (UI y hệt khi tạo mới)
  void _showAppendCardsDialog(String deckId, String deckTitle) {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final txtController = TextEditingController();

    // Danh sách lưu tạm các thẻ thêm thủ công
    final List<Map<String, String>> manualCards = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Thêm thẻ vào "$deckTitle"'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Khu vực nhập từng thẻ thủ công
                    const Text('1. Thêm từng thẻ thủ công:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Câu hỏi',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: answerController,
                      decoration: const InputDecoration(
                        labelText: 'Câu trả lời',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('+ Thêm thẻ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade900,
                        ),
                        onPressed: () {
                          final q = questionController.text.trim();
                          final a = answerController.text.trim();
                          if (q.isNotEmpty && a.isNotEmpty) {
                            setDialogState(() {
                              manualCards.add({'question': q, 'answer': a});
                              questionController.clear();
                              answerController.clear();
                            });
                          }
                        },
                      ),
                    ),

                    // Hiển thị danh sách thẻ thủ công đã thêm
                    if (manualCards.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Đã thêm ${manualCards.length} thẻ thủ công',
                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: manualCards.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              title: Text(manualCards[index]['question']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(manualCards[index]['answer']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    manualCards.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),

                    // 2. Khu vực nhập TXT thủ công
                    const Text('2. Hoặc nhập danh sách từ file TXT:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: txtController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Định dạng:\nCâu hỏi 1 : Đáp án 1\nCâu hỏi 2 : Đáp án 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  // Parse phần TXT
                  final txtCards = FlashcardsService.parseTxtOnlyCards(txtController.text);

                  // Gộp thẻ thủ công + thẻ TXT
                  final allCards = [...manualCards, ...txtCards];

                  if (allCards.isNotEmpty) {
                    await _service.appendCardsToDeck(deckId, allCards);
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Bổ sung thẻ'),
              ),
            ],
          );
        },
      ),
    );
  }
  // Modal chọn Chế độ: Học hoặc Test
  void _openDeckModeSelection(Map<String, dynamic> deckData, String deckId) {
    final List cards = deckData['cards'] ?? [];
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bộ thẻ này chưa có câu hỏi nào! Hãy thêm thẻ trước.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(deckData['title'] ?? 'Bộ thẻ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${cards.length} thẻ khả dụng', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.style, color: Colors.blue, size: 30),
              title: const Text('Chế độ Học (Study)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Lật thẻ ghi nhớ, có tùy chọn tự động chuyển thẻ'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FlashcardStudyScreen(cards: cards, title: deckData['title'] ?? '')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.orange, size: 30),
              title: const Text('Chế độ Luyện tập / Test', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Thi Trắc nghiệm hoặc Tự luận, chấm điểm & lưu lịch sử'),
              onTap: () {
                Navigator.pop(ctx);
                _showTestSetupDialog(deckData, deckId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Cấu hình bài Test
  void _showTestSetupDialog(Map<String, dynamic> deckData, String deckId) {
    final List cards = deckData['cards'] ?? [];
    int numQuestions = cards.length;
    bool isMultipleChoice = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cấu hình bài Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Số câu hỏi: '),
                  DropdownButton<int>(
                    value: numQuestions,
                    items: List.generate(cards.length, (i) => i + 1)
                        .map((val) => DropdownMenuItem(value: val, child: Text('$val câu')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => numQuestions = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RadioListTile<bool>(
                title: const Text('Trắc nghiệm (Multiple Choice)'),
                value: true,
                groupValue: isMultipleChoice,
                onChanged: (val) => setDialogState(() => isMultipleChoice = val!),
              ),
              RadioListTile<bool>(
                title: const Text('Tự luận (Text Input)'),
                value: false,
                groupValue: isMultipleChoice,
                onChanged: (val) => setDialogState(() => isMultipleChoice = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlashcardTestScreen(
                      deckId: deckId,
                      deckTitle: deckData['title'] ?? '',
                      allCards: cards,
                      numQuestions: numQuestions,
                      isMultipleChoice: isMultipleChoice,
                    ),
                  ),
                );
              },
              child: const Text('Bắt đầu Test'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Flashcards')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getDeckStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có bộ thẻ nào. Bấm nút + để tạo mới!'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final cards = (data['cards'] as List?) ?? [];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(data['title'] ?? 'Bộ thẻ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${cards.length} thẻ'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        tooltip: 'Bổ sung thẻ TXT',
                        onPressed: () => _showAppendCardsDialog(doc.id, data['title'] ?? ''),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Xóa bộ thẻ',
                        onPressed: () => _confirmDeleteDeck(doc.id, data['title'] ?? ''),
                      ),
                    ],
                  ),
                  onTap: () => _openDeckModeSelection(data, doc.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDeckDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH CHẾ ĐỘ HỌC (STUDY MODE)
// ==========================================
class FlashcardStudyScreen extends StatefulWidget {
  final List cards;
  final String title;

  const FlashcardStudyScreen({super.key, required this.cards, required this.title});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int currentIndex = 0;
  bool isFlipped = false;
  bool autoAdvance = false;
  Timer? _autoTimer;

  void _flipCard() {
    setState(() {
      isFlipped = !isFlipped;
    });

    if (isFlipped && autoAdvance) {
      _autoTimer?.cancel();
      _autoTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) _nextCard();
      });
    }
  }

  void _nextCard() {
    _autoTimer?.cancel();
    if (currentIndex < widget.cards.length - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
      });
    }
  }

  void _prevCard() {
    _autoTimer?.cancel();
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isFlipped = false;
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = widget.cards[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Row(
            children: [
              const Text('Tự động chuyển (1.5s)', style: TextStyle(fontSize: 12)),
              Switch(
                value: autoAdvance,
                onChanged: (val) => setState(() => autoAdvance = val),
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            LinearProgressIndicator(value: (currentIndex + 1) / widget.cards.length),
            const SizedBox(height: 10),
            Text('Thẻ ${currentIndex + 1}/${widget.cards.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: _flipCard,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: isFlipped ? Colors.blue.shade50 : Colors.indigo.shade500,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isFlipped ? 'ĐÁP ÁN' : 'CÂU HỎI',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFlipped ? Colors.blue : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFlipped ? (currentCard['answer'] ?? '') : (currentCard['question'] ?? ''),
                      style: TextStyle(
                        fontSize: 22,
                        color: isFlipped ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: currentIndex > 0 ? _prevCard : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Trước'),
                ),
                ElevatedButton.icon(
                  onPressed: currentIndex < widget.cards.length - 1 ? _nextCard : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tiếp'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH BÀI TEST (TEST MODE)
// ==========================================
class FlashcardTestScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;
  final List allCards;
  final int numQuestions;
  final bool isMultipleChoice;

  const FlashcardTestScreen({
    super.key,
    required this.deckId,
    required this.deckTitle,
    required this.allCards,
    required this.numQuestions,
    required this.isMultipleChoice,
  });

  @override
  State<FlashcardTestScreen> createState() => _FlashcardTestScreenState();
}

class _FlashcardTestScreenState extends State<FlashcardTestScreen> {
  late List testQuestions;
  int currentIndex = 0;
  int correctCount = 0;
  List<Map<String, dynamic>> wrongCards = [];
  final textController = TextEditingController();

  List<String> currentOptions = [];
  String? selectedOption;

  @override
  void initState() {
    super.initState();
    final shuffled = List.from(widget.allCards)..shuffle();
    testQuestions = shuffled.take(widget.numQuestions).toList();
    if (widget.isMultipleChoice) {
      _generateOptions();
    }
  }

  void _generateOptions() {
    final currentAnswer = testQuestions[currentIndex]['answer'] ?? '';
    Set<String> options = {currentAnswer};

    final random = Random();
    while (options.length < 4 && options.length < widget.allCards.length) {
      final randomCard = widget.allCards[random.nextInt(widget.allCards.length)];
      options.add(randomCard['answer'] ?? '');
    }

    currentOptions = options.toList()..shuffle();
    selectedOption = null;
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _submitAnswer(String answer) {
    final correctAnswer = testQuestions[currentIndex]['answer'] ?? '';
    final isCorrect = widget.isMultipleChoice
        ? answer == correctAnswer
        : _normalize(answer) == _normalize(correctAnswer);

    if (isCorrect) {
      correctCount++;
    } else {
      wrongCards.add({
        'question': testQuestions[currentIndex]['question'],
        'correctAnswer': correctAnswer,
        'userAnswer': answer,
      });
    }

    if (currentIndex < testQuestions.length - 1) {
      setState(() {
        currentIndex++;
        textController.clear();
        if (widget.isMultipleChoice) _generateOptions();
      });
    } else {
      _finishTest();
    }
  }

  void _finishTest() async {
    final historyData = {
      'deckId': widget.deckId,
      'deckTitle': widget.deckTitle,
      'totalQuestions': testQuestions.length,
      'correctCount': correctCount,
      'score': ((correctCount / testQuestions.length) * 100).round(),
      'wrongCards': wrongCards,
    };

    await FlashcardsService().saveTestHistory(historyData);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardTestResultScreen(
            historyData: historyData,
            originalCards: widget.allCards,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = testQuestions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Test: ${widget.deckTitle}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (currentIndex + 1) / testQuestions.length),
            const SizedBox(height: 10),
            Text('Câu ${currentIndex + 1}/${testQuestions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  q['question'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.isMultipleChoice)
              ...currentOptions.map(
                (opt) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => _submitAnswer(opt),
                    child: Text(opt, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              )
            else ...[
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Nhập đáp án của bạn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submitAnswer(textController.text),
                child: const Text('Nộp câu trả lời'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH BÁO CÁO KẾT QUẢ TEST
// ==========================================
class FlashcardTestResultScreen extends StatelessWidget {
  final Map<String, dynamic> historyData;
  final List originalCards;

  const FlashcardTestResultScreen({
    super.key,
    required this.historyData,
    required this.originalCards,
  });

  @override
  Widget build(BuildContext context) {
    final int score = historyData['score'] ?? 0;
    final int correct = historyData['correctCount'] ?? 0;
    final int total = historyData['totalQuestions'] ?? 0;
    final List wrongCards = historyData['wrongCards'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả bài Test')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('$score%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: score >= 70 ? Colors.green : Colors.red)),
            Text('Đúng $correct / $total câu', style: const TextStyle(fontSize: 18)),
            const Divider(height: 30),
            if (wrongCards.isNotEmpty) ...[
              const Text('Danh sách các câu làm sai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: wrongCards.length,
                  itemBuilder: (ctx, idx) {
                    final item = wrongCards[idx];
                    return Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        title: Text(item['question'] ?? ''),
                        subtitle: Text('Đáp án đúng: ${item['correctAnswer']}\nBạn chọn: ${item['userAnswer']}'),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Xuất sắc! Bạn không làm sai câu nào 🎉', style: TextStyle(color: Colors.green, fontSize: 18)),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      ),
    );
  }
}