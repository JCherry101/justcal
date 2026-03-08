import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Document> _docs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final docs = await ApiService.getDocuments();
      if (mounted) setState(() => _docs = docs);
    } catch (_) {}
  }

  Future<void> _delete(String id) async {
    await ApiService.deleteDocument(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Documents',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Ingested documents used for AI context.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: _docs.isEmpty
                ? const Center(
                    child: Text('No documents yet.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13)))
                : ListView.builder(
                    itemCount: _docs.length,
                    itemBuilder: (ctx, i) {
                      final d = _docs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.filename,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.chunkCount} chunks  ·  ${d.ingestedAt.substring(0, 10)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _delete(d.id),
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
