import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final r = await Supabase.instance.client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      return (r as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Center(child: Text('No audit entries yet'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final l = list[i];
                return ListTile(
                  leading: const Icon(Icons.history, size: 18),
                  title: Text(l['action'] ?? '—'),
                  subtitle: Text(
                      '${l['resource_type'] ?? ''} ${l['resource_id'] ?? ''}\n${l['created_at']}'),
                  isThreeLine: true,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
