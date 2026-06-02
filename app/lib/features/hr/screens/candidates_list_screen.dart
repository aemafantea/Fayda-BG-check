import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/db_status_banner.dart';
import '../../shared/widgets/status_badge.dart';

class CandidatesListScreen extends ConsumerStatefulWidget {
  const CandidatesListScreen({super.key});
  @override
  ConsumerState<CandidatesListScreen> createState() =>
      _CandidatesListScreenState();
}

class _CandidatesListScreenState extends ConsumerState<CandidatesListScreen> {
  final _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(bgCheckRepoProvider).candidateSummaries();
  }

  void _runSearch() {
    setState(() {
      _future = ref
          .read(bgCheckRepoProvider)
          .candidateSummaries(search: _search.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidates')),
      body: Column(
        children: [
          const DbStatusBanner(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name…',
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _runSearch();
                        },
                      ),
              ),
              onSubmitted: (_) => _runSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _runSearch(),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('Error: ${snap.error}',
                            textAlign: TextAlign.center));
                  }
                  final list = snap.data ?? const [];
                  if (list.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 100),
                      Icon(Icons.people_outline,
                          size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 12),
                      Center(child: Text('No candidates yet')),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final name = (c['full_name'] ?? '?').toString();
                      final initial = name.trim().isEmpty
                          ? '?'
                          : name.trim().characters.first.toUpperCase();
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primary.withOpacity(.1),
                            child: Text(initial,
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                          title: Text(name),
                          subtitle: Text(
                              '${c['current_position'] ?? 'No position'} • '
                              '${c['verified_jobs'] ?? 0}/${c['total_jobs'] ?? 0} jobs verified'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge.fromStatus(
                                  c['fayda_verification_status']?.toString()),
                              const SizedBox(width: 6),
                              if (c['latest_risk'] != null)
                                StatusBadge.fromRisk(
                                    c['latest_risk']?.toString()),
                            ],
                          ),
                          onTap: () =>
                              context.go('/hr/candidate/${c['candidate_id']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
