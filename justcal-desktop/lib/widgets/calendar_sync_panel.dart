import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CalendarSyncPanel extends StatefulWidget {
  final List<Task> tasks;
  const CalendarSyncPanel({super.key, required this.tasks});

  @override
  State<CalendarSyncPanel> createState() => _CalendarSyncPanelState();
}

class _CalendarSyncPanelState extends State<CalendarSyncPanel> {
  bool _googleConnected = false;
  bool _syncing = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await ApiService.getGoogleAuthStatus();
      if (mounted) setState(() => _googleConnected = status['connected'] as bool? ?? false);
    } catch (_) {}
  }

  Future<void> _connectGoogle() async {
    try {
      await ApiService.startGoogleAuth();
      await _checkStatus();
    } catch (_) {}
  }

  Future<void> _sync() async {
    setState(() { _syncing = true; _result = null; });
    try {
      final msg = await ApiService.syncTasksToCalendars(widget.tasks);
      if (mounted) setState(() => _result = msg);
    } catch (e) {
      if (mounted) setState(() => _result = 'Error: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unsyncedCount = widget.tasks.where((t) => !t.synced).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('Calendar Sync',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              _badge('JustCal', AppColors.low),
              const SizedBox(width: 6),
              _badge(
                _googleConnected ? 'Google ✓' : 'Google ✗',
                _googleConnected ? AppColors.low : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (!_googleConnected) ...[
            const Text('Connect Google Calendar to sync milestones.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: _connectGoogle,
                child: const Text('Connect Google',
                    style: TextStyle(fontSize: 12))),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, size: 16),
              label: Text(
                _syncing
                    ? 'Syncing…'
                    : 'Sync $unsyncedCount task${unsyncedCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 10),
            Text(_result!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
