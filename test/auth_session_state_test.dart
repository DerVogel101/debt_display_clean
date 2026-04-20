import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/config/app_config.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSessionState.resolveDisplayNameForUser', () {
    test('prefers the custom full name claim over other fields', () {
      const customFullName = 'Metadata Full Name';
      final user = UserProfile(
        sub: 'auth0|user',
        name: 'Root Name',
        nickname: 'Nickname',
        email: 'user@example.com',
        customClaims: {
          AppConfig.defaultAuth0FullNameClaim: customFullName,
        },
      );

      final displayName = AuthSessionState.resolveDisplayNameForUser(user);

      expect(displayName, customFullName);
    });

    test('prefers the backend display name over token fields', () {
      final user = UserProfile(
        sub: 'auth0|user',
        name: 'Root Name',
        nickname: 'Nickname',
        email: 'user@example.com',
      );

      final displayName = AuthSessionState.resolveDisplayNameForUser(
        user,
        backendName: 'Backend Name',
      );

      expect(displayName, 'Backend Name');
    });

    test('falls back to the token name when the custom claim is missing', () {
      final user = UserProfile(
        sub: 'auth0|user',
        name: 'Root Name',
        nickname: 'Nickname',
        email: 'user@example.com',
      );

      final displayName = AuthSessionState.resolveDisplayNameForUser(user);

      expect(displayName, 'Root Name');
    });

    test('falls back to nickname when custom claim and name are missing', () {
      final user = UserProfile(
        sub: 'auth0|user',
        nickname: 'Nickname',
        email: 'user@example.com',
      );

      final displayName = AuthSessionState.resolveDisplayNameForUser(user);

      expect(displayName, 'Nickname');
    });

    test('falls back to the email local part when no name fields exist', () {
      final user = UserProfile(
        sub: 'auth0|user',
        email: 'user@example.com',
      );

      final displayName = AuthSessionState.resolveDisplayNameForUser(user);

      expect(displayName, 'user');
    });
  });

  group('AuthSessionState.resolvePersistedNameForUser', () {
    test('prefers the custom full name claim over token fields', () {
      const customFullName = 'Metadata Full Name';
      final user = UserProfile(
        sub: 'auth0|user',
        name: 'Root Name',
        nickname: 'Nickname',
        email: 'user@example.com',
        customClaims: {
          AppConfig.defaultAuth0FullNameClaim: customFullName,
        },
      );

      final persistedName = AuthSessionState.resolvePersistedNameForUser(user);

      expect(persistedName, customFullName);
    });

    test('falls back to the token name when the custom claim is missing', () {
      final user = UserProfile(
        sub: 'auth0|user',
        name: 'Root Name',
        nickname: 'Nickname',
        email: 'user@example.com',
      );

      final persistedName = AuthSessionState.resolvePersistedNameForUser(user);

      expect(persistedName, 'Root Name');
    });

    test('returns null when only nickname and email are present', () {
      final user = UserProfile(
        sub: 'auth0|user',
        nickname: 'Nickname',
        email: 'user@example.com',
      );

      final persistedName = AuthSessionState.resolvePersistedNameForUser(user);

      expect(persistedName, isNull);
    });
  });
}
