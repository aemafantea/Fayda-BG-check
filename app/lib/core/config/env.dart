/// Compile-time environment configuration.
/// Pass values via `--dart-define`, e.g.:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dzqinurnkdcwhsbfmzrm.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'REPLACE_WITH_YOUR_ANON_KEY',
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
