import 'dart:io';
import 'package:http/http.dart' as http;

/// Manages the lifecycle of the Python FastAPI backend process.
class BackendProcess {
  Process? _process;
  static const _port = 21547;

  /// Spawn the Python backend. Returns once the health endpoint responds.
  Future<void> start() async {
    // Find the backend directory relative to the executable
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    // In development the backend lives next to the Flutter project root.
    // In a bundled app it would be next to the runner executable.
    final candidates = [
      '$exeDir/backend/main.py',
      '$exeDir/../backend/main.py',
      '${Directory.current.path}/backend/main.py',
    ];

    String? backendScript;
    for (final c in candidates) {
      if (File(c).existsSync()) {
        backendScript = c;
        break;
      }
    }

    if (backendScript == null) {
      throw Exception(
          'Cannot find backend/main.py. Searched:\n${candidates.join('\n')}');
    }

    final python = Platform.isWindows ? 'python' : 'python3';

    _process = await Process.start(
      python,
      [backendScript],
      environment: {'JUSTCAL_PORT': '$_port'},
      mode: ProcessStartMode.inheritStdio,
    );

    // Wait for backend to become ready (up to 60 s for model download)
    for (var i = 0; i < 120; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final resp = await http.Client()
            .get(Uri.parse('http://127.0.0.1:$_port/health'))
            .timeout(const Duration(seconds: 2));
        if (resp.statusCode == 200) return;
      } catch (_) {}
    }
    throw Exception('Backend did not start within 60 seconds');
  }

  /// Kill the backend process.
  void stop() {
    _process?.kill();
    _process = null;
  }
}
