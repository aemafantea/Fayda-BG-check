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
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final r = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return (r as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _changeRole(String id, String role) async {
    try {
      await Supabase.instance.client.from('profiles').update({'role': role}).eq('id', id);
      setState(() => _future = _load());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snap.data ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('No users yet'));
            }
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge.fromStatus(u['fayda_verification_status']?.toString()),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (r) => _changeRole(u['id'], r),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'candidate', child: Text('Make candidate')),
                            PopupMenuItem(value: 'hr', child: Text('Make HR')),
                            PopupMenuItem(value: 'admin', child: Text('Make admin')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
