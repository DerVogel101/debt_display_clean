import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyConsentState extends ChangeNotifier {
  PrivacyConsentState({this.policyVersion = currentPolicyVersion});

  @visibleForTesting
  PrivacyConsentState.test({
    this.policyVersion = currentPolicyVersion,
    bool hasAcceptedCurrentVersion = true,
  }) : _isLoading = false,
       _acceptedVersion = hasAcceptedCurrentVersion ? policyVersion : null,
       _acceptedAt = hasAcceptedCurrentVersion
           ? DateTime.utc(2026, 5, 10)
           : null;

  static const currentPolicyVersion = '2026-05-10';
  static const consentVersionKey = 'privacy.consent.version';
  static const consentAcceptedAtKey = 'privacy.consent.acceptedAt';

  final String policyVersion;

  bool _isLoading = true;
  String? _acceptedVersion;
  DateTime? _acceptedAt;

  bool get isLoading => _isLoading;
  String? get acceptedVersion => _acceptedVersion;
  DateTime? get acceptedAt => _acceptedAt;

  bool get hasAcceptedCurrentVersion =>
      !_isLoading && _acceptedVersion == policyVersion;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _acceptedVersion = prefs.getString(consentVersionKey);
    final acceptedAtRaw = prefs.getString(consentAcceptedAtKey);
    _acceptedAt = acceptedAtRaw == null
        ? null
        : DateTime.tryParse(acceptedAtRaw);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> accept() async {
    final acceptedAt = DateTime.now().toUtc();
    _acceptedVersion = policyVersion;
    _acceptedAt = acceptedAt;
    _isLoading = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(consentVersionKey, policyVersion);
    await prefs.setString(consentAcceptedAtKey, acceptedAt.toIso8601String());
  }

  Future<void> revoke() async {
    _acceptedVersion = null;
    _acceptedAt = null;
    _isLoading = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(consentVersionKey);
    await prefs.remove(consentAcceptedAtKey);
  }
}
