import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/drop_zone.dart';
import '../widgets/task_list.dart';
import '../widgets/calendar_sync_panel.dart';

class DashboardScreen extends StatefulWidget {
  final bool showTasksOnly;
  const DashboardScreen({super.key, this.showTasksOnly = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await ApiService.getAllTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (_) {}
  }

  Future<void> _onNewTasks(List<Task> newTasks) async {
    setState(() => _tasks = [..._tasks, ...newTasks]);
    try {
      await ApiService.saveTasks(newTasks);
    } catch (e) {
      debugPrint('Failed to save tasks: $e');
    }
  }

  void _onTasksChange(List<Task> updated) {
    setState(() => _tasks = updated);
    ApiService.saveTasks(updated).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.showTasksOnly ? 'My Tasks' : 'Dashboard',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              widget.showTasksOnly
                  ? 'All your extracted milestones in one place.'
                  : 'Drop a syllabus or course document to get started.',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (!widget.showTasksOnly) ...[
              DropZone(onTasksExtracted: _onNewTasks),
              const SizedBox(height: 24),
            ],
            if (_tasks.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    widget.showTasksOnly ? 'All Tasks' : 'Extracted Tasks',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_tasks.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentHover),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TaskList(tasks: _tasks, onTasksChange: _onTasksChange),
            ] else if (widget.showTasksOnly)
              Container(
                padding: const EdgeInsets.all(48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'No tasks yet — drop a document on the Dashboard to get started.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            if (!widget.showTasksOnly && _tasks.isNotEmpty) ...[
              const SizedBox(height: 24),
              CalendarSyncPanel(tasks: _tasks),
            ],
          ],
        ),
      ),
    );
  }
}
