import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: FutureBuilder(
        future: Supabase.instance.client.from('audit_logs').select().order('created_at', ascending: false).limit(200),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = (snap.data as List).cast<Map<String,dynamic>>();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final l = list[i];
              return ListTile(
                leading: const Icon(Icons.history, size: 18),
                title: Text(l['action'] ?? '—'),
                subtitle: Text('${l['resource_type'] ?? ''} ${l['resource_id'] ?? ''}\n${l['created_at']}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
