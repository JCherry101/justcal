import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:21547';
  static final _client = http.Client();

  // ── Health ──

  static Future<bool> healthCheck() async {
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Tasks ──

  static Future<List<Task>> getAllTasks() async {
    final resp = await _client.get(Uri.parse('$_baseUrl/tasks'));
    _check(resp);
    return (jsonDecode(resp.body) as List)
        .map((j) => Task.fromJson(j))
        .toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
    _check(resp);
  }

  static Future<List<Task>> createTasksFromChat() async {
    final resp = await _client.post(Uri.parse('$_baseUrl/tasks/from-chat'));
    _check(resp);
    return (jsonDecode(resp.body) as List)
        .map((j) => Task.fromJson(j))
        .toList();
  }

  static Future<void> updateTask(Task task) async {
    final resp = await _client.put(
      Uri.parse('$_baseUrl/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': task.title,
        'deadline': task.deadline,
        'priority': task.priority,
        'description': task.description,
      }),
    );
    _check(resp);
  }

  static Future<void> deleteTask(String taskId) async {
    final resp = await _client.delete(Uri.parse('$_baseUrl/tasks/$taskId'));
    _check(resp);
  }

  // ── Documents ──

  static Future<List<Task>> ingestDocument(String filePath) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/documents/ingest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'file_path': filePath}),
    );
    _check(resp);
    return (jsonDecode(resp.body) as List)
        .map((j) => Task.fromJson(j))
        .toList();
  }

  static Future<List<Document>> getDocuments() async {
    final resp = await _client.get(Uri.parse('$_baseUrl/documents'));
    _check(resp);
    return (jsonDecode(resp.body) as List)
        .map((j) => Document.fromJson(j))
        .toList();
  }

  static Future<void> deleteDocument(String docId) async {
    final resp =
        await _client.delete(Uri.parse('$_baseUrl/documents/$docId'));
    _check(resp);
  }

  // ── Chat ──

  static Future<List<ChatMessage>> getChatHistory() async {
    final resp = await _client.get(Uri.parse('$_baseUrl/chat/history'));
    _check(resp);
    return (jsonDecode(resp.body) as List)
        .map((j) => ChatMessage.fromJson(j))
        .toList();
  }

  static Future<ChatMessage> chatSend(String message) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/chat/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    _check(resp);
    return ChatMessage.fromJson(jsonDecode(resp.body));
  }

  static Future<void> chatClearHistory() async {
    final resp = await _client.delete(Uri.parse('$_baseUrl/chat/history'));
    _check(resp);
  }

  // ── Calendar ──

  static Future<List<Milestone>> getAllMilestones() async {
    final resp = await _client.get(Uri.parse('$_baseUrl/milestones'));
    _check(resp);
    return (jsonDecode(resp.body) as List)
        .map((j) => Milestone.fromJson(j))
        .toList();
  }

  static Future<Milestone> createMilestone(Milestone ms) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/milestones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'task_id': ms.taskId,
        'title': ms.title,
        'due_date': ms.dueDate,
        'kind': ms.kind,
      }),
    );
    _check(resp);
    return Milestone.fromJson(jsonDecode(resp.body));
  }

  static Future<void> updateMilestone(Milestone ms) async {
    final resp = await _client.put(
      Uri.parse('$_baseUrl/milestones/${ms.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': ms.title,
        'due_date': ms.dueDate,
        'kind': ms.kind,
      }),
    );
    _check(resp);
  }

  static Future<void> deleteMilestone(String milestoneId) async {
    final resp =
        await _client.delete(Uri.parse('$_baseUrl/milestones/$milestoneId'));
    _check(resp);
  }

  static Future<String> syncTasksToCalendars(List<Task> tasks) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/calendar/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
    _check(resp);
    return (jsonDecode(resp.body) as Map)['message'] as String? ?? 'Synced';
  }

  // ── Auth ──

  static Future<void> startGoogleAuth() async {
    final resp =
        await _client.post(Uri.parse('$_baseUrl/auth/google/start'))
            .timeout(const Duration(minutes: 6));
    _check(resp);
  }

  static Future<Map<String, dynamic>> getGoogleAuthStatus() async {
    final resp =
        await _client.get(Uri.parse('$_baseUrl/auth/google/status'));
    _check(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<void> revokeGoogleAuth() async {
    final resp =
        await _client.post(Uri.parse('$_baseUrl/auth/google/revoke'));
    _check(resp);
  }

  // ── Settings ──

  static Future<void> saveGeminiKey(String key) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/settings/gemini-key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': key}),
    );
    _check(resp);
  }

  static Future<bool> getGeminiKeyStatus() async {
    final resp =
        await _client.get(Uri.parse('$_baseUrl/settings/gemini-key/status'));
    _check(resp);
    return (jsonDecode(resp.body) as Map)['saved'] as bool? ?? false;
  }

  // ── helpers ──

  static void _check(http.Response resp) {
    if (resp.statusCode >= 400) {
      throw Exception('API error ${resp.statusCode}: ${resp.body}');
    }
  }
}
