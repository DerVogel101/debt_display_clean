import 'package:flutter/material.dart';

import '../ui/app_shared.dart';

enum AppThemeMode { light, auto, dark }

enum DarkThemePalette { dracula, moonlight, nightOwl }

extension AppThemeModeLabel on AppThemeMode {
  String get label => switch (this) {
    AppThemeMode.light => 'Light',
    AppThemeMode.auto => 'Auto',
    AppThemeMode.dark => 'Dark',
  };
}

extension DarkThemePaletteLabel on DarkThemePalette {
  String get label => switch (this) {
    DarkThemePalette.dracula => 'Dracula',
    DarkThemePalette.moonlight => 'Moonlight',
    DarkThemePalette.nightOwl => 'Night Owl',
  };
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    brightness: Brightness.light,
  );

  return _buildThemeData(scheme);
}

ThemeData buildDarkTheme(DarkThemePalette palette) {
  final scheme = switch (palette) {
    DarkThemePalette.dracula => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFBD93F9),
      onPrimary: Color(0xFF1E1F29),
      primaryContainer: Color(0xFF44475A),
      onPrimaryContainer: Color(0xFFF8F8F2),
      secondary: Color(0xFF8BE9FD),
      onSecondary: Color(0xFF15262B),
      secondaryContainer: Color(0xFF2D3A4A),
      onSecondaryContainer: Color(0xFFF1FA8C),
      tertiary: Color(0xFFFF79C6),
      onTertiary: Color(0xFF2D1227),
      tertiaryContainer: Color(0xFF4B2147),
      onTertiaryContainer: Color(0xFFFFD6EC),
      error: Color(0xFFFF5555),
      onError: Color(0xFF2D0F11),
      errorContainer: Color(0xFF5A2528),
      onErrorContainer: Color(0xFFFFDAD7),
      surface: Color(0xFF191A21),
      onSurface: Color(0xFFF8F8F2),
      surfaceContainerHighest: Color(0xFF3A3C4E),
      onSurfaceVariant: Color(0xFFCCD0E3),
      outline: Color(0xFF70758E),
      outlineVariant: Color(0xFF44475A),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFF8F8F2),
      onInverseSurface: Color(0xFF1E1F29),
      inversePrimary: Color(0xFF6F4AB7),
    ),
    DarkThemePalette.moonlight => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF82AAFF),
      onPrimary: Color(0xFF0B1120),
      primaryContainer: Color(0xFF2A3359),
      onPrimaryContainer: Color(0xFFD9E6FF),
      secondary: Color(0xFFC3E88D),
      onSecondary: Color(0xFF102211),
      secondaryContainer: Color(0xFF2B3B28),
      onSecondaryContainer: Color(0xFFE1F6C3),
      tertiary: Color(0xFFF78C6C),
      onTertiary: Color(0xFF30140B),
      tertiaryContainer: Color(0xFF5C2F1D),
      onTertiaryContainer: Color(0xFFFFDBC8),
      error: Color(0xFFFF757F),
      onError: Color(0xFF33090E),
      errorContainer: Color(0xFF5F2028),
      onErrorContainer: Color(0xFFFFDAD9),
      surface: Color(0xFF1E2030),
      onSurface: Color(0xFFD4D9E9),
      surfaceContainerHighest: Color(0xFF3A3F5A),
      onSurfaceVariant: Color(0xFFBAC3DD),
      outline: Color(0xFF7680A4),
      outlineVariant: Color(0xFF3B4261),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFDDE3F5),
      onInverseSurface: Color(0xFF171A26),
      inversePrimary: Color(0xFF305FAF),
    ),
    DarkThemePalette.nightOwl => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF82AAFF),
      onPrimary: Color(0xFF08151F),
      primaryContainer: Color(0xFF1F3958),
      onPrimaryContainer: Color(0xFFD6E5FF),
      secondary: Color(0xFFC792EA),
      onSecondary: Color(0xFF22142A),
      secondaryContainer: Color(0xFF473159),
      onSecondaryContainer: Color(0xFFF0D9FF),
      tertiary: Color(0xFF7FDBCA),
      onTertiary: Color(0xFF07211D),
      tertiaryContainer: Color(0xFF224843),
      onTertiaryContainer: Color(0xFFC6FFF4),
      error: Color(0xFFFF6363),
      onError: Color(0xFF330D0D),
      errorContainer: Color(0xFF5B2323),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF011627),
      onSurface: Color(0xFFD6DEEB),
      surfaceContainerHighest: Color(0xFF2D3F56),
      onSurfaceVariant: Color(0xFFA8B7CB),
      outline: Color(0xFF6D8098),
      outlineVariant: Color(0xFF2A3A4E),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE4EBF7),
      onInverseSurface: Color(0xFF102033),
      inversePrimary: Color(0xFF4A7ACC),
    ),
  };

  return _buildThemeData(scheme);
}

ThemeData _buildThemeData(ColorScheme scheme) {
  final base = ThemeData(
    colorScheme: scheme,
    brightness: scheme.brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface.withValues(alpha: 0.96),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow.withValues(alpha: 0.14),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant;
        return IconThemeData(color: color);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant;
        return base.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        );
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurface;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHigh;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.primary.withValues(alpha: 0.2),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      labelStyle: base.textTheme.labelLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

LinearGradient buildAppBackgroundGradient(ThemeData theme) {
  final scheme = theme.colorScheme;

  if (theme.brightness == Brightness.dark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.surface,
        Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.16),
          scheme.surface,
        ),
        Color.alphaBlend(
          scheme.secondary.withValues(alpha: 0.12),
          scheme.surface,
        ),
      ],
      stops: const [0, 0.5, 1],
    );
  }

  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.alphaBlend(scheme.primary.withValues(alpha: 0.10), Colors.white),
      Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.08), Colors.white),
      Color.alphaBlend(scheme.secondary.withValues(alpha: 0.06), Colors.white),
    ],
    stops: const [0, 0.55, 1],
  );
}
