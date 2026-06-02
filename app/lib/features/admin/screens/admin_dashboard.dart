import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/db_status_banner.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});
  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(bgCheckRepoProvider).dashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(role: 'admin'),
      appBar: AppBar(title: const Text('Admin')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = ref.read(bgCheckRepoProvider).dashboardStats();
          });
          await _future;
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final s = snap.data ?? const <String, dynamic>{};
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const DbStatusBanner(),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Manage users'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/users'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Audit log'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/audit'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Platform stats',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Candidates: ${s['total_candidates'] ?? 0}'),
                        Text('Total checks: ${s['total_checks'] ?? 0}'),
                        Text('Fayda verified profiles: ${s['fayda_verified'] ?? 0}'),
                        Text('In review: ${s['in_review'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
