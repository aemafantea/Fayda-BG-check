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
      final isAuth = loc.startsWith('/auth') || loc == '/splash';
      if (session == null && !isAuth) return '/auth/sign-in';
      if (session != null && loc == '/splash') return '/home';
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

class _HomeDispatcher extends ConsumerWidget {
  const _HomeDispatcher();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return profile.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (p) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          switch (p?.role) {
            case 'admin': context.go('/admin'); break;
            case 'hr': context.go('/hr'); break;
            default: context.go('/candidate');
          }
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
