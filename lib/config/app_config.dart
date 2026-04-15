import 'package:flutter/services.dart';

abstract final class AppConfig {
  static const String _assetPath = 'assets/env/app.env';

  static late final String backendUrl;
  static late final String frontendUrl;
  static late final String auth0Domain;
  static late final String auth0ClientId;
  static late final String auth0Audience;

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) {
      return;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final values = <String, String>{};

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final separatorIndex = trimmed.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }
      final key = trimmed.substring(0, separatorIndex).trim();
      final value = trimmed.substring(separatorIndex + 1).trim();
      values[key] = value;
    }

    backendUrl = values['BACKEND_URL'] ?? 'http://localhost:3300';
    frontendUrl = values['FRONTEND_URL'] ?? 'http://localhost:3000';
    auth0Domain = values['AUTH0_DOMAIN'] ?? '';
    auth0ClientId = values['AUTH0_CLIENT_ID'] ?? '';
    auth0Audience = values['AUTH0_AUDIENCE'] ?? '';
    _loaded = true;
  }
}
