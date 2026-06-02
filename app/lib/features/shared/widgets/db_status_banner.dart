import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/bg_check_repository.dart';

/// Shows a yellow banner when the Supabase schema hasn't been applied yet.
/// Hidden silently otherwise.
class DbStatusBanner extends ConsumerWidget {
  const DbStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ok = ref.watch(dbReadyProvider);
    if (ok) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Database not initialized',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sign-in works, but data features are read-only with empty results '
                  'until the SQL migrations are applied to Supabase.',
                  style: TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  TextButton.icon(
                    icon: const Icon(Icons.menu_book, size: 16),
                    label: const Text('See setup guide'),
                    onPressed: () => launchUrl(Uri.parse(
                        'https://github.com/aemafantea/Fayda-BG-check/blob/main/docs/DEPLOY.md')),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    onPressed: () => ref.read(dbReadyProvider.notifier).state = true,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
