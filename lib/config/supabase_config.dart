/// Supabase connection settings.
///
/// Values are read at build time from `--dart-define` (most easily via
/// `--dart-define-from-file=.env`) and fall back to the project's public
/// defaults, so the app still runs with zero local setup.
///
/// The anon key is a **public** client key — access is enforced server-side by
/// Row Level Security — so it is safe to ship in a client bundle. Never put a
/// service-role or other secret key here.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://orvatsbznbcccrhooxmk.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ydmF0c2J6bmJjY2NyaG9veG1rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3MjAwODYsImV4cCI6MjA5NTI5NjA4Nn0.ysQkSKbodO5qMZkPFL2KOVR2CXtvtPudaa1ebRp0hOc',
  );
}
