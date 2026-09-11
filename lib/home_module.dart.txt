import 'package:flutter/material.dart';
import '../../core/study_module.dart';
import '../../core/module_registry.dart';
import '../countdown/models/countdown_item.dart';
import '../countdown/services/countdown_service.dart';

class HomeModule extends StudyModule {
  @override
  String get id => 'home';
  @override
  String get title => 'Trang chủ';
  @override
  IconData get icon => Icons.dashboard_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) {
    return HomeScreen(onNavigate: onNavigate);
  }
}

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CountdownItem> _topCountdowns = [];

  @override
  void initState() {
    super.initState();
    _loadCountdowns();
  }

  Future<void> _loadCountdowns() async {
    final items = await CountdownService.loadCountdowns();
    // Lọc các sự kiện chưa diễn ra (hoặc vừa diễn ra) và sắp xếp ngày gần nhất lên đầu
    items.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    setState(() {
      _topCountdowns = items.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách các module ngoài trang chủ
    final otherModules = ModuleRegistry.modules.where((m) => m.id != 'home').toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Tiêu đề bên trái + Top 3 Countdown bên phải
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ultimate Study Dashboard',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn nhanh công cụ học tập hoặc xem hoạt động gần đây.',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              if (_topCountdowns.isNotEmpty)
                Row(
                  children: _topCountdowns.map((item) => _buildMiniCountdownWidget(item)).toList(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Banner Hoạt động gần nhất
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252636),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade700),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.history, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoạt động gần nhất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Bấm vào đây để mở Flashcards', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () => widget.onNavigate?.call(1),
                )
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Text('Các công cụ học tập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Grid công cụ
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 160,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: otherModules.length,
              itemBuilder: (context, index) {
                final module = otherModules[index];
                final realIndex = ModuleRegistry.modules.indexOf(module);

                return Card(
                  color: const Color(0xFF313244),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => widget.onNavigate?.call(realIndex),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(module.icon, size: 40, color: Colors.cyanAccent),
                          const SizedBox(height: 12),
                          Text(
                            module.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Card đếm ngược thu nhỏ đặt bên phải header
  Widget _buildMiniCountdownWidget(CountdownItem item) {
    final days = item.daysLeft;
    Color statusColor = days <= 3 ? Colors.redAccent : (days <= 7 ? Colors.amberAccent : Colors.greenAccent);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 130),
      decoration: BoxDecoration(
        color: const Color(0xFF313244),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 12, color: statusColor),
              const SizedBox(width: 4),
              Text(
                days < 0 ? 'Đã qua' : '$days ngày nữa',
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}