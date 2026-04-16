import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';

import 'auth0_service.dart';
import 'config/app_config.dart';
import 'services/auth_backend_service.dart';
import 'ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await Auth0Service.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'debt_display',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandPrimary),
        useMaterial3: true,
      ),
      home: const MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final auth0Service = Auth0Service();
  final authBackendService = AuthBackendService();
  Credentials? _credentials;
  bool _isLoading = true;
  String? _backendError;
  AppDestination _selectedDestination = AppDestination.home;

  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    try {
      final credentials = await auth0Service.auth0Web.onLoad(
        audience: AppConfig.auth0Audience.isNotEmpty
            ? AppConfig.auth0Audience
            : null,
      );
      if (credentials != null) {
        final backendResp = await authBackendService.login(
          credentials.accessToken,
          email: credentials.user.email,
          name: credentials.user.name,
          avatarUrl: credentials.user.pictureUrl?.toString(),
        );
        if (!backendResp.success) {
          if (authBackendService.isExpiredTokenMessage(backendResp.message)) {
            await _handleExpiredSession();
            return;
          }
          setState(() {
            _backendError = backendResp.message;
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _credentials = credentials;
        _isLoading = false;
      });
    } catch (e) {
      final msg = e.toString();
      // consent_required / login_required come from onLoad()'s silent iframe
      // check when no valid session exists — not a real error, just means the
      // user needs to log in interactively.
      if (msg.contains('consent_required') || msg.contains('login_required')) {
        setState(() => _isLoading = false);
        return;
      }
      if (authBackendService.isExpiredTokenMessage(msg)) {
        await _handleExpiredSession();
        return;
      }
      debugPrint('Error handling auth callback: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExpiredSession() async {
    try {
      await auth0Service.auth0Web.logout(returnToUrl: AppConfig.frontendUrl);
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _credentials = null;
        _backendError = 'Your session expired. Please log in again.';
        _isLoading = false;
      });
    }
  }

  /// Returns true if [token] is cryptographically valid and not expired.
  Future<bool> isTokenValid(String token) async {
    final resp = await authBackendService.verifyToken(token);
    if (!resp.valid && authBackendService.isExpiredTokenMessage(resp.message)) {
      await _handleExpiredSession();
      return false;
    }
    final notExpired =
        resp.expiresAt > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return resp.valid && notExpired;
  }

  Future<void> _login() async {
    await auth0Service.auth0Web.loginWithRedirect(
      redirectUrl: AppConfig.frontendUrl,
      audience: AppConfig.auth0Audience.isNotEmpty
          ? AppConfig.auth0Audience
          : null,
    );
  }

  Future<void> _logout() async {
    await auth0Service.auth0Web.logout(returnToUrl: AppConfig.frontendUrl);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      credentials: _credentials,
      isLoading: _isLoading,
      backendError: _backendError,
      selectedDestination: _selectedDestination,
      onDestinationSelected: (destination) {
        setState(() => _selectedDestination = destination);
      },
      onLogin: _login,
      onLogout: _logout,
    );
  }
}
