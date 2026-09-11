import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/study_module.dart';

class QuickToolsModule extends StudyModule {
  @override
  String get id => 'quick_tools';
  @override
  String get title => 'Công cụ tiện ích';
  @override
  IconData get icon => Icons.build_circle_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) => const QuickToolsScreen();
}

class QuickToolsScreen extends StatefulWidget {
  const QuickToolsScreen({super.key});

  @override
  State<QuickToolsScreen> createState() => _QuickToolsScreenState();
}

class _QuickToolsScreenState extends State<QuickToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bộ công cụ tiện ích', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.text_fields), text: 'Xử lý Văn bản'),
              Tab(icon: Icon(Icons.code), text: 'Base64 & URL'),
              Tab(icon: Icon(Icons.calculate_outlined), text: 'Tính điểm TB Môn'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                TextUtilTool(),
                EncodingTool(),
                GradeCalculatorTool(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. TOOL XỬ LÝ VĂN BẢN
// -------------------------------------------------------------
class TextUtilTool extends StatefulWidget {
  const TextUtilTool({super.key});

  @override
  State<TextUtilTool> createState() => _TextUtilToolState();
}

class _TextUtilToolState extends State<TextUtilTool> {
  final _controller = TextEditingController();

  int _wordCount = 0;
  int _charCount = 0;
  int _lineCount = 0;

  void _analyzeText(String text) {
    setState(() {
      _charCount = text.length;
      _lineCount = text.isEmpty ? 0 : text.split('\n').length;
      final words = text.trim().split(RegExp(r'\s+'));
      _wordCount = (text.trim().isEmpty) ? 0 : words.length;
    });
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              _buildStatChip('Số từ', '$_wordCount'),
              const SizedBox(width: 12),
              _buildStatChip('Số ký tự', '$_charCount'),
              const SizedBox(width: 12),
              _buildStatChip('Số dòng', '$_lineCount'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 8,
            onChanged: _analyzeText,
            decoration: const InputDecoration(
              hintText: 'Dán đoạn văn bản hoặc bài luận vào đây...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  _controller.text = _controller.text.toUpperCase();
                  _analyzeText(_controller.text);
                },
                child: const Text('IN HOA'),
              ),
              ElevatedButton(
                onPressed: () {
                  _controller.text = _controller.text.toLowerCase();
                  _analyzeText(_controller.text);
                },
                child: const Text('in thường'),
              ),
              ElevatedButton(
                onPressed: () {
                  _controller.text = _controller.text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
                  _analyzeText(_controller.text);
                },
                child: const Text('Xóa khoảng trắng thừa'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Sao chép'),
                onPressed: () => _copy(_controller.text),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Xóa tất cả'),
                onPressed: () {
                  _controller.clear();
                  _analyzeText('');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF313244),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. TOOL BASE64 & URL ENCODE/DECODE
// -------------------------------------------------------------
class EncodingTool extends StatefulWidget {
  const EncodingTool({super.key});

  @override
  State<EncodingTool> createState() => _EncodingToolState();
}

class _EncodingToolState extends State<EncodingTool> {
  final _inputController = TextEditingController();
  final _outputController = TextEditingController();

  void _encodeBase64() {
    try {
      final bytes = utf8.encode(_inputController.text);
      _outputController.text = base64.encode(bytes);
    } catch (_) {
      _outputController.text = 'Lỗi mã hóa Base64!';
    }
  }

  void _decodeBase64() {
    try {
      final decoded = base64.decode(_inputController.text.trim());
      _outputController.text = utf8.decode(decoded);
    } catch (_) {
      _outputController.text = 'Chuỗi Base64 không hợp lệ!';
    }
  }

  void _encodeUrl() {
    _outputController.text = Uri.encodeComponent(_inputController.text);
  }

  void _decodeUrl() {
    try {
      _outputController.text = Uri.decodeComponent(_inputController.text);
    } catch (_) {
      _outputController.text = 'Chuỗi URL Encode không hợp lệ!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _inputController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Dữ liệu đầu vào (Input)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: _encodeBase64, child: const Text('Base64 Encode')),
              ElevatedButton(onPressed: _decodeBase64, child: const Text('Base64 Decode')),
              ElevatedButton(onPressed: _encodeUrl, child: const Text('URL Encode')),
              ElevatedButton(onPressed: _decodeUrl, child: const Text('URL Decode')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _outputController,
            maxLines: 4,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Kết quả (Output)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _outputController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép kết quả!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. TOOL TÍNH ĐIỂM TRUNG BÌNH MÔN HỌC
// -------------------------------------------------------------
class GradeCalculatorTool extends StatefulWidget {
  const GradeCalculatorTool({super.key});

  @override
  State<GradeCalculatorTool> createState() => _GradeCalculatorToolState();
}

class _GradeCalculatorToolState extends State<GradeCalculatorTool> {
  final _coef1Controller = TextEditingController(); // Điểm HS 1 (miệng, 15p)
  final _coef2Controller = TextEditingController(); // Điểm HS 2 (1 tiết)
  final _coef3Controller = TextEditingController(); // Điểm HS 3 (thi học kỳ)

  double? _averageScore;

  void _calculateAverage() {
    List<double> parseScores(String input) {
      return input
          .split(RegExp(r'[\s,]+'))
          .map((e) => double.tryParse(e.trim()))
          .whereType<double>()
          .toList();
    }

    final scores1 = parseScores(_coef1Controller.text);
    final scores2 = parseScores(_coef2Controller.text);
    final scores3 = parseScores(_coef3Controller.text);

    double sum1 = scores1.fold(0, (a, b) => a + b);
    double sum2 = scores2.fold(0, (a, b) => a + b);
    double sum3 = scores3.fold(0, (a, b) => a + b);

    int count1 = scores1.length;
    int count2 = scores2.length;
    int count3 = scores3.length;

    int totalCoef = count1 * 1 + count2 * 2 + count3 * 3;

    if (totalCoef == 0) {
      setState(() => _averageScore = null);
      return;
    }

    double totalSum = (sum1 * 1) + (sum2 * 2) + (sum3 * 3);
    setState(() {
      _averageScore = double.parse((totalSum / totalCoef).toStringAsFixed(2));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhập danh sách điểm (cách nhau bởi dấu phẩy hoặc khoảng trắng):',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          TextField(
            controller: _coef1Controller,
            decoration: const InputDecoration(
              labelText: 'Điểm Hệ số 1 (Miệng, 15 phút) - VD: 8 9 7.5',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculateAverage(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _coef2Controller,
            decoration: const InputDecoration(
              labelText: 'Điểm Hệ số 2 (1 tiết, giữa kỳ) - VD: 8.5 9',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculateAverage(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _coef3Controller,
            decoration: const InputDecoration(
              labelText: 'Điểm Hệ số 3 (Thi cuối kỳ) - VD: 9.0',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculateAverage(),
          ),
          const SizedBox(height: 20),
          if (_averageScore != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF313244),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurpleAccent),
              ),
              child: Column(
                children: [
                  const Text('Điểm trung bình môn dự kiến', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    '$_averageScore',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _averageScore! >= 8.0
                          ? Colors.greenAccent
                          : (_averageScore! >= 6.5 ? Colors.orangeAccent : Colors.redAccent),
                    ),
                  ),
                  Text(
                    _averageScore! >= 8.0 ? 'Xếp loại: Giỏi / Tốt' : (_averageScore! >= 6.5 ? 'Xếp loại: Khá' : 'Xếp loại: Trung bình / Cần cố gắng'),
                    style: const TextStyle(fontSize: 13, color: Colors.white54),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}