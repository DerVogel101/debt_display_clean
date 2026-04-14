import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'config/app_config.dart';

class Auth0Service {
  static final Auth0Service _instance = Auth0Service._internal();
  late final Auth0Web auth0Web;

  factory Auth0Service() {
    return _instance;
  }

  Auth0Service._internal() {
    auth0Web = Auth0Web(
      const String.fromEnvironment('AUTH0_DOMAIN'),
      const String.fromEnvironment('AUTH0_CLIENT_ID'),
      redirectUrl: AppConfig.frontendUrl,
      cacheLocation: CacheLocation.localStorage, // Persist sessions
    );
  }
}
