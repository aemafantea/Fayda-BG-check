import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/status_badge.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});
  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  Future<List<Map<String,dynamic>>> _load() async {
    final r = await Supabase.instance.client.from('profiles').select().order('created_at', ascending: false);
    return (r as List).cast<Map<String,dynamic>>();
  }

  Future<void> _changeRole(String id, String role) async {
    await Supabase.instance.client.from('profiles').update({'role': role}).eq('id', id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: FutureBuilder(
        future: _load(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final users = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final u = users[i];
              return Card(
                child: ListTile(
                  title: Text(u['full_name'] ?? '—'),
                  subtitle: Text('${u['phone'] ?? ''} • role: ${u['role']}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    StatusBadge.fromStatus(u['fayda_verification_status']),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (r) => _changeRole(u['id'], r),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'candidate', child: Text('Make candidate')),
                        PopupMenuItem(value: 'hr', child: Text('Make HR')),
                        PopupMenuItem(value: 'admin', child: Text('Make admin')),
                      ],
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
