import 'package:flutter/material.dart';
import '../../core/study_module.dart';
import 'models/habit_item.dart';
import 'services/habit_service.dart';

class HabitModule extends StudyModule {
  @override
  String get id => 'habits';
  @override
  String get title => 'Thói quen & Streak';
  @override
  IconData get icon => Icons.local_fire_department_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) => const HabitScreen();
}

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  List<HabitItem> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loaded = await HabitService.loadHabits();
    setState(() {
      _habits = loaded;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await HabitService.saveHabits(_habits);
    setState(() {});
  }

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  void _toggleHabitToday(HabitItem habit) {
    final today = _getTodayString();
    if (habit.completedDates.contains(today)) {
      habit.completedDates.remove(today);
    } else {
      habit.completedDates.add(today);
    }
    _saveData();
  }

  void _showAddHabitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm thói quen mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên thói quen (VD: Giải 1 bài CTF, Học 15p Tiếng Anh)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              _habits.add(HabitItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: controller.text.trim(),
              ));
              _saveData();
              Navigator.pop(ctx);
            },
            child: const Text('Tạo thói quen'),
          )
        ],
      ),
    );
  }

  void _deleteHabit(HabitItem habit) {
    setState(() {
      _habits.removeWhere((h) => h.id == habit.id);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final today = _getTodayString();
    final completedTodayCount = _habits.where((h) => h.completedDates.contains(today)).length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rèn luyện Thói quen & Streak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Hôm nay đã hoàn thành $completedTodayCount / ${_habits.length} mục tiêu',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddHabitDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm thói quen'),
              )
            ],
          ),
          const SizedBox(height: 16),

          // GitHub-style Heatmap (11 tuần x 7 ngày)
          _buildOverallHeatmapCard(),

          const SizedBox(height: 16),
          const Text('Danh sách mục tiêu hàng ngày', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Expanded(
            child: _habits.isEmpty
                ? const Center(child: Text('Chưa có thói quen nào. Hãy bấm "Thêm thói quen" để bắt đầu!'))
                : ListView.builder(
                    itemCount: _habits.length,
                    itemBuilder: (ctx, idx) {
                      final habit = _habits[idx];
                      final isDoneToday = habit.completedDates.contains(today);
                      return Card(
                        color: const Color(0xFF313244),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Checkbox(
                            value: isDoneToday,
                            activeColor: Colors.greenAccent,
                            checkColor: Colors.black,
                            onChanged: (_) => _toggleHabitToday(habit),
                          ),
                          title: Text(
                            habit.title,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: isDoneToday ? TextDecoration.lineThrough : TextDecoration.none,
                              color: isDoneToday ? Colors.white54 : Colors.white,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.local_fire_department, size: 16, color: Colors.orangeAccent),
                              const SizedBox(width: 4),
                              Text(
                                '${habit.currentStreak} ngày liên tiếp',
                                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteHabit(habit),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  // Widget Heatmap dạng 11 Cột (Tuần) x 7 Hàng (Ngày)
  Widget _buildOverallHeatmapCard() {
    final now = DateTime.now();

    final Map<String, int> dailyActivity = {};
    for (var habit in _habits) {
      for (var dateStr in habit.completedDates) {
        dailyActivity[dateStr] = (dailyActivity[dateStr] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_on, size: 18, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              const Text('Biểu đồ chăm chỉ (11 tuần gần nhất)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              _buildHeatmapLegend(),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(11, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final dayOffset = (10 - weekIndex) * 7 + (6 - dayIndex);
                      final date = now.subtract(Duration(days: dayOffset));
                      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                      final count = dailyActivity[dateStr] ?? 0;

                      Color boxColor = const Color(0xFF313244);
                      if (count == 1) boxColor = Colors.green.shade900;
                      if (count == 2) boxColor = Colors.green.shade700;
                      if (count >= 3) boxColor = Colors.greenAccent;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Tooltip(
                          message: '$dateStr: $count mục tiêu',
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: boxColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      children: [
        const Text('Ít', style: TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(width: 4),
        Container(width: 10, height: 10, color: const Color(0xFF313244)),
        const SizedBox(width: 2),
        Container(width: 10, height: 10, color: Colors.green.shade900),
        const SizedBox(width: 2),
        Container(width: 10, height: 10, color: Colors.green.shade700),
        const SizedBox(width: 2),
        Container(width: 10, height: 10, color: Colors.greenAccent),
        const SizedBox(width: 4),
        const Text('Nhiều', style: TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}