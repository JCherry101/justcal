import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DropZone extends StatefulWidget {
  final void Function(List<Task> tasks) onTasksExtracted;
  const DropZone({super.key, required this.onTasksExtracted});

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _dragging = false;
  bool _processing = false;
  String? _error;

  Future<void> _processFile(String path) async {
    final ext = path.split('.').last.toLowerCase();
    if (ext != 'pdf' && ext != 'docx') {
      setState(() => _error = 'Only PDF and DOCX files are supported.');
      return;
    }

    setState(() { _processing = true; _error = null; });
    try {
      final tasks = await ApiService.ingestDocument(path);
      widget.onTasksExtracted(tasks);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _browse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      _processFile(result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        if (details.files.isNotEmpty) {
          _processFile(details.files.first.path);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: _dragging ? AppColors.accentMuted : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _dragging ? AppColors.accent : AppColors.borderActive,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_processing) ...[
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.accent),
              ),
              const SizedBox(height: 12),
              const Text('Extracting tasks with AI…',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ] else ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accentMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _dragging ? Icons.description : Icons.upload_file,
                  size: 24,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _dragging ? 'Release to extract' : 'Drop your syllabus here',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text('PDF and DOCX supported',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              if (!_dragging) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _browse,
                  icon: const Icon(Icons.folder_open, size: 14),
                  label: const Text('Browse files',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.high)),
            ],
          ],
        ),
      ),
    );
  }
}
