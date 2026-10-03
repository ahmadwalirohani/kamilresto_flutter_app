import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const primaryTeal = Color(0xFF35B5AC);
  static const primaryNavy = Color(0xFF1C485E);
  static const brightTealAccent = Color(0xFF3CC1B7);
  static const softTeal = Color(0xFF5BA6A4);
  static const lightTeal = Color(0xFFA7D1D1);
  static const darkNavy = Color(0xFF183C4E);
  static const charcoal = Color(0xFF0B0D0E);
  static const appBackground = Color(0xFFF8FAFA);

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme() : _lightScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? darkNavy : Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ColorScheme _lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primaryTeal,
      onPrimary: Colors.white,
      primaryContainer: lightTeal,
      onPrimaryContainer: darkNavy,
      secondary: primaryNavy,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD7EAEB),
      onSecondaryContainer: darkNavy,
      tertiary: brightTealAccent,
      onTertiary: charcoal,
      tertiaryContainer: Color(0xFFC8EFEC),
      onTertiaryContainer: darkNavy,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: appBackground,
      onSurface: charcoal,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF1F6F6),
      surfaceContainer: Color(0xFFEAF2F2),
      surfaceContainerHigh: Color(0xFFE0ECEC),
      surfaceContainerHighest: Color(0xFFD7E6E6),
      onSurfaceVariant: primaryNavy,
      outline: softTeal,
      outlineVariant: lightTeal,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: charcoal,
      onInverseSurface: appBackground,
      inversePrimary: brightTealAccent,
    );
  }

  static ColorScheme _darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: brightTealAccent,
      onPrimary: charcoal,
      primaryContainer: primaryNavy,
      onPrimaryContainer: Color(0xFFD8FFFC),
      secondary: lightTeal,
      onSecondary: darkNavy,
      secondaryContainer: darkNavy,
      onSecondaryContainer: Color(0xFFD8FFFC),
      tertiary: primaryTeal,
      onTertiary: charcoal,
      tertiaryContainer: Color(0xFF244F5E),
      onTertiaryContainer: Color(0xFFD8FFFC),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: charcoal,
      onSurface: appBackground,
      surfaceContainerLowest: Color(0xFF070909),
      surfaceContainerLow: Color(0xFF101819),
      surfaceContainer: Color(0xFF132124),
      surfaceContainerHigh: Color(0xFF183036),
      surfaceContainerHighest: darkNavy,
      onSurfaceVariant: Color(0xFFC7D9D9),
      outline: softTeal,
      outlineVariant: primaryNavy,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: appBackground,
      onInverseSurface: charcoal,
      inversePrimary: primaryTeal,
    );
  }
}
