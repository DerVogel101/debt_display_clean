import 'package:flutter/material.dart';

const brandPrimary = Color(0xFF667EEA);

enum AppGlassVariant { primary, secondary, chrome }

class AppGlassStyle {
  const AppGlassStyle({
    required this.fillGradient,
    required this.borderColor,
    required this.shadows,
  });

  final Gradient fillGradient;
  final Color borderColor;
  final List<BoxShadow> shadows;
}

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

Color _blendColor(Color base, Color tint, double alpha) {
  return Color.alphaBlend(tint.withValues(alpha: alpha), base);
}

AppGlassStyle appGlassStyle(
  ThemeData theme, {
  AppGlassVariant variant = AppGlassVariant.primary,
  Color? tone,
}) {
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final baseSurface = switch (variant) {
    AppGlassVariant.primary => scheme.surface,
    AppGlassVariant.secondary => _blendColor(
      scheme.surface,
      scheme.surfaceContainerHighest,
      isDark ? 0.46 : 0.22,
    ),
    AppGlassVariant.chrome => _blendColor(
      scheme.surface,
      scheme.primary,
      isDark ? 0.12 : 0.05,
    ),
  };
  final fillBase = baseSurface.withValues(
    alpha: switch (variant) {
      AppGlassVariant.primary => isDark ? 0.84 : 0.74,
      AppGlassVariant.secondary => isDark ? 0.78 : 0.68,
      AppGlassVariant.chrome => isDark ? 0.74 : 0.64,
    },
  );

  var topColor = _blendColor(
    fillBase,
    Colors.white,
    switch (variant) {
      AppGlassVariant.primary => isDark ? 0.12 : 0.58,
      AppGlassVariant.secondary => isDark ? 0.09 : 0.44,
      AppGlassVariant.chrome => isDark ? 0.18 : 0.74,
    },
  );
  var middleColor = _blendColor(
    fillBase,
    scheme.primary,
    switch (variant) {
      AppGlassVariant.primary => isDark ? 0.12 : 0.05,
      AppGlassVariant.secondary => isDark ? 0.09 : 0.04,
      AppGlassVariant.chrome => isDark ? 0.18 : 0.08,
    },
  );
  var bottomColor = _blendColor(
    fillBase,
    scheme.secondary,
    switch (variant) {
      AppGlassVariant.primary => isDark ? 0.10 : 0.05,
      AppGlassVariant.secondary => isDark ? 0.08 : 0.04,
      AppGlassVariant.chrome => isDark ? 0.12 : 0.06,
    },
  );

  if (tone != null) {
    topColor = _blendColor(topColor, tone, isDark ? 0.20 : 0.12);
    middleColor = _blendColor(middleColor, tone, isDark ? 0.16 : 0.10);
    bottomColor = _blendColor(bottomColor, tone, isDark ? 0.12 : 0.08);
  }

  final borderBase = scheme.outlineVariant.withValues(
    alpha: switch (variant) {
      AppGlassVariant.primary => isDark ? 0.62 : 0.24,
      AppGlassVariant.secondary => isDark ? 0.52 : 0.20,
      AppGlassVariant.chrome => isDark ? 0.70 : 0.30,
    },
  );
  final borderColor = tone == null
      ? borderBase
      : _blendColor(borderBase, tone, isDark ? 0.36 : 0.18);

  final shadowColor = scheme.shadow.withValues(
    alpha: switch (variant) {
      AppGlassVariant.primary => isDark ? 0.22 : 0.09,
      AppGlassVariant.secondary => isDark ? 0.18 : 0.06,
      AppGlassVariant.chrome => isDark ? 0.20 : 0.08,
    },
  );
  final ambientShadowColor = scheme.shadow.withValues(
    alpha: switch (variant) {
      AppGlassVariant.primary => isDark ? 0.08 : 0.03,
      AppGlassVariant.secondary => isDark ? 0.06 : 0.02,
      AppGlassVariant.chrome => isDark ? 0.07 : 0.025,
    },
  );

  return AppGlassStyle(
    fillGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [topColor, middleColor, bottomColor],
      stops: const [0, 0.38, 1],
    ),
    borderColor: borderColor,
    shadows: [
      BoxShadow(
        color: shadowColor,
        blurRadius: switch (variant) {
          AppGlassVariant.primary => 30,
          AppGlassVariant.secondary => 22,
          AppGlassVariant.chrome => 26,
        },
        offset: switch (variant) {
          AppGlassVariant.primary => const Offset(0, 18),
          AppGlassVariant.secondary => const Offset(0, 12),
          AppGlassVariant.chrome => const Offset(0, 14),
        },
      ),
      BoxShadow(
        color: ambientShadowColor,
        blurRadius: switch (variant) {
          AppGlassVariant.primary => 14,
          AppGlassVariant.secondary => 10,
          AppGlassVariant.chrome => 12,
        },
        offset: switch (variant) {
          AppGlassVariant.primary => const Offset(0, 6),
          AppGlassVariant.secondary => const Offset(0, 4),
          AppGlassVariant.chrome => const Offset(0, 5),
        },
      ),
    ],
  );
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
    fontFamily: 'RobotoLocal',
    scaffoldBackgroundColor: Colors.transparent,
  );
  final isDark = scheme.brightness == Brightness.dark;

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface.withValues(alpha: isDark ? 0.82 : 0.68),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.18 : 0.08),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          _blendColor(
            scheme.surface.withValues(alpha: isDark ? 0.92 : 0.86),
            Colors.white,
            isDark ? 0.06 : 0.12,
          ),
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.34)),
        ),
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
              ? scheme.primary.withValues(alpha: isDark ? 0.86 : 0.90)
              : scheme.surface.withValues(alpha: isDark ? 0.34 : 0.44);
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.42)),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: _blendColor(
        scheme.surface.withValues(alpha: isDark ? 0.42 : 0.56),
        scheme.primary,
        isDark ? 0.10 : 0.04,
      ),
      selectedColor: scheme.primary.withValues(alpha: 0.2),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.42)),
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
          scheme.primary.withValues(alpha: 0.18),
          scheme.surface,
        ),
        Color.alphaBlend(
          scheme.secondary.withValues(alpha: 0.12),
          scheme.surface,
        ),
        Color.alphaBlend(
          scheme.tertiary.withValues(alpha: 0.08),
          scheme.surface,
        ),
      ],
      stops: const [0, 0.38, 0.74, 1],
    );
  }

  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.alphaBlend(scheme.primary.withValues(alpha: 0.12), Colors.white),
      Color.alphaBlend(
        scheme.tertiary.withValues(alpha: 0.10),
        const Color(0xFFFCFDFF),
      ),
      Color.alphaBlend(
        scheme.secondary.withValues(alpha: 0.07),
        const Color(0xFFF6FAFF),
      ),
      Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.04),
        const Color(0xFFFDFEFF),
      ),
    ],
    stops: const [0, 0.34, 0.72, 1],
  );
}
