import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';

String _initials(String? s) {
  final t = (s ?? '').trim();
  if (t.isEmpty) return '?';
  return t.characters.first.toUpperCase();
}

class AppDrawer extends ConsumerWidget {
  final String role;
  const AppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    final items = <_NavItem>[
      if (role == 'candidate') ...[
        _NavItem('Dashboard', Icons.dashboard, '/candidate'),
        _NavItem('My profile', Icons.person, '/candidate/profile'),
        _NavItem('Employment history', Icons.work, '/candidate/employment'),
        _NavItem('Documents', Icons.folder, '/candidate/documents'),
      ],
      if (role == 'hr') ...[
        _NavItem('Dashboard', Icons.dashboard, '/hr'),
        _NavItem('Candidates', Icons.people, '/hr/candidates'),
        _NavItem('New BG check', Icons.add_task, '/hr/new-check'),
      ],
      if (role == 'admin') ...[
        _NavItem('Dashboard', Icons.dashboard, '/admin'),
        _NavItem('Users', Icons.admin_panel_settings, '/admin/users'),
        _NavItem('Audit log', Icons.history, '/admin/audit'),
      ],
      _NavItem('Notifications', Icons.notifications, '/notifications'),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Text(
                      _initials(profile?.fullName),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.fullName ?? '—',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items
                    .map((i) => ListTile(
                          leading: Icon(i.icon),
                          title: Text(i.label),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(i.path);
                          },
                        ))
                    .toList(),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.danger),
              title: const Text('Sign out',
                  style: TextStyle(color: AppTheme.danger)),
              onTap: () async {
                final navContext = context;
                await ref.read(authRepositoryProvider).signOut();
                if (navContext.mounted) navContext.go('/auth/sign-in');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  _NavItem(this.label, this.icon, this.path);
}
