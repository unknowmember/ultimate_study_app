class NoteItem {
  final String id;
  String title;
  String content;
  String subject; // Toán, Lý, Hóa, Tiếng Anh, Code, Khác
  List<String> tags;
  DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    this.subject = 'Toán',
    List<String>? tags,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'subject': subject,
        'tags': tags,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        subject: json['subject'] ?? 'Toán',
        tags: List<String>.from(json['tags'] ?? []),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}