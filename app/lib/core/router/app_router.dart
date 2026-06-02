import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/fayda_verify_screen.dart';
import '../../features/candidate/screens/candidate_dashboard.dart';
import '../../features/candidate/screens/employment_history_screen.dart';
import '../../features/candidate/screens/documents_screen.dart';
import '../../features/candidate/screens/profile_edit_screen.dart';
import '../../features/hr/screens/hr_dashboard.dart';
import '../../features/hr/screens/candidates_list_screen.dart';
import '../../features/hr/screens/candidate_detail_screen.dart';
import '../../features/hr/screens/bg_check_detail_screen.dart';
import '../../features/hr/screens/new_bg_check_screen.dart';
import '../../features/admin/screens/admin_dashboard.dart';
import '../../features/admin/screens/users_screen.dart';
import '../../features/admin/screens/audit_log_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../data/repositories/auth_repository.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authChange = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(authChange),
    redirect: (ctx, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loc = state.matchedLocation;

      // From splash, always jump somewhere
      if (loc == '/splash') {
        return session == null ? '/auth/sign-in' : '/home';
      }

      // Protect non-auth routes
      final isAuthRoute = loc.startsWith('/auth');
      if (session == null && !isAuthRoute) return '/auth/sign-in';

      // Already signed in but visiting sign-in/up
      if (session != null && (loc == '/auth/sign-in' || loc == '/auth/sign-up')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/auth/sign-up', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/auth/fayda-verify', builder: (_, __) => const FaydaVerifyScreen()),

      // Role-based shell. We dispatch the right dashboard based on user role.
      GoRoute(path: '/home', builder: (_, __) => const _HomeDispatcher()),

      // Candidate
      GoRoute(path: '/candidate', builder: (_, __) => const CandidateDashboard(), routes: [
        GoRoute(path: 'profile', builder: (_, __) => const ProfileEditScreen()),
        GoRoute(path: 'employment', builder: (_, __) => const EmploymentHistoryScreen()),
        GoRoute(path: 'documents', builder: (_, __) => const DocumentsScreen()),
      ]),

      // HR
      GoRoute(path: '/hr', builder: (_, __) => const HrDashboard(), routes: [
        GoRoute(path: 'candidates', builder: (_, __) => const CandidatesListScreen()),
        GoRoute(path: 'candidate/:id', builder: (c, s) => CandidateDetailScreen(candidateId: s.pathParameters['id']!)),
        GoRoute(path: 'check/:id', builder: (c, s) => BgCheckDetailScreen(checkId: s.pathParameters['id']!)),
        GoRoute(path: 'new-check', builder: (_, __) => const NewBgCheckScreen()),
      ]),

      // Admin
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard(), routes: [
        GoRoute(path: 'users', builder: (_, __) => const UsersScreen()),
        GoRoute(path: 'audit', builder: (_, __) => const AuditLogScreen()),
      ]),

      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(AsyncValue<AuthState> change) {
    change.whenData((_) => notifyListeners());
  }
}

class _HomeDispatcher extends ConsumerStatefulWidget {
  const _HomeDispatcher();
  @override
  ConsumerState<_HomeDispatcher> createState() => _HomeDispatcherState();
}

class _HomeDispatcherState extends ConsumerState<_HomeDispatcher> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Could not load profile:\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(currentProfileProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/auth/sign-in');
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (p) {
        if (_navigated) return const Scaffold(body: SizedBox.shrink());
        _navigated = true;
        // Default to candidate if profile row not ready yet (will reconcile after refresh)
        final target = switch (p?.role) {
          'admin' => '/admin',
          'hr'    => '/hr',
          _       => '/candidate',
        };
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(target);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
