import 'package:flutter/material.dart';
import '../../core/study_module.dart';
import 'models/countdown_item.dart';
import 'services/countdown_service.dart';

class CountdownModule extends StudyModule {
  @override
  String get id => 'countdown';
  @override
  String get title => 'Đếm ngược Sự kiện';
  @override
  IconData get icon => Icons.event_available_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) => const CountdownScreen();
}

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  List<CountdownItem> _items = [];
  bool _isLoading = true;

  final List<String> _categories = ['Thi cử', 'CTF / Pentest', 'Deadline', 'Khác'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loaded = await CountdownService.loadCountdowns();
    setState(() {
      _items = loaded;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await CountdownService.saveCountdowns(_items);
    setState(() {});
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedCategory = 'Thi cử';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm sự kiện đếm ngược'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sự kiện (VD: Thi Giữa Kỳ I, Giải CTF Pico2026)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Ngày diễn ra: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Chọn ngày'),
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                _items.add(
                  CountdownItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    targetDate: selectedDate,
                    category: selectedCategory,
                  ),
                );
                _saveData();
                Navigator.pop(ctx);
              },
              child: const Text('Thêm sự kiện'),
            )
          ],
        ),
      ),
    );
  }

  void _deleteItem(CountdownItem item) {
    setState(() {
      _items.removeWhere((i) => i.id == item.id);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    _items.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đếm ngược Kỳ thi & Sự kiện', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm sự kiện'),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Chưa có sự kiện nào. Hãy thêm mốc thời gian kỳ thi hoặc giải đấu!'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      mainAxisExtent: 180,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (ctx, idx) => _buildCountdownCard(_items[idx]),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildCountdownCard(CountdownItem item) {
    final days = item.daysLeft;
    final isPast = days < 0;

    Color badgeColor = Colors.blueAccent;
    if (item.category == 'CTF / Pentest') badgeColor = Colors.purpleAccent;
    if (item.category == 'Deadline') badgeColor = Colors.orangeAccent;

    return Card(
      color: const Color(0xFF313244),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(item.category, style: const TextStyle(fontSize: 11)),
                  backgroundColor: badgeColor.withOpacity(0.2),
                  side: BorderSide(color: badgeColor),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  onPressed: () => _deleteItem(item),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.targetDate.day}/${item.targetDate.month}/${item.targetDate.year}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
                Text(
                  isPast ? 'Đã diễn ra' : 'Còn $days ngày',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isPast
                        ? Colors.grey
                        : (days <= 3 ? Colors.redAccent : (days <= 7 ? Colors.amberAccent : Colors.greenAccent)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}