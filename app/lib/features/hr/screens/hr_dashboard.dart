import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/app_drawer.dart';

class HrDashboard extends ConsumerWidget {
  const HrDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bgCheckRepoProvider);
    return Scaffold(
      drawer: const AppDrawer(role: 'hr'),
      appBar: AppBar(title: const Text('HR Consultant Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.add_task), onPressed: () => context.go('/hr/new-check')),
      ]),
      body: FutureBuilder<Map<String,dynamic>>(
        future: repo.dashboardStats(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final s = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, childAspectRatio: 1.5, mainAxisSpacing: 12, crossAxisSpacing: 12,
                children: [
                  _Stat('Candidates', '${s['total_candidates'] ?? 0}', Icons.people, AppTheme.primary),
                  _Stat('Total checks', '${s['total_checks'] ?? 0}', Icons.fact_check, AppTheme.accent),
                  _Stat('In review', '${s['in_review'] ?? 0}', Icons.hourglass_bottom, AppTheme.warning),
                  _Stat('Completed', '${s['completed'] ?? 0}', Icons.check_circle, AppTheme.success),
                  _Stat('High risk', '${s['high_risk'] ?? 0}', Icons.warning, AppTheme.danger),
                  _Stat('Fayda verified', '${s['fayda_verified'] ?? 0}', Icons.verified_user, AppTheme.primaryDark),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Risk distribution', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 200,
                    child: PieChart(PieChartData(sections: [
                      PieChartSectionData(value: (s['total_checks'] ?? 1).toDouble() - (s['high_risk'] ?? 0).toDouble() - (s['critical_risk'] ?? 0).toDouble(),
                          color: AppTheme.success, title: 'Low/Med', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      PieChartSectionData(value: (s['high_risk'] ?? 0).toDouble(), color: AppTheme.warning, title: 'High',
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      PieChartSectionData(value: (s['critical_risk'] ?? 0).toDouble(), color: AppTheme.danger, title: 'Critical',
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ])),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/hr/candidates'),
                icon: const Icon(Icons.people), label: const Text('Browse candidates'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}
