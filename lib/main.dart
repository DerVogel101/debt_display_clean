import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'auth0_service.dart';
import 'services/auth_backend_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth0 Flutter Web',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  Credentials? _credentials;
  bool _isLoading = true;
  String? _backendError;

  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    try {
      final credentials = await auth0Service.auth0Web.onLoad();
      if (credentials != null) {
        // Sync user with backend via Protobuf
        final backendResp = await AuthBackendService().login(
          credentials.accessToken,
        );
        if (!backendResp.success) {
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
      print('Error handling auth callback: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Returns true if [token] is cryptographically valid and not expired.
  Future<bool> isTokenValid(String token) async {
    final resp = await AuthBackendService().verifyToken(token);
    final notExpired =
        resp.expiresAt > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return resp.valid && notExpired;
  }

  Future<void> _login() async {
    await auth0Service.auth0Web.loginWithRedirect(
      redirectUrl: 'http://localhost:3000',
    );
  }

  Future<void> _logout() async {
    await auth0Service.auth0Web.logout(returnToUrl: 'http://localhost:3000');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_backendError != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Backend authentication failed: $_backendError',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.security,
                    size: 64,
                    color: Color(0xFF667eea),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Auth0 Flutter Web',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _credentials != null
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _credentials != null
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _credentials != null
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _credentials != null
                              ? 'You are logged in'
                              : 'You are logged out',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _credentials != null
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_credentials == null)
                    ElevatedButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login),
                      label: const Text('Log In'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    Column(
                      children: [
                        if (_credentials!.user.pictureUrl != null)
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              _credentials!.user.pictureUrl!.toString(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _credentials!.user.name ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _credentials!.user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileView(credentials: _credentials!),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person),
                              label: const Text('View Profile'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Out'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileView extends StatelessWidget {
  final Credentials credentials;

  const ProfileView({super.key, required this.credentials});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        if (credentials.user.pictureUrl != null)
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(
                              credentials.user.pictureUrl!.toString(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          credentials.user.name ?? 'User',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Profile Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Email', credentials.user.email ?? 'N/A'),
                  _buildInfoRow('Name', credentials.user.name ?? 'N/A'),
                  _buildInfoRow('Nickname', credentials.user.nickname ?? 'N/A'),
                  _buildInfoRow('User ID', credentials.user.sub),
                  const SizedBox(height: 24),
                  const Text(
                    'Raw User Object',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        credentials.user.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
