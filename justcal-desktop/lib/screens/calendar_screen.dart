import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_edit_dialog.dart';
import '../widgets/milestone_edit_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _current = DateTime.now();
  DateTime? _selected;
  List<Task> _tasks = [];
  List<Milestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await ApiService.getAllTasks();
      final m = await ApiService.getAllMilestones();
      if (mounted) setState(() { _tasks = t; _milestones = m; });
    } catch (_) {}
  }

  // Collect events for a given day
  List<_DayEvent> _eventsFor(DateTime day) {
    final ds = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final events = <_DayEvent>[];
    for (final t in _tasks) {
      if (t.deadline == ds) {
        events.add(_DayEvent(t.title, _priorityColor(t.priority), 'task', id: t.id));
      }
    }
    for (final m in _milestones) {
      if (m.dueDate == ds) {
        events.add(_DayEvent(m.title, _kindColor(m.kind), 'milestone', id: m.id));
      }
    }
    return events;
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return AppColors.high;
      case 'medium': return AppColors.medium;
      default: return AppColors.low;
    }
  }

  Color _kindColor(String k) {
    switch (k) {
      case 'final': return AppColors.high;
      case 'review': return AppColors.medium;
      case 'draft': return AppColors.accent;
      default: return AppColors.low;
    }
  }

  void _prevMonth() => setState(() {
        _current = DateTime(_current.year, _current.month - 1);
        _selected = null;
      });

  void _nextMonth() => setState(() {
        _current = DateTime(_current.year, _current.month + 1);
        _selected = null;
      });

  void _goToday() => setState(() {
        _current = DateTime.now();
        _selected = null;
      });

  // ── Task CRUD ──

  Future<void> _addTask(DateTime date) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (_) => TaskEditDialog(initialDate: date),
    );
    if (result == null) return;
    try {
      await ApiService.saveTasks([result]);
      await _load();
    } catch (_) {}
  }

  Future<void> _editTask(Task task) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (_) => TaskEditDialog(task: task),
    );
    if (result == null) return;
    try {
      await ApiService.updateTask(result.copyWith(id: task.id));
      await _load();
    } catch (_) {}
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}" and all its milestones?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteTask(task.id);
      await _load();
    } catch (_) {}
  }

  // ── Milestone CRUD ──

  Future<void> _addMilestone(DateTime date) async {
    final result = await showDialog<Milestone>(
      context: context,
      builder: (_) => MilestoneEditDialog(
        tasks: _tasks,
        initialDate: date,
      ),
    );
    if (result == null) return;
    try {
      await ApiService.createMilestone(result);
      await _load();
    } catch (_) {}
  }

  Future<void> _editMilestone(Milestone ms) async {
    final result = await showDialog<Milestone>(
      context: context,
      builder: (_) => MilestoneEditDialog(milestone: ms, tasks: _tasks),
    );
    if (result == null) return;
    try {
      await ApiService.updateMilestone(result.copyWith(id: ms.id));
      await _load();
    } catch (_) {}
  }

  Future<void> _deleteMilestone(Milestone ms) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('Delete Milestone'),
        content: Text('Delete "${ms.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteMilestone(ms.id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_current.year, _current.month, 1);
    final daysInMonth = DateTime(_current.year, _current.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // 0=Sun
    final today = DateTime.now();
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: calendar grid ──
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      '${months[_current.month]} ${_current.year}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left, size: 20)),
                    OutlinedButton(
                        onPressed: _goToday,
                        child: const Text('Today', style: TextStyle(fontSize: 12))),
                    IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right, size: 20)),
                  ],
                ),
                const SizedBox(height: 16),

                // Weekday headers
                Row(
                  children: weekdays
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Day grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: startWeekday + daysInMonth,
                    itemBuilder: (ctx, idx) {
                      if (idx < startWeekday) return const SizedBox.shrink();
                      final day = idx - startWeekday + 1;
                      final date = DateTime(_current.year, _current.month, day);
                      final isToday = date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day;
                      final isSelected = _selected != null &&
                          date.year == _selected!.year &&
                          date.month == _selected!.month &&
                          date.day == _selected!.day;
                      final events = _eventsFor(date);

                      return GestureDetector(
                        onTap: () => setState(() =>
                            _selected = isSelected ? null : date),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentMuted
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.accent
                                  : AppColors.border,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (events.isNotEmpty)
                                Wrap(
                                  spacing: 3,
                                  children: [
                                    for (final e in events.take(3))
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                            color: e.color, shape: BoxShape.circle),
                                      ),
                                    if (events.length > 3)
                                      Text('+${events.length - 3}',
                                          style: const TextStyle(
                                              fontSize: 8,
                                              color: AppColors.textMuted)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ── Right: day detail panel ──
          Expanded(
            flex: 2,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: _selected == null
                  ? const Center(
                      child: Text(
                        'Select a day to view or add events',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                    )
                  : _buildDayDetail(months),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetail(List<String> months) {
    final events = _eventsFor(_selected!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header + add buttons
        Row(
          children: [
            Text(
              '${months[_selected!.month]} ${_selected!.day}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const Spacer(),
            _AddMenu(
              onAddTask: () => _addTask(_selected!),
              onAddMilestone: () => _addMilestone(_selected!),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Divider(color: AppColors.border, height: 20),

        // Event list
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Text('No events',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted)),
                )
              : ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final e = events[i];
                    return _EventTile(
                      event: e,
                      onEdit: () {
                        if (e.type == 'task') {
                          final t = _tasks.firstWhere((t) => t.id == e.id);
                          _editTask(t);
                        } else {
                          final m = _milestones.firstWhere((m) => m.id == e.id);
                          _editMilestone(m);
                        }
                      },
                      onDelete: () {
                        if (e.type == 'task') {
                          final t = _tasks.firstWhere((t) => t.id == e.id);
                          _deleteTask(t);
                        } else {
                          final m = _milestones.firstWhere((m) => m.id == e.id);
                          _deleteMilestone(m);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Helper widgets ──

class _AddMenu extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddMilestone;

  const _AddMenu({required this.onAddTask, required this.onAddMilestone});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, size: 18, color: AppColors.accent),
      ),
      color: AppColors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (v) {
        if (v == 'task') onAddTask();
        if (v == 'milestone') onAddMilestone();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'task',
          child: Row(children: [
            Icon(Icons.check_circle_outline, size: 16, color: AppColors.accent),
            SizedBox(width: 8),
            Text('New Task', style: TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'milestone',
          child: Row(children: [
            Icon(Icons.flag_outlined, size: 16, color: AppColors.medium),
            SizedBox(width: 8),
            Text('New Milestone', style: TextStyle(fontSize: 13)),
          ]),
        ),
      ],
    );
  }
}

class _EventTile extends StatefulWidget {
  final _DayEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventTile({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<_EventTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.bgHover : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: widget.event.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.event.type == 'task' ? 'Task' : 'Milestone',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (_hovered) ...[
              _IconBtn(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                onTap: widget.onEdit,
              ),
              const SizedBox(width: 2),
              _IconBtn(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                onTap: widget.onDelete,
                color: AppColors.high,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _DayEvent {
  final String title;
  final Color color;
  final String type;
  final String id;
  const _DayEvent(this.title, this.color, this.type, {required this.id});
}
