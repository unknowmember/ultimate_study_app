import 'package:flutter/material.dart';
import '../../core/study_module.dart';
import 'services/pomodoro_service.dart';

class PomodoroModule extends StudyModule {
  @override
  String get id => 'pomodoro';
  @override
  String get title => 'Pomodoro Timer';
  @override
  IconData get icon => Icons.timer_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) => const PomodoroScreen();
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final _service = PomodoroService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  // Dialog Tùy chỉnh Thời Gian
  void _showSettingsDialog() {
    final workController = TextEditingController(text: (_service.workDuration ~/ 60).toString());
    final shortController = TextEditingController(text: (_service.shortBreakDuration ~/ 60).toString());
    final longController = TextEditingController(text: (_service.longBreakDuration ~/ 60).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tùy chỉnh thời gian (Phút)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: workController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Thời gian Tập trung (Work)')),
            TextField(controller: shortController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nghỉ ngắn (Short Break)')),
            TextField(controller: longController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nghỉ dài (Long Break)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final w = int.tryParse(workController.text) ?? 25;
              final s = int.tryParse(shortController.text) ?? 5;
              final l = int.tryParse(longController.text) ?? 15;
              _service.updateDurations(workMin: w, shortMin: s, longMin: l);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = Colors.redAccent;
    if (_service.currentMode == PomodoroMode.shortBreak) themeColor = Colors.tealAccent;
    if (_service.currentMode == PomodoroMode.longBreak) themeColor = Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pomodoro Timer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsDialog),
            ],
          ),
          const SizedBox(height: 20),

          // Chuyển chế độ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Tập trung'),
                selected: _service.currentMode == PomodoroMode.work,
                onSelected: (_) => _service.switchMode(PomodoroMode.work),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Nghỉ ngắn'),
                selected: _service.currentMode == PomodoroMode.shortBreak,
                onSelected: (_) => _service.switchMode(PomodoroMode.shortBreak),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Nghỉ dài'),
                selected: _service.currentMode == PomodoroMode.longBreak,
                onSelected: (_) => _service.switchMode(PomodoroMode.longBreak),
              ),
            ],
          ),

          const Spacer(),

          // Đồng hồ bấm giờ dạng Vòng tròn
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: _service.progress,
                  strokeWidth: 12,
                  color: themeColor,
                  backgroundColor: Colors.white12,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_service.formattedTime, style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Chu kỳ đã xong: ${_service.completedSessions}', style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Nút điều khiển
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  backgroundColor: themeColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: _service.isRunning ? _service.pauseTimer : _service.startTimer,
                icon: Icon(_service.isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_service.isRunning ? 'TẠM DỪNG' : 'BẮT ĐẦU', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: _service.resetTimer,
                icon: const Icon(Icons.refresh),
              )
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}