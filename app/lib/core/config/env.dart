/// Compile-time environment configuration.
/// Pass values via `--dart-define`, e.g.:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dzqinurnkdcwhsbfmzrm.supabase.co',
  );

  // Supabase publishable (anon) key — safe to embed in client code.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_n1NaCnYoEBYowZlvZ3TGlQ_kzMuzZa9',
  );

  static const String faydaRedirectScheme = String.fromEnvironment(
    'FAYDA_REDIRECT_SCHEME',
    defaultValue: 'io.supabase.faydabgcheck',
  );

  static const String appName = 'Fayda BG-Check';

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseAnonKey.startsWith('REPLACE_');
}
