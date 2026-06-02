import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/app_drawer.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bgCheckRepoProvider);
    return Scaffold(
      drawer: const AppDrawer(role: 'admin'),
      appBar: AppBar(title: const Text('Admin')),
      body: FutureBuilder<Map<String,dynamic>>(
        future: repo.dashboardStats(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final s = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Manage users'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/admin/users'),
              )),
              Card(child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Audit log'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/admin/audit'),
              )),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Platform stats', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Candidates: ${s['total_candidates']}'),
                    Text('Total checks: ${s['total_checks']}'),
                    Text('Fayda verified profiles: ${s['fayda_verified']}'),
                    Text('In review: ${s['in_review']}'),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
