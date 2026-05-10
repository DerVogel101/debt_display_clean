import 'package:debt_display/state/privacy_consent_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('privacy consent defaults to not accepted', () async {
    SharedPreferences.setMockInitialValues({});
    final state = PrivacyConsentState();

    await state.load();

    expect(state.isLoading, isFalse);
    expect(state.hasAcceptedCurrentVersion, isFalse);
    expect(state.acceptedVersion, isNull);
    expect(state.acceptedAt, isNull);
  });

  test('privacy consent persists the current version and timestamp', () async {
    SharedPreferences.setMockInitialValues({});
    final state = PrivacyConsentState();
    await state.load();

    await state.accept();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(PrivacyConsentState.consentVersionKey),
      PrivacyConsentState.currentPolicyVersion,
    );
    expect(
      DateTime.tryParse(
        prefs.getString(PrivacyConsentState.consentAcceptedAtKey)!,
      ),
      isNotNull,
    );
    expect(state.hasAcceptedCurrentVersion, isTrue);
  });

  test('privacy consent rejects an old accepted version', () async {
    SharedPreferences.setMockInitialValues({
      PrivacyConsentState.consentVersionKey: '2026-01-01',
      PrivacyConsentState.consentAcceptedAtKey: '2026-01-01T00:00:00.000Z',
    });
    final state = PrivacyConsentState();

    await state.load();

    expect(state.acceptedVersion, '2026-01-01');
    expect(state.acceptedAt, DateTime.utc(2026, 1, 1));
    expect(state.hasAcceptedCurrentVersion, isFalse);
  });

  test('privacy consent revoke clears persisted consent', () async {
    SharedPreferences.setMockInitialValues({
      PrivacyConsentState.consentVersionKey:
          PrivacyConsentState.currentPolicyVersion,
      PrivacyConsentState.consentAcceptedAtKey: '2026-05-10T00:00:00.000Z',
    });
    final state = PrivacyConsentState();
    await state.load();

    await state.revoke();

    final prefs = await SharedPreferences.getInstance();
    expect(state.hasAcceptedCurrentVersion, isFalse);
    expect(state.acceptedVersion, isNull);
    expect(state.acceptedAt, isNull);
    expect(prefs.getString(PrivacyConsentState.consentVersionKey), isNull);
    expect(prefs.getString(PrivacyConsentState.consentAcceptedAtKey), isNull);
  });
}
