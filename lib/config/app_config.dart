/// Compile-time environment configuration.
///
/// Dev (flutter run / flutter build web):
///   uses hardcoded defaults — Flutter :3000, backend :3300
///
/// Prod override via --dart-define at build time:
///   flutter build web \
///     --dart-define=BACKEND_URL=https://api.example.com \
///     --dart-define=FRONTEND_URL=https://app.example.com
abstract final class AppConfig {
  /// Base URL of the FastAPI backend (no trailing slash).
  /// Dev default: http://localhost:3300
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3300',
  );

  /// URL this Flutter app is served from — used for Auth0 redirect/logout URLs.
  /// Dev default: http://localhost:3000
  static const String frontendUrl = String.fromEnvironment(
    'FRONTEND_URL',
    defaultValue: 'http://localhost:3000',
  );
}
