import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:debt_display/config/app_config.dart';

class Auth0Service {
  static Auth0Service? _instance;
  final Auth0Web auth0Web;

  factory Auth0Service() {
    final instance = _instance;
    if (instance == null) {
      throw StateError('Auth0Service.init() must be called before use.');
    }
    return instance;
  }

  Auth0Service._internal(this.auth0Web);

  static Future<void> init() async {
    if (_instance != null) {
      return;
    }
    await AppConfig.load();
    _instance = Auth0Service._internal(
      Auth0Web(
        AppConfig.auth0Domain,
        AppConfig.auth0ClientId,
        redirectUrl: AppConfig.frontendUrl,
        cacheLocation: CacheLocation.localStorage, // Persist sessions
      ),
    );
  }
}
