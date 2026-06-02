import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/db_status_banner.dart';

class HrDashboard extends ConsumerStatefulWidget {
  const HrDashboard({super.key});
  @override
  ConsumerState<HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends ConsumerState<HrDashboard> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(bgCheckRepoProvider).dashboardStats();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ref.read(bgCheckRepoProvider).dashboardStats();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(role: 'hr'),
      appBar: AppBar(
        title: const Text('HR Consultant'),
        actions: [
          IconButton(
              icon: const Icon(Icons.add_task),
              tooltip: 'New BG check',
              onPressed: () => context.go('/hr/new-check')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final s = snap.data ?? const <String, dynamic>{};
            final tot = (s['total_checks'] ?? 0) as num;
            final hr = (s['high_risk'] ?? 0) as num;
            final crit = (s['critical_risk'] ?? 0) as num;
            final lowMed = (tot - hr - crit).clamp(0, double.infinity);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const DbStatusBanner(),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _Stat('Candidates', '${s['total_candidates'] ?? 0}',
                        Icons.people, AppTheme.primary),
                    _Stat('Total checks', '${s['total_checks'] ?? 0}',
                        Icons.fact_check, AppTheme.accent),
                    _Stat('In review', '${s['in_review'] ?? 0}',
                        Icons.hourglass_bottom, AppTheme.warning),
                    _Stat('Completed', '${s['completed'] ?? 0}',
                        Icons.check_circle, AppTheme.success),
                    _Stat('High risk', '${s['high_risk'] ?? 0}',
                        Icons.warning, AppTheme.danger),
                    _Stat('Fayda verified', '${s['fayda_verified'] ?? 0}',
                        Icons.verified_user, AppTheme.primaryDark),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Risk distribution',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: tot == 0
                          ? const Center(
                              child: Text('No checks yet',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary)))
                          : PieChart(PieChartData(sections: [
                              if (lowMed > 0)
                                PieChartSectionData(
                                    value: lowMed.toDouble(),
                                    color: AppTheme.success,
                                    title: 'Low/Med',
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              if (hr > 0)
                                PieChartSectionData(
                                    value: hr.toDouble(),
                                    color: AppTheme.warning,
                                    title: 'High',
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              if (crit > 0)
                                PieChartSectionData(
                                    value: crit.toDouble(),
                                    color: AppTheme.danger,
                                    title: 'Critical',
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                            ])),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/hr/candidates'),
                  icon: const Icon(Icons.people),
                  label: const Text('Browse candidates'),
                ),
              ],
            );
          },
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
