/// Compile-time environment configuration.
///
/// Dev (flutter run / flutter build web):
///   uses hardcoded defaults — Flutter :3000, backend :3300
///
/// Prod override via --dart-define at build time:
///   flutter build web \
///     --dart-define=BACKEND_URL=https://api.example.com \
///     --dart-define=FRONTEND_URL=https://app.example.com \
///     --dart-define=AUTH0_DOMAIN=your-tenant.us.auth0.com \
///     --dart-define=AUTH0_CLIENT_ID=xxx \
///     --dart-define=AUTH0_AUDIENCE=https://your-api-identifier
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

  /// Auth0 API audience identifier — must match AUTH0_AUDIENCE in the backend .env
  /// and the API identifier set in Auth0 Dashboard → Applications → APIs.
  /// Without this, Auth0 issues an opaque token instead of a verifiable JWT.
  static const String auth0Audience = String.fromEnvironment(
    'AUTH0_AUDIENCE',
    defaultValue: '',
  );
}
