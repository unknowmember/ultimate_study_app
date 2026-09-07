import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/study_module.dart';
import 'models/kanban_task.dart';
import 'services/kanban_service.dart';

// Cấu hình hỗ trợ kéo trượt bằng chuột trên Windows/Desktop
class KanbanScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class KanbanModule implements StudyModule {
  @override
  String get id => 'kanban';

  @override
  String get title => 'Kanban Board';

  @override
  IconData get icon => Icons.view_kanban_outlined;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) {
    return const KanbanBoardScreen();
  }
}

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final KanbanService _service = KanbanService();

  // ScrollController riêng cho từng vùng để cuộn ngang
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _subScrollController = ScrollController();

  // Bật/tắt chế độ chỉnh sửa cho 2 vùng
  bool _isMainEditMode = false;
  bool _isSubEditMode = false;

  // Danh sách cột mặc định của Vùng Chính
  final Map<String, String> _mainStatuses = {
    'todo': 'Chưa làm',
    'doing': 'Đang làm',
    'done': 'Hoàn thành',
  };

  @override
  void dispose() {
    _mainScrollController.dispose();
    _subScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Hub Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: KanbanScrollBehavior(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== VÙNG 1: KANBAN CHÍNH ====================
              _buildZoneHeader(
                title: '📌 KANBAN CHÍNH (Cố định)',
                color: Colors.indigo,
                isEditMode: _isMainEditMode,
                onToggleEdit: () => setState(() => _isMainEditMode = !_isMainEditMode),
                onAddTask: () => _showTaskDialog(zone: 'main', availableStatuses: _mainStatuses.keys.toList()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 400,
                child: StreamBuilder<List<KanbanTask>>(
                  stream: _service.getTaskStream('main'),
                  builder: (context, snapshot) {
                    final tasks = snapshot.data ?? [];
                    return Scrollbar(
                      controller: _mainScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: ListView(
                        controller: _mainScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        children: _mainStatuses.entries.map((entry) {
                          final statusTasks = tasks.where((t) => t.status == entry.key).toList();
                          return _buildKanbanColumn(
                            statusKey: entry.key,
                            statusTitle: entry.value,
                            tasks: statusTasks,
                            zone: 'main',
                            isEditMode: _isMainEditMode,
                            isCustomColumn: false,
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 32, thickness: 2),

              // ==================== VÙNG 2: KANBAN PHỤ ====================
              StreamBuilder<List<String>>(
                stream: _service.getSubStatusesStream(),
                builder: (context, subStatusSnapshot) {
                  final subStatuses = subStatusSnapshot.data ?? ['Code', 'Run', 'Debug', 'Fixbug', 'Done'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildZoneHeader(
                        title: '⚙️ KANBAN PHỤ (Tùy chỉnh)',
                        color: Colors.teal,
                        isEditMode: _isSubEditMode,
                        onToggleEdit: () => setState(() => _isSubEditMode = !_isSubEditMode),
                        onAddTask: () => _showTaskDialog(zone: 'sub', availableStatuses: subStatuses),
                        onAddStatus: () => _showAddStatusDialog(),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 400,
                        child: StreamBuilder<List<KanbanTask>>(
                          stream: _service.getTaskStream('sub'),
                          builder: (context, taskSnapshot) {
                            final tasks = taskSnapshot.data ?? [];
                            return Scrollbar(
                              controller: _subScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView(
                                controller: _subScrollController,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(bottom: 12),
                                children: subStatuses.map((status) {
                                  final statusTasks = tasks.where((t) => t.status == status).toList();
                                  return _buildKanbanColumn(
                                    statusKey: status,
                                    statusTitle: status,
                                    tasks: statusTasks,
                                    zone: 'sub',
                                    isEditMode: _isSubEditMode,
                                    isCustomColumn: true,
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER CỦA MỖI VÙNG ---
  Widget _buildZoneHeader({
    required String title,
    required Color color,
    required bool isEditMode,
    required VoidCallback onToggleEdit,
    required VoidCallback onAddTask,
    VoidCallback? onAddStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          if (onAddStatus != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: onAddStatus,
              icon: const Icon(Icons.add_road, size: 16),
              label: const Text('Thêm trạng thái'),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onAddTask,
            icon: const Icon(Icons.add_task, size: 16),
            label: const Text('Thêm nhiệm vụ'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: isEditMode,
            label: Text(isEditMode ? 'Chế độ Sửa: BẬT' : 'Chế độ Sửa: TẮT'),
            avatar: Icon(isEditMode ? Icons.edit : Icons.edit_off, size: 16),
            onSelected: (_) => onToggleEdit(),
            selectedColor: Colors.amber.shade200,
          ),
        ],
      ),
    );
  }

  // --- MỖI CỘT TRẠNG THÁI (KANBAN COLUMN) ---
  Widget _buildKanbanColumn({
    required String statusKey,
    required String statusTitle,
    required List<KanbanTask> tasks,
    required String zone,
    required bool isEditMode,
    required bool isCustomColumn,
  }) {
    return DragTarget<KanbanTask>(
      onWillAcceptWithDetails: (details) => details.data.status != statusKey,
      onAcceptWithDetails: (details) {
        _service.updateTaskStatus(details.data.id, statusKey);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$statusTitle (${tasks.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  if (isCustomColumn && isEditMode)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                      onPressed: () => _service.deleteSubStatus(statusKey),
                      tooltip: 'Xóa trạng thái',
                    ),
                ],
              ),
              const Divider(),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(child: Text('Trống', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Draggable<KanbanTask>(
                            data: task,
                            feedback: Material(
                              elevation: 4,
                              child: Container(
                                width: 260,
                                padding: const EdgeInsets.all(12),
                                color: Colors.white,
                                child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            childWhenDragging: Opacity(opacity: 0.3, child: _buildTaskCard(task, isEditMode, zone)),
                            child: _buildTaskCard(task, isEditMode, zone),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- CARD NHIỆM VỤ (TASK CARD) ---
  Widget _buildTaskCard(KanbanTask task, bool isEditMode, String zone) {
    final deadlineColor = task.deadlineColor;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: deadlineColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (isEditMode) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showTaskDialog(zone: zone, availableStatuses: [], editTask: task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _service.deleteTask(task.id),
                  ),
                ],
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  labelPadding: EdgeInsets.zero,
                  backgroundColor: deadlineColor.withOpacity(0.2),
                  label: Text(
                    task.priority.label,
                    style: TextStyle(fontSize: 10, color: deadlineColor, fontWeight: FontWeight.bold),
                  ),
                ),
                if (task.dueDate != null)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: deadlineColor),
                      const SizedBox(width: 2),
                      Text(
                        DateFormat('dd/MM HH:mm').format(task.dueDate!),
                        style: TextStyle(fontSize: 11, color: deadlineColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG THÊM / SỬA TASK ---
  void _showTaskDialog({
    required String zone,
    required List<String> availableStatuses,
    KanbanTask? editTask,
  }) {
    final titleController = TextEditingController(text: editTask?.title ?? '');
    final descController = TextEditingController(text: editTask?.description ?? '');
    TaskPriority selectedPriority = editTask?.priority ?? TaskPriority.normal;
    DateTime? selectedDueDate = editTask?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    String selectedStatus = editTask?.status ?? (availableStatuses.isNotEmpty ? availableStatuses.first : 'todo');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(editTask == null ? 'Thêm Nhiệm Vụ Mới' : 'Chỉnh Sửa Nhiệm Vụ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tên nhiệm vụ *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  const Text('Độ quan trọng:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<TaskPriority>(
                    isExpanded: true,
                    value: selectedPriority,
                    items: TaskPriority.values.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedPriority = val);
                      }
                    },
                  ),
                  if (selectedPriority != TaskPriority.notImportant) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'Chưa chọn hạn'
                                : 'Thời hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDueDate!)}',
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Chọn Lịch'),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null && context.mounted) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDueDate ?? DateTime.now()),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  selectedDueDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  final task = KanbanTask(
                    id: editTask?.id ?? '',
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    zone: zone,
                    status: selectedStatus,
                    priority: selectedPriority,
                    dueDate: selectedPriority == TaskPriority.notImportant ? null : selectedDueDate,
                  );

                  if (editTask == null) {
                    await _service.addTask(task);
                  } else {
                    await _service.updateTask(task);
                  }

                  if (mounted) Navigator.pop(context);
                },
                child: Text(editTask == null ? 'Thêm' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOG THÊM TRẠNG THÁI CHO KANBAN PHỤ ---
  void _showAddStatusDialog() {
    final statusController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Trạng Thái Cho Kanban Phụ'),
        content: TextField(
          controller: statusController,
          decoration: const InputDecoration(labelText: 'Tên trạng thái (VD: Code, Debug...)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (statusController.text.trim().isNotEmpty) {
                await _service.addSubStatus(statusController.text.trim());
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}