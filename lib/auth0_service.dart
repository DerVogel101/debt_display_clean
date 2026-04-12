import 'package:auth0_flutter/auth0_flutter_web.dart';

class Auth0Service {
  static final Auth0Service _instance = Auth0Service._internal();
  late final Auth0Web auth0Web;

  factory Auth0Service() {
    return _instance;
  }

  Auth0Service._internal() {
    auth0Web = Auth0Web(
      const String.fromEnvironment('AUTH0_DOMAIN'),        // Replace with your Auth0 domain
      const String.fromEnvironment('AUTH0_CLIENT_ID'),     // Replace with your Client ID
      cacheLocation: CacheLocation.localStorage, // Persist sessions
    );
  }
}