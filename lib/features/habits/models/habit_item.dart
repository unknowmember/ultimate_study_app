class HabitItem {
  final String id;
  String title;
  List<String> completedDates; // Format: YYYY-MM-DD
  DateTime createdAt;

  HabitItem({
    required this.id,
    required this.title,
    List<String>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Tính chuỗi streak hiện tại
  int get currentStreak {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Nếu hôm nay chưa tích thì kiểm tra xem hôm qua có tích không
    String todayStr = _formatDate(checkDate);
    if (!completedDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (completedDates.contains(_formatDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completedDates': completedDates,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HabitItem.fromJson(Map<String, dynamic> json) => HabitItem(
        id: json['id'],
        title: json['title'],
        completedDates: List<String>.from(json['completedDates'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
      );
}