import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/kanban_task.dart';

class KanbanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  KanbanService() {
    _initNotifications();
  }

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _tasksRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('kanban_tasks');
  }

  DocumentReference? get _subStatusRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('kanban_settings').doc('sub_statuses');
  }

  // Khởi tạo Notification Plugin
  Future<void> _initNotifications() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _notificationsPlugin.initialize(initSettings);
  }

  // --- TASK OPERATIONS ---

  Stream<List<KanbanTask>> getTaskStream(String zone) {
    if (_tasksRef == null) return Stream.value([]);
    return _tasksRef!
        .where('zone', isEqualTo: zone)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return KanbanTask.fromJson(doc.data() as Map<String, dynamic>, doc.id);
            }).toList());
  }

  Future<void> addTask(KanbanTask task) async {
    if (_tasksRef == null) return;
    final doc = await _tasksRef!.add(task.toJson());
    
    if (task.priority == TaskPriority.superImportant && task.dueDate != null) {
      await scheduleTaskReminders(doc.id, task.title, task.dueDate!);
    }
  }

  Future<void> updateTask(KanbanTask task) async {
    if (_tasksRef == null) return;
    await _tasksRef!.doc(task.id).update(task.toJson());

    if (task.priority == TaskPriority.superImportant && task.dueDate != null) {
      await scheduleTaskReminders(task.id, task.title, task.dueDate!);
    } else {
      await cancelTaskReminders(task.id);
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    if (_tasksRef == null) return;
    await _tasksRef!.doc(taskId).update({'status': newStatus});
  }

  Future<void> deleteTask(String taskId) async {
    if (_tasksRef == null) return;
    await _tasksRef!.doc(taskId).delete();
    await cancelTaskReminders(taskId);
  }

  // --- CUSTOM STATUSES FOR SUB KANBAN ---

  Stream<List<String>> getSubStatusesStream() {
    if (_subStatusRef == null) return Stream.value(['Code', 'Run', 'Debug', 'Fixbug', 'Done']);
    return _subStatusRef!.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return ['Code', 'Run', 'Debug', 'Fixbug', 'Done'];
      }
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['statuses'] ?? ['Code', 'Run', 'Debug', 'Fixbug', 'Done']);
    });
  }

  Future<void> addSubStatus(String newStatus) async {
    if (_subStatusRef == null) return;
    final doc = await _subStatusRef!.get();
    List<String> current = ['Code', 'Run', 'Debug', 'Fixbug', 'Done'];
    if (doc.exists && doc.data() != null) {
      current = List<String>.from((doc.data() as Map<String, dynamic>)['statuses'] ?? current);
    }
    if (!current.contains(newStatus)) {
      current.add(newStatus);
      await _subStatusRef!.set({'statuses': current});
    }
  }

  Future<void> deleteSubStatus(String statusName) async {
    if (_subStatusRef == null) return;
    final doc = await _subStatusRef!.get();
    if (doc.exists && doc.data() != null) {
      List<String> current = List<String>.from((doc.data() as Map<String, dynamic>)['statuses'] ?? []);
      current.remove(statusName);
      await _subStatusRef!.set({'statuses': current});
    }
  }

  // --- NOTIFICATION SCHEDULING (1 ngày, 1 giờ, 15 phút, 5 phút) ---

  Future<void> scheduleTaskReminders(String taskId, String title, DateTime dueDate) async {
    await cancelTaskReminders(taskId);

    // Local notifications qua flutter_local_notifications chạy tối ưu trên Android
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final now = DateTime.now();
    final baseId = taskId.hashCode;

    final reminders = [
      {'minutes': 1440, 'label': '1 ngày', 'offset': 1},
      {'minutes': 60, 'label': '1 giờ', 'offset': 2},
      {'minutes': 15, 'label': '15 phút', 'offset': 3},
      {'minutes': 5, 'label': '5 phút', 'offset': 4},
    ];

    for (var r in reminders) {
      final notificationTime = dueDate.subtract(Duration(minutes: r['minutes'] as int));
      if (notificationTime.isAfter(now)) {
        final notifId = baseId + (r['offset'] as int);
        await _notificationsPlugin.zonedSchedule(
          notifId,
          '⚠️ BÁO ĐỘNG DEADLINE (SIÊU QUAN TRỌNG)',
          'Nhiệm vụ "$title" chỉ còn ${r['label']} là hết hạn!',
          tz.TZDateTime.from(notificationTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'kanban_deadline_channel',
              'Kanban Deadline Alerts',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelTaskReminders(String taskId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final baseId = taskId.hashCode;
    for (int offset = 1; offset <= 4; offset++) {
      await _notificationsPlugin.cancel(baseId + offset);
    }
  }
}