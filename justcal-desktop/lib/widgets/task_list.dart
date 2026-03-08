import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class TaskList extends StatefulWidget {
  final List<Task> tasks;
  final void Function(List<Task> updated) onTasksChange;

  const TaskList({super.key, required this.tasks, required this.onTasksChange});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  String? _expandedId;

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return AppColors.high;
      case 'medium':
        return AppColors.medium;
      default:
        return AppColors.low;
    }
  }

  void _delete(String id) {
    widget.onTasksChange(widget.tasks.where((t) => t.id != id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final task in widget.tasks)
          GestureDetector(
            onTap: () => setState(() =>
                _expandedId = _expandedId == task.id ? null : task.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _expandedId == task.id
                      ? AppColors.borderActive
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _priorityColor(task.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      // Badges
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.deadline,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _priorityColor(task.priority).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _priorityColor(task.priority)),
                        ),
                      ),
                      if (task.synced) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.low.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Synced',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.low)),
                        ),
                      ],
                    ],
                  ),
                  if (_expandedId == task.id) ...[
                    const SizedBox(height: 10),
                    Text(
                      task.description.isEmpty
                          ? 'No description.'
                          : task.description,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _delete(task.id),
                        icon: const Icon(Icons.delete_outline,
                            size: 14, color: AppColors.high),
                        label: const Text('Delete',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.high)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
