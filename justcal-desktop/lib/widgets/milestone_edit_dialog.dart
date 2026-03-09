import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// A dialog for creating or editing a milestone.
/// Returns the edited [Milestone] on save, or null on cancel.
class MilestoneEditDialog extends StatefulWidget {
  final Milestone? milestone;
  final String? defaultTaskId;
  final DateTime? initialDate;
  final List<Task> tasks;

  const MilestoneEditDialog({
    super.key,
    this.milestone,
    this.defaultTaskId,
    this.initialDate,
    required this.tasks,
  });

  @override
  State<MilestoneEditDialog> createState() => _MilestoneEditDialogState();
}

class _MilestoneEditDialogState extends State<MilestoneEditDialog> {
  late final TextEditingController _titleCtrl;
  late DateTime _dueDate;
  late String _kind;
  late String? _taskId;

  static const _kinds = ['start', 'draft', 'review', 'final', 'custom'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.milestone?.title ?? '');
    _kind = widget.milestone?.kind ?? 'custom';

    if (widget.milestone != null) {
      final parts = widget.milestone!.dueDate.split('-');
      if (parts.length == 3) {
        _dueDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        _dueDate = widget.initialDate ?? DateTime.now();
      }
      _taskId = widget.milestone!.taskId;
    } else {
      _dueDate = widget.initialDate ?? DateTime.now();
      _taskId = widget.defaultTaskId ?? widget.tasks.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
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
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _taskId == null) return;

    final result = Milestone(
      id: widget.milestone?.id ?? '',
      taskId: _taskId!,
      title: title,
      dueDate: _fmtDate(_dueDate),
      kind: _kind,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.milestone != null;
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
                isEdit ? 'Edit Milestone' : 'New Milestone',
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

              // Parent task
              if (!isEdit && widget.tasks.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('Task',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _taskId,
                        dropdownColor: AppColors.bgElevated,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: widget.tasks
                            .map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _taskId = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Due date
              Row(
                children: [
                  const Text('Due date',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_fmtDate(_dueDate),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Kind
              Row(
                children: [
                  const Text('Kind',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  for (final k in _kinds)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(k[0].toUpperCase() + k.substring(1),
                            style: const TextStyle(fontSize: 11)),
                        selected: _kind == k,
                        selectedColor: AppColors.accent.withOpacity(0.25),
                        backgroundColor: AppColors.bgElevated,
                        side: BorderSide(
                          color: _kind == k
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                        onSelected: (_) => setState(() => _kind = k),
                      ),
                    ),
                ],
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
