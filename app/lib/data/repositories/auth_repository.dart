import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseProvider).auth.currentUser;
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final sb = ref.watch(supabaseProvider);

  // Synthetic fallback from auth metadata if DB row missing / schema not yet applied.
  Profile synthetic() {
    final meta = user.userMetadata ?? {};
    return Profile(
      id: user.id,
      role: (meta['role'] as String?) ?? 'candidate',
      fullName: (meta['full_name'] as String?) ?? user.email?.split('@').first,
    );
  }

  try {
    final res = await sb.from('profiles').select().eq('id', user.id).maybeSingle();
    if (res == null) return synthetic();
    return Profile.fromMap(res);
  } catch (_) {
    // Schema not yet applied or RLS blocking — still let the user in
    return synthetic();
  }
});

class AuthRepository {
  final SupabaseClient _sb;
  AuthRepository(this._sb);

  Future<AuthResponse> signIn(String email, String password) =>
      _sb.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'candidate',
  }) =>
      _sb.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

  Future<void> signOut() => _sb.auth.signOut();

  Future<void> resetPassword(String email) => _sb.auth.resetPasswordForEmail(email);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});
