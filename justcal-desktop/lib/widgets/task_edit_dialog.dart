import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// A dialog for creating or editing a task.
/// Returns the edited [Task] on save, or null on cancel.
class TaskEditDialog extends StatefulWidget {
  final Task? task;
  final DateTime? initialDate;

  const TaskEditDialog({super.key, this.task, this.initialDate});

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _deadline;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 'medium';

    if (widget.task != null) {
      final parts = widget.task!.deadline.split('-');
      if (parts.length == 3) {
        _deadline = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        _deadline = widget.initialDate ?? DateTime.now();
      }
    } else {
      _deadline = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.bgElevated,
            onSurface: AppColors.textPrimary,
          ),
          dialogBackgroundColor: AppColors.bgSurface,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final result = Task(
      id: widget.task?.id ?? '',
      title: title,
      deadline: _fmtDate(_deadline),
      priority: _priority,
      description: _descCtrl.text.trim(),
      synced: widget.task?.synced ?? false,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    return Dialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Task' : 'New Task',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),

              // Title
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Title'),
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
              ),
              const SizedBox(height: 14),

              // Deadline
              Row(
                children: [
                  const Text('Deadline',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_fmtDate(_deadline),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Priority
              Row(
                children: [
                  const Text('Priority',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  for (final p in ['low', 'medium', 'high'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(p[0].toUpperCase() + p.substring(1),
                            style: const TextStyle(fontSize: 12)),
                        selected: _priority == p,
                        selectedColor: p == 'high'
                            ? AppColors.high.withOpacity(0.25)
                            : p == 'medium'
                                ? AppColors.medium.withOpacity(0.25)
                                : AppColors.low.withOpacity(0.25),
                        backgroundColor: AppColors.bgElevated,
                        side: BorderSide(
                          color: _priority == p
                              ? (p == 'high'
                                  ? AppColors.high
                                  : p == 'medium'
                                      ? AppColors.medium
                                      : AppColors.low)
                              : AppColors.border,
                        ),
                        onSelected: (_) => setState(() => _priority = p),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Description
              TextField(
                controller: _descCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'Save' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
