import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar.dart';
import 'screens/calendar_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/settings_screen.dart';
import 'services/backend_process.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JustCalApp());
}

class JustCalApp extends StatelessWidget {
  const JustCalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustCal',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _activeView = 'calendar';
  final _backend = BackendProcess();
  bool _backendReady = false;
  String? _backendError;

  @override
  void initState() {
    super.initState();
    _startBackend();
  }

  Future<void> _startBackend() async {
    try {
      await _backend.start();
      if (mounted) setState(() => _backendReady = true);
    } catch (e) {
      if (mounted) setState(() => _backendError = e.toString());
    }
  }

  @override
  void dispose() {
    _backend.stop();
    super.dispose();
  }

  Widget _buildBody() {
    if (!_backendReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              _backendError ?? 'Starting backend…',
              style: TextStyle(
                color: _backendError != null
                    ? AppColors.high
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    switch (_activeView) {
      case 'calendar':
        return const CalendarScreen();
      case 'tasks':
        return const CalendarScreen(); // tasks visible in calendar
      case 'chat':
        return const ChatScreen();
      case 'documents':
        return const DocumentsScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const CalendarScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            activeView: _activeView,
            onNavigate: (v) => setState(() => _activeView = v),
          ),
          Container(width: 1, color: AppColors.border),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
