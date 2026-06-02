import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/db_status_banner.dart';
import '../../shared/widgets/status_badge.dart';

class CandidateDashboard extends ConsumerWidget {
  const CandidateDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      drawer: const AppDrawer(role: 'candidate'),
      appBar: AppBar(title: const Text('My BG-Check')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const DbStatusBanner(),
              _WelcomeCard(name: profile.fullName ?? 'there'),
              const SizedBox(height: 16),
              if (!profile.isFaydaVerified) const _FaydaPromptCard(),
              if (!profile.isFaydaVerified) const SizedBox(height: 16),
              const Text('Profile completeness',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              _CompletenessTile(
                label: 'Personal information',
                done: (profile.fullName?.isNotEmpty ?? false) &&
                    (profile.phone?.isNotEmpty ?? false),
                onTap: () => context.go('/candidate/profile'),
              ),
              _CompletenessTile(
                label: 'Fayda identity verification',
                done: profile.isFaydaVerified,
                onTap: () => context.go('/auth/fayda-verify'),
              ),
              _CompletenessTile(
                label: 'Employment history',
                done: false,
                onTap: () => context.go('/candidate/employment'),
              ),
              _CompletenessTile(
                label: 'Documents',
                done: false,
                onTap: () => context.go('/candidate/documents'),
              ),
              const SizedBox(height: 24),
              const Text('Your background checks',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              _MyChecksList(profileId: profile.id),
            ],
          );
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi, $name 👋',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Complete your profile to be ready for instant background checks.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _FaydaPromptCard extends StatelessWidget {
  const _FaydaPromptCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.warning),
      ),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
        title: const Text('Verify your Fayda ID'),
        subtitle: const Text('Required for background-check eligibility.'),
        trailing: FilledButton(
          onPressed: () => context.go('/auth/fayda-verify'),
          child: const Text('Verify'),
        ),
      ),
    );
  }
}

class _CompletenessTile extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;
  const _CompletenessTile(
      {required this.label, required this.done, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppTheme.success : AppTheme.textSecondary,
        ),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MyChecksList extends ConsumerStatefulWidget {
  final String profileId;
  const _MyChecksList({required this.profileId});

  @override
  ConsumerState<_MyChecksList> createState() => _MyChecksListState();
}

class _MyChecksListState extends ConsumerState<_MyChecksList> {
  late Future<List<BackgroundCheck>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BackgroundCheck>> _load() async {
    final repo = ref.read(bgCheckRepoProvider);
    final cand = await repo.getOrCreateCandidate(widget.profileId);
    if (cand == null) return [];
    return repo.listChecks(candidateId: cand.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BackgroundCheck>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(child: ListTile(title: Text('Loading…')));
        }
        if (snap.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: AppTheme.danger),
              title: const Text('Couldn\'t load checks'),
              subtitle: Text('${snap.error}'),
            ),
          );
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.inbox),
              title: Text('No background checks yet'),
              subtitle: Text(
                  'An HR officer will create one and request your consent.'),
            ),
          );
        }
        return Column(
          children: list
              .map<Widget>((bg) => Card(
                    child: ListTile(
                      title: Text('Check #${bg.id.substring(0, 8)}'),
                      subtitle:
                          Text('Created ${bg.createdAt.toLocal()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge.fromStatus(bg.status),
                          const SizedBox(width: 8),
                          StatusBadge.fromRisk(bg.riskLevel),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
