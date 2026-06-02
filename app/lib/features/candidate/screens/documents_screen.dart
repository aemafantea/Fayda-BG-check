import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/bg_check_repository.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _docTypes = const ['national_id','passport','certificate','transcript','reference_letter','employment_letter','police_clearance','other'];

  Future<void> _upload(String ownerId) async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    final docType = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, children: _docTypes
            .map((t) => ListTile(title: Text(t.replaceAll('_',' ')),
                onTap: () => Navigator.pop(context, t))).toList()),
      ),
    );
    if (docType == null) return;
    await ref.read(bgCheckRepoProvider).uploadDocument(
      ownerId: ownerId, docType: docType, fileName: f.name, bytes: f.bytes!, mimeType: _mime(f.name),
    );
    setState(() {});
  }

  String? _mime(String name) {
    final ext = name.split('.').last.toLowerCase();
    return {'pdf':'application/pdf','jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png'}[ext];
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final repo = ref.watch(bgCheckRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: FutureBuilder(
        future: repo.listDocuments(profile.id),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!;
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.folder_off, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 12), const Text('No documents yet'),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = docs[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: AppTheme.primary),
                  title: Text(d.fileName),
                  subtitle: Text(d.docType.replaceAll('_',' ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      final url = await repo.signedDocUrl(d.filePath);
                      await launchUrl(Uri.parse(url));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upload(profile.id),
        icon: const Icon(Icons.upload_file), label: const Text('Upload'),
      ),
    );
  }
}
