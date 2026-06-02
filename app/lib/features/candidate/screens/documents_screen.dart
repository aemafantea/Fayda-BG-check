import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/db_status_banner.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _docTypes = const [
    'national_id', 'passport', 'certificate', 'transcript',
    'reference_letter', 'employment_letter', 'police_clearance', 'other'
  ];
  late Future<List<AppDocument>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppDocument>> _load() {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return Future.value([]);
    return ref.read(bgCheckRepoProvider).listDocuments(uid);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _upload(String ownerId) async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    if (f.bytes == null) {
      _showSnack('Could not read file bytes');
      return;
    }
    if (!mounted) return;
    final docType = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _docTypes
              .map((t) => ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(t.replaceAll('_', ' ')),
                    onTap: () => Navigator.pop(context, t),
                  ))
              .toList(),
        ),
      ),
    );
    if (docType == null) return;
    try {
      await ref.read(bgCheckRepoProvider).uploadDocument(
            ownerId: ownerId,
            docType: docType,
            fileName: f.name,
            bytes: f.bytes!,
            mimeType: _mime(f.name),
          );
      _showSnack('Uploaded ${f.name}');
      _reload();
    } catch (e) {
      _showSnack('Upload failed: $e');
    }
  }

  void _showSnack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  String? _mime(String name) {
    final ext = name.split('.').last.toLowerCase();
    return {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
    }[ext];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final repo = ref.watch(bgCheckRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<AppDocument>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorState(
                  message: '${snap.error}', onRetry: _reload);
            }
            final docs = snap.data ?? const [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const DbStatusBanner(),
                if (docs.isEmpty)
                  const _EmptyState()
                else
                  ...docs.map((d) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file,
                              color: AppTheme.primary),
                          title: Text(d.fileName),
                          subtitle: Text(d.docType.replaceAll('_', ' ')),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'open') {
                                try {
                                  final url = await repo.signedDocUrl(d.filePath);
                                  await launchUrl(Uri.parse(url));
                                } catch (e) {
                                  _showSnack('Cannot open: $e');
                                }
                              } else if (action == 'delete') {
                                try {
                                  await repo.deleteDocument(d);
                                  _reload();
                                } catch (e) {
                                  _showSnack('Delete failed: $e');
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'open',
                                  child: ListTile(
                                      leading: Icon(Icons.open_in_new),
                                      title: Text('Open'))),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                      leading: Icon(Icons.delete_outline,
                                          color: AppTheme.danger),
                                      title: Text('Delete'))),
                            ],
                          ),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upload(user.id),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_off, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            const Text('No documents yet'),
            const SizedBox(height: 4),
            Text('Tap "Upload" to add your first document',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
