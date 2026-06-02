import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/status_badge.dart';

class CandidatesListScreen extends ConsumerStatefulWidget {
  const CandidatesListScreen({super.key});
  @override
  ConsumerState<CandidatesListScreen> createState() => _CandidatesListScreenState();
}

class _CandidatesListScreenState extends ConsumerState<CandidatesListScreen> {
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(bgCheckRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidates')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Search by name…'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: repo.candidateSummaries(search: _search.text),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty) return const Center(child: Text('No candidates'));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final c = list[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(.1),
                        child: Text((c['full_name'] ?? '?').toString().characters.first,
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(c['full_name'] ?? '—'),
                      subtitle: Text('${c['current_position'] ?? 'No position'} • '
                          '${c['verified_jobs'] ?? 0}/${c['total_jobs'] ?? 0} jobs verified'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        StatusBadge.fromStatus(c['fayda_verification_status']),
                        const SizedBox(width: 6),
                        if (c['latest_risk'] != null) StatusBadge.fromRisk(c['latest_risk']),
                      ]),
                      onTap: () => context.go('/hr/candidate/${c['candidate_id']}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
