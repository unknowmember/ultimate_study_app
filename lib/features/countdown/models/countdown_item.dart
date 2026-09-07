class CountdownItem {
  final String id;
  String title;
  DateTime targetDate;
  String category; // Thi cử, CTF/Pentest, Deadline, Khác

  CountdownItem({
    required this.id,
    required this.title,
    required this.targetDate,
    this.category = 'Thi cử',
  });

  int get daysLeft {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    return difference.inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetDate': targetDate.toIso8601String(),
        'category': category,
      };

  factory CountdownItem.fromJson(Map<String, dynamic> json) => CountdownItem(
        id: json['id'],
        title: json['title'],
        targetDate: DateTime.parse(json['targetDate']),
        category: json['category'] ?? 'Thi cử',
      );
}