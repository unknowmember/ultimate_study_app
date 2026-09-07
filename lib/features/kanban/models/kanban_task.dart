import 'package:flutter/material.dart';

// Định nghĩa độ quan trọng
enum TaskPriority {
  notImportant,   // Không quan trọng (không có thời hạn)
  normal,         // Quan trọng bình thường (có thời hạn, cho phép quá hạn)
  superImportant, // Siêu quan trọng (bắt buộc đúng hạn, có thông báo)
}

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.notImportant:
        return 'Không quan trọng';
      case TaskPriority.normal:
        return 'Quan trọng bình thường';
      case TaskPriority.superImportant:
        return 'Siêu quan trọng';
    }
  }

  String get code {
    switch (this) {
      case TaskPriority.notImportant:
        return 'not_important';
      case TaskPriority.normal:
        return 'normal';
      case TaskPriority.superImportant:
        return 'super_important';
    }
  }

  static TaskPriority fromCode(String code) {
    switch (code) {
      case 'super_important':
        return TaskPriority.superImportant;
      case 'normal':
        return TaskPriority.normal;
      case 'not_important':
      default:
        return TaskPriority.notImportant;
    }
  }
}

class KanbanTask {
  final String id;
  String title;
  String description;
  String zone; // 'main' (Kanban chính) hoặc 'sub' (Kanban phụ)
  String status; // ID/Tên trạng thái (VD: 'todo', 'doing', 'done' hoặc custom status)
  TaskPriority priority;
  DateTime? dueDate;
  DateTime? createdAt;

  KanbanTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.zone,
    required this.status,
    this.priority = TaskPriority.normal,
    this.dueDate,
    this.createdAt,
  });

  // Kiểm tra trạng thái hạn chót để hiển thị màu cảnh báo
  Color get deadlineColor {
    if (priority == TaskPriority.notImportant || dueDate == null) {
      return Colors.grey; // Không áp dụng cảnh báo
    }

    final now = DateTime.now();
    if (dueDate!.isBefore(now)) {
      return Colors.red; // 🔴 Đã quá thời hạn
    }

    final difference = dueDate!.difference(now);
    if (difference.inHours <= 24) {
      return Colors.amber.shade700; // 🟡 Sắp quá thời hạn (trong 24 giờ)
    }

    return Colors.green; // 🟢 Chưa quá thời hạn
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'zone': zone,
        'status': status,
        'priority': priority.code,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

  factory KanbanTask.fromJson(Map<String, dynamic> json, String docId) => KanbanTask(
        id: docId,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        zone: json['zone'] ?? 'main',
        status: json['status'] ?? 'todo',
        priority: TaskPriorityExtension.fromCode(json['priority'] ?? 'normal'),
        dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}