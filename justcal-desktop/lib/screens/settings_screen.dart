import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _googleConnected = false;
  String _googleEmail = '';
  bool _geminiKeySaved = false;
  final _geminiCtl = TextEditingController();
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final g = await ApiService.getGoogleAuthStatus();
      final k = await ApiService.getGeminiKeyStatus();
      if (mounted) {
        setState(() {
          _googleConnected = g['connected'] as bool? ?? false;
          _googleEmail = g['email'] as String? ?? '';
          _geminiKeySaved = k;
        });
      }
    } catch (_) {}
  }

  Future<void> _connectGoogle() async {
    try {
      await ApiService.startGoogleAuth();
      await _loadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _disconnectGoogle() async {
    await ApiService.revokeGoogleAuth();
    if (mounted) setState(() { _googleConnected = false; _googleEmail = ''; });
  }

  Future<void> _saveGeminiKey() async {
    final key = _geminiCtl.text.trim();
    if (key.isEmpty) return;
    await ApiService.saveGeminiKey(key);
    if (mounted) {
      setState(() => _geminiKeySaved = true);
      _geminiCtl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 24),

            // ── Google Calendar ──
            _card(
              title: 'Google Calendar',
              trailing: _statusPill(_googleConnected),
              child: _googleConnected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_googleEmail.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.account_circle,
                                    size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  _googleEmail,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        OutlinedButton(
                            onPressed: _disconnectGoogle,
                            child: const Text('Disconnect')),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _connectGoogle,
                      child: const Text('Connect Google')),
            ),
            const SizedBox(height: 16),

            // ── Gemini API Key ──
            _card(
              title: 'Gemini API Key',
              trailing: _statusPill(_geminiKeySaved),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paste your Gemini API key. This is stored securely in your OS keychain.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _geminiCtl,
                          obscureText: !_showKey,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'AIza…',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _showKey = !_showKey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: _saveGeminiKey,
                          child: const Text('Save')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
      {required String title, required Widget child, Widget? trailing}) {
    return Container(
      width: double.infinity,
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statusPill(bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? AppColors.low.withValues(alpha: 0.15) : AppColors.high.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ok ? 'Connected' : 'Not set',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ok ? AppColors.low : AppColors.high),
      ),
    );
  }
}
