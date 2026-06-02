import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder(
        future: Supabase.instance.client.from('notifications')
            .select().order('created_at', ascending: false).limit(100),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = (snap.data as List).cast<Map<String,dynamic>>();
          if (list.isEmpty) return const Center(child: Text('No notifications'));
          return ListView.separated(
            itemCount: list.length, separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = list[i];
              return ListTile(
                leading: Icon(n['is_read'] == true ? Icons.mark_email_read : Icons.mark_email_unread),
                title: Text(n['title'] ?? ''), subtitle: Text(n['body'] ?? ''),
                trailing: Text((n['created_at'] as String).substring(0, 10)),
              );
            },
          );
        },
      ),
    );
  }
}
