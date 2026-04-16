import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';

import '../auth0_service.dart';
import '../config/app_config.dart';
import '../services/auth_backend_service.dart';

class AuthSessionState extends ChangeNotifier {
  AuthSessionState({
    required Auth0Service auth0Service,
    required AuthBackendService authBackendService,
  }) : _auth0Service = auth0Service,
       _authBackendService = authBackendService;

  final Auth0Service _auth0Service;
  final AuthBackendService _authBackendService;

  Credentials? _credentials;
  bool _isLoading = true;
  String? _backendError;
  bool _hasStarted = false;

  Credentials? get credentials => _credentials;
  bool get isLoading => _isLoading;
  String? get backendError => _backendError;
  bool get isAuthenticated => _credentials != null;
  String? get userEmail => _credentials?.user.email;
  String get greeting {
    final name = displayName;
    if (name == null || name.isEmpty) {
      return 'Hi there';
    }
    return 'Hi, $name';
  }

  String? get displayName {
    final user = _credentials?.user;
    final name = user?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final nickname = user?.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return null;
  }

  Future<void> initialize() async {
    if (_hasStarted) {
      return;
    }
    _hasStarted = true;

    try {
      final credentials = await _auth0Service.auth0Web.onLoad(
        audience: AppConfig.auth0Audience.isNotEmpty
            ? AppConfig.auth0Audience
            : null,
      );
      if (credentials != null) {
        final backendResp = await _authBackendService.login(
          credentials.accessToken,
          email: credentials.user.email,
          name: credentials.user.name,
          avatarUrl: credentials.user.pictureUrl?.toString(),
        );

        if (!backendResp.success) {
          if (_authBackendService.isExpiredTokenMessage(backendResp.message)) {
            await _handleExpiredSession();
            return;
          }
          _backendError = backendResp.message;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _credentials = credentials;
      _backendError = null;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      final message = error.toString();
      if (message.contains('consent_required') ||
          message.contains('login_required')) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      if (_authBackendService.isExpiredTokenMessage(message)) {
        await _handleExpiredSession();
        return;
      }
      debugPrint('Error handling auth callback: $error');
      _backendError = message;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login() async {
    await _auth0Service.auth0Web.loginWithRedirect(
      redirectUrl: AppConfig.frontendUrl,
      audience: AppConfig.auth0Audience.isNotEmpty
          ? AppConfig.auth0Audience
          : null,
    );
  }

  Future<void> logout() async {
    await _auth0Service.auth0Web.logout(returnToUrl: AppConfig.frontendUrl);
  }

  Future<bool> isTokenValid(String token) async {
    final resp = await _authBackendService.verifyToken(token);
    if (!resp.valid &&
        _authBackendService.isExpiredTokenMessage(resp.message)) {
      await _handleExpiredSession();
      return false;
    }

    final notExpired =
        resp.expiresAt > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return resp.valid && notExpired;
  }

  Future<void> _handleExpiredSession() async {
    try {
      await _auth0Service.auth0Web.logout(returnToUrl: AppConfig.frontendUrl);
    } catch (_) {
      _credentials = null;
      _backendError = 'Your session expired. Please log in again.';
      _isLoading = false;
      notifyListeners();
    }
  }
}
