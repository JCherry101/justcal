import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _sending = false;
  bool _creatingTasks = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final msgs = await ApiService.getChatHistory();
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await ApiService.chatSend(text);
      if (mounted) setState(() => _messages.add(reply));
    } catch (e) {
      if (mounted) {
        setState(() => _messages
            .add(ChatMessage(role: 'assistant', content: 'Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _clearHistory() async {
    await ApiService.chatClearHistory();
    if (mounted) setState(() => _messages = []);
  }

  Future<void> _autoCreateTasks() async {
    setState(() => _creatingTasks = true);
    try {
      final tasks = await ApiService.createTasksFromChat();
      if (mounted) {
        setState(() => _messages.add(ChatMessage(
            role: 'assistant',
            content: 'Created ${tasks.length} task(s) from your documents.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages
            .add(ChatMessage(role: 'assistant', content: 'Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _creatingTasks = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Assistant',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (_messages.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Ask me about your schedule, deadlines, or documents.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _creatingTasks ? null : _autoCreateTasks,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(
                            _creatingTasks
                                ? 'Creating…'
                                : 'Auto-Create Tasks from Documents',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length) {
                        // "Thinking" bubble
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Thinking…',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                          ),
                        );
                      }
                      final msg = _messages[i];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.accent
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            msg.content,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isUser
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),

          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(
                    hintText: 'Ask something…',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send_rounded, color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
