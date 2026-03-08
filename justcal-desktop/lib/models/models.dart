class Task {
  final String id;
  final String title;
  final String deadline;
  final String priority;
  final String description;
  final bool synced;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.description,
    this.synced = false,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        deadline: j['deadline'] as String,
        priority: j['priority'] as String,
        description: j['description'] as String? ?? '',
        synced: j['synced'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'deadline': deadline,
        'priority': priority,
        'description': description,
        'synced': synced,
      };
}

class Milestone {
  final String id;
  final String taskId;
  final String title;
  final String dueDate;
  final String kind;

  Milestone({
    required this.id,
    required this.taskId,
    required this.title,
    required this.dueDate,
    required this.kind,
  });

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
        id: j['id'] as String,
        taskId: j['task_id'] as String,
        title: j['title'] as String,
        dueDate: j['due_date'] as String,
        kind: j['kind'] as String,
      );
}

class Document {
  final String id;
  final String filename;
  final String ingestedAt;
  final int chunkCount;
  final int taskCount;

  Document({
    required this.id,
    required this.filename,
    required this.ingestedAt,
    required this.chunkCount,
    required this.taskCount,
  });

  factory Document.fromJson(Map<String, dynamic> j) => Document(
        id: j['id'] as String,
        filename: j['filename'] as String,
        ingestedAt: j['ingested_at'] as String,
        chunkCount: j['chunk_count'] as int? ?? 0,
        taskCount: j['task_count'] as int? ?? 0,
      );
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: j['role'] as String,
        content: j['content'] as String,
      );
}
