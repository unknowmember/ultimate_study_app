import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/study_module.dart';

// ==========================================
// 1. NOTES SERVICE (FIRESTORE)
// ==========================================
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

// ==========================================
// 2. NOTES MODULE IMPLEMENTATION
// ==========================================
class NotesModule implements StudyModule {
  @override
  String get id => 'notes';

  @override
  String get title => 'Ghi chú';

  @override
  IconData get icon => Icons.note_alt_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) {
    return const NotesScreen();
  }
}

// ==========================================
// 3. MAIN NOTES SCREEN
// ==========================================
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesService _service = NotesService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  static const List<Color> _noteColors = [
    Color(0xFFFFFFFF), // Trắng
    Color(0xFFFFF9C4), // Vàng nhạt
    Color(0xFFDCEDC8), // Xanh lá nhạt
    Color(0xFFE1F5FE), // Xanh dương nhạt
    Color(0xFFF8BBD0), // Hồng nhạt
    Color(0xFFE1BEE7), // Tím nhạt
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNoteEditor({String? docId, Map<String, dynamic>? initialData}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          docId: docId,
          initialData: initialData,
          availableColors: _noteColors,
          onSave: (title, content, tags, colorValue) async {
            if (docId == null) {
              await _service.addNote(
                title: title,
                content: content,
                tags: tags,
                colorValue: colorValue,
              );
            } else {
              await _service.updateNote(
                docId: docId,
                title: title,
                content: content,
                tags: tags,
                colorValue: colorValue,
              );
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: Text('Bạn có chắc muốn xóa "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteNote(docId);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi Chú', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm (Đặt ngoài StreamBuilder giữ Focus)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tiêu đề, nội dung, #tag...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Lấy dữ liệu Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Chưa có ghi chú nào. Bấm + để tạo mới!'),
                  );
                }

                final allDocs = snapshot.data!.docs;

                // Tổng hợp danh sách Tag duy nhất
                final Set<String> uniqueTags = {};
                for (var doc in allDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final tags = List<String>.from(data['tags'] ?? []);
                  uniqueTags.addAll(tags);
                }

                // Lọc dữ liệu theo Từ khóa & Tag được bấm chọn
                final cleanQuery = _searchQuery.replaceAll('#', '').trim().toLowerCase();
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final content = (data['content'] ?? '').toString().toLowerCase();
                  final tags = List<String>.from(data['tags'] ?? []).map((t) => t.toLowerCase()).toList();

                  final matchesQuery = cleanQuery.isEmpty ||
                      title.contains(cleanQuery) ||
                      content.contains(cleanQuery) ||
                      tags.any((t) => t.contains(cleanQuery));

                  final matchesTagFilter = _selectedTag == null || tags.contains(_selectedTag!.toLowerCase());

                  return matchesQuery && matchesTagFilter;
                }).toList();

                return Column(
                  children: [
                    // Thanh lọc Tag nhanh
                    if (uniqueTags.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: _selectedTag == null,
                                selectedColor: Colors.blueAccent,
                                labelStyle: TextStyle(
                                  color: _selectedTag == null ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                side: BorderSide.none,
                                onSelected: (_) => setState(() => _selectedTag = null),
                              ),
                            ),
                            ...uniqueTags.map((tag) {
                              final isSelected = _selectedTag == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('#$tag'),
                                  selected: isSelected,
                                  selectedColor: Colors.blueAccent,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                  side: BorderSide.none,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedTag = isSelected ? null : tag;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Grid hiển thị các Card Ghi chú
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(child: Text('Không tìm thấy ghi chú phù hợp.'))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final title = data['title'] ?? 'Không có tiêu đề';
                                final content = data['content'] ?? '';
                                final tags = List<String>.from(data['tags'] ?? []);
                                final colorValue = data['colorValue'] ?? Colors.white.value;
                                final cardColor = Color(colorValue);

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openNoteEditor(docId: doc.id, initialData: data),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            // Nút Sao chép Note
                                            InkWell(
                                              onTap: () {
                                                final fullText = '$title\n\n$content';
                                                Clipboard.setData(ClipboardData(text: fullText));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Đã sao chép ghi chú vào bộ nhớ tạm!'),
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              child: const Icon(Icons.copy_rounded, size: 16, color: Colors.black54),
                                            ),
                                            const SizedBox(width: 8),
                                            // Nút Xóa Note
                                            InkWell(
                                              onTap: () => _confirmDelete(doc.id, title),
                                              child: const Icon(Icons.close, size: 18, color: Colors.black45),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Text(
                                            content,
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                                          ),
                                        ),
                                        if (tags.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: tags
                                                .map((t) => InkWell(
                                                      onTap: () => setState(() => _selectedTag = t),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.08),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '#$t',
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// 4. NOTE EDITOR SCREEN
// ==========================================
class NoteEditorScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;
  final List<Color> availableColors;
  final Function(String title, String content, List<String> tags, int colorValue) onSave;

  const NoteEditorScreen({
    super.key,
    this.docId,
    this.initialData,
    required this.availableColors,
    required this.onSave,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  late List<String> _tags;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData?['title'] ?? '');
    _contentController = TextEditingController(text: widget.initialData?['content'] ?? '');
    _tagInputController = TextEditingController();
    _tags = List<String>.from(widget.initialData?['tags'] ?? []);

    final savedColor = widget.initialData?['colorValue'];
    _selectedColor = savedColor != null ? Color(savedColor) : widget.availableColors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagInputController.text.trim().replaceAll('#', '');
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputController.clear();
      });
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    widget.onSave(
      title.isEmpty ? 'Ghi chú không tiêu đề' : title,
      content,
      _tags,
      _selectedColor.value,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.black87),
            onPressed: () {
              final fullText = '${_titleController.text}\n\n${_contentController.text}';
              Clipboard.setData(ClipboardData(text: fullText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép nội dung ghi chú!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black87),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // Tiêu đề
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              decoration: const InputDecoration(
                hintText: 'Tiêu đề ghi chú...',
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),

            // Thanh chọn màu pastel
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  const Text('Màu thẻ: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.availableColors.length,
                      itemBuilder: (ctx, idx) {
                        final color = widget.availableColors[idx];
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black87 : Colors.grey.shade400,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black87) : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.black26),

            // Ô thêm Tag
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Thêm thẻ (Tag) ví dụ: Toan, Flutter...',
                      hintStyle: TextStyle(color: Colors.black38),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black87),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  children: _tags
                      .map((t) => Chip(
                            backgroundColor: Colors.grey.shade200,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '#$t',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onDeleted: () => setState(() => _tags.remove(t)),
                            deleteIconColor: Colors.black54,
                          ))
                      .toList(),
                ),
              ),
            const Divider(color: Colors.black26),

            // Ô nội dung ghi chú
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Bắt đầu viết ghi chú ở đây...',
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}