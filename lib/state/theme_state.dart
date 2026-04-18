import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_themes.dart';

class ThemeState extends ChangeNotifier {
  static const _themeModeKey = 'theme.mode';
  static const _darkPaletteKey = 'theme.darkPalette';

  AppThemeMode _themeMode = AppThemeMode.auto;
  DarkThemePalette _darkPalette = DarkThemePalette.dracula;

  AppThemeMode get themeMode => _themeMode;
  DarkThemePalette get darkPalette => _darkPalette;

  ThemeMode get materialThemeMode => switch (_themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.auto => ThemeMode.system,
    AppThemeMode.dark => ThemeMode.dark,
  };

  ThemeData get lightTheme => buildLightTheme();
  ThemeData get darkTheme => buildDarkTheme(_darkPalette);
  bool get showDarkPalettePicker => _themeMode != AppThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_themeModeKey);
    final darkPaletteName = prefs.getString(_darkPaletteKey);

    _themeMode = _parseThemeMode(modeName) ?? AppThemeMode.auto;
    _darkPalette =
        _parseDarkThemePalette(darkPaletteName) ?? DarkThemePalette.dracula;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setDarkPalette(DarkThemePalette palette) async {
    if (_darkPalette == palette) {
      return;
    }
    _darkPalette = palette;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_darkPaletteKey, palette.name);
  }

  AppThemeMode? _parseThemeMode(String? value) {
    for (final mode in AppThemeMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return null;
  }

  DarkThemePalette? _parseDarkThemePalette(String? value) {
    for (final palette in DarkThemePalette.values) {
      if (palette.name == value) {
        return palette;
      }
    }
    return null;
  }
}
