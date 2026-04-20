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
  String? _backendDisplayName;
  bool _hasStarted = false;

  Credentials? get credentials => _credentials;
  bool get isLoading => _isLoading;
  String? get backendError => _backendError;
  bool get isAuthenticated => _credentials != null;
  String? get userEmail => _credentials?.user.email;

  static String? resolvePersistedNameForUser(
    UserProfile? user, {
    String claimKey = AppConfig.defaultAuth0FullNameClaim,
    String? backendName,
  }) {
    final resolvedBackendName = _trimmedNonEmptyString(backendName);
    if (resolvedBackendName != null) {
      return resolvedBackendName;
    }

    final customFullName = _trimmedNonEmptyString(user?.customClaims?[claimKey]);
    if (customFullName != null) {
      return customFullName;
    }

    return _trimmedNonEmptyString(user?.name);
  }

  static String? resolveDisplayNameForUser(
    UserProfile? user, {
    String claimKey = AppConfig.defaultAuth0FullNameClaim,
    String? backendName,
  }) {
    final name = resolvePersistedNameForUser(
      user,
      claimKey: claimKey,
      backendName: backendName,
    );
    if (name != null) {
      return name;
    }

    final nickname = _trimmedNonEmptyString(user?.nickname);
    if (nickname != null) {
      return nickname;
    }

    final email = _trimmedNonEmptyString(user?.email);
    if (email != null) {
      return email.split('@').first;
    }

    return null;
  }

  String get greeting {
    final name = displayName;
    if (name == null || name.isEmpty) {
      return 'Hi there';
    }
    return 'Hi, $name';
  }

  String? get displayName {
    return resolveDisplayNameForUser(
      _credentials?.user,
      claimKey: AppConfig.auth0FullNameClaim,
      backendName: _backendDisplayName,
    );
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
        final persistedName = resolvePersistedNameForUser(
          credentials.user,
          claimKey: AppConfig.auth0FullNameClaim,
        );
        final backendResp = await _authBackendService.login(
          credentials.accessToken,
          email: credentials.user.email,
          name: persistedName,
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

        await _refreshBackendDisplayName(credentials.accessToken);
      } else {
        _backendDisplayName = null;
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
      _backendDisplayName = null;
      _backendError = 'Your session expired. Please log in again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshBackendDisplayName(String accessToken) async {
    final response = await _authBackendService.getMe(accessToken);
    if (!response.success) {
      if (_authBackendService.isExpiredTokenMessage(response.message)) {
        await _handleExpiredSession();
        return;
      }
      _backendDisplayName = null;
      return;
    }

    if (response.hasUser() && response.user.hasName()) {
      _backendDisplayName = _trimmedNonEmptyString(response.user.name);
      return;
    }

    _backendDisplayName = null;
  }

  static String? _trimmedNonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
