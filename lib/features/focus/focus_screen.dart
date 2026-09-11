import 'package:flutter/material.dart';
import 'focus_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final _focusService = FocusService();
  
  int _selectedHours = 0;
  int _selectedMinutes = 25;

  @override
  void initState() {
    super.initState();
    _focusService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _focusService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  // Mở Dialog chọn thời gian chính xác
  Future<void> _showCustomTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHours, minute: _selectedMinutes),
      helpText: 'CHỌN THỜI GIAN TẬP TRUNG (GIỜ : PHÚT)',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHours = picked.hour;
        _selectedMinutes = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = FocusService.isFocusActive;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.lock : Icons.timer_outlined,
                  size: 64,
                  color: isActive ? Colors.redAccent : Colors.indigoAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  isActive ? 'ĐANG TRONG CHẾ ĐỘ TẬP TRUNG' : 'CẤU HÌNH THỜI GIAN TẬP TRUNG',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isActive
                      ? 'Toàn bộ phím chuyển App (Alt+Tab, Windows) đã bị khóa.'
                      : 'Tùy chỉnh thời gian mong muốn và bắt đầu.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 36),

                // --- TRẠNG THÁI 1: ĐANG TẬP TRUNG (HIỂN THỊ ĐỒNG HỒ ĐẾM NGƯỢC VÒNG TRÒN) ---
                if (isActive) ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: CircularProgressIndicator(
                          value: _focusService.progress,
                          strokeWidth: 14,
                          color: Colors.redAccent,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _focusService.formattedTime,
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Thời gian còn lại',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] 
                
                // --- TRẠNG THÁI 2: CHƯA BẬT (BỘ ĐỒNG HỒ CHỌN THỜI GIAN TÙY CHỈNH) ---
                else ...[
                  // Khung hiển thị thời gian đã chọn
                  InkWell(
                    onTap: _showCustomTimePicker,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2B3D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.indigoAccent.withOpacity(0.5), width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_selectedHours.toString().padLeft(2, '0')}h : ${_selectedMinutes.toString().padLeft(2, '0')}m',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigoAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.edit_calendar, color: Colors.indigoAccent, size: 28),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Bấm vào đây để chỉnh đồng hồ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút tăng/giảm nhanh phút
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedMinutes >= 5) {
                              _selectedMinutes -= 5;
                            } else if (_selectedHours > 0) {
                              _selectedHours--;
                              _selectedMinutes = 55;
                            }
                          });
                        },
                        child: const Text('- 5 Phút'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedMinutes += 5;
                            if (_selectedMinutes >= 60) {
                              _selectedHours += _selectedMinutes ~/ 60;
                              _selectedMinutes %= 60;
                            }
                          });
                        },
                        child: const Text('+ 5 Phút'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedMinutes += 15;
                            if (_selectedMinutes >= 60) {
                              _selectedHours += _selectedMinutes ~/ 60;
                              _selectedMinutes %= 60;
                            }
                          });
                        },
                        child: const Text('+ 15 Phút'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Nút khởi chạy
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_selectedHours == 0 && _selectedMinutes == 0)
                        ? null
                        : () {
                            final duration = Duration(hours: _selectedHours, minutes: _selectedMinutes);
                            _focusService.startFocusMode(duration);
                          },
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text(
                      'BẮT ĐẦU TẬP TRUNG',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}