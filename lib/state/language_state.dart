import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguageMode { auto, english, german }

class LanguageState extends ChangeNotifier {
  static const _languageModeKey = 'language.mode';

  AppLanguageMode _languageMode = AppLanguageMode.auto;

  AppLanguageMode get languageMode => _languageMode;

  Locale? get locale => switch (_languageMode) {
    AppLanguageMode.auto => null,
    AppLanguageMode.english => const Locale('en'),
    AppLanguageMode.german => const Locale('de'),
  };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_languageModeKey);
    _languageMode = _parseLanguageMode(modeName) ?? AppLanguageMode.auto;
    notifyListeners();
  }

  Future<void> setLanguageMode(AppLanguageMode mode) async {
    if (_languageMode == mode) {
      return;
    }
    _languageMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageModeKey, mode.name);
  }

  AppLanguageMode? _parseLanguageMode(String? value) {
    for (final mode in AppLanguageMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return null;
  }
}
