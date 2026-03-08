import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
        events.add(_DayEvent(t.title, _priorityColor(t.priority), 'task'));
      }
    }
    for (final m in _milestones) {
      if (m.dueDate == ds) {
        events.add(_DayEvent(m.title, _kindColor(m.kind), 'milestone'));
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

          // Selected day detail
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${months[_selected!.month]} ${_selected!.day}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  for (final e in _eventsFor(_selected!))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: e.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(e.title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                        ),
                      ]),
                    ),
                  if (_eventsFor(_selected!).isEmpty)
                    const Text('No events',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayEvent {
  final String title;
  final Color color;
  final String type;
  const _DayEvent(this.title, this.color, this.type);
}
