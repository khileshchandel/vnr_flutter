import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Premium E Track theme.
///
/// Dark: near-black "ink" surfaces with a luminous emerald accent.
/// Light: warm paper-white surfaces with a deep emerald accent.
/// A restrained gold secondary is used sparingly for highlights.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF0E6B52);
  static const double radius = 16;
  static const double radiusLarge = 28;

  /// Apple-style "emphasized decelerate" curve: fast start, long soft landing.
  /// Never overshoots, so it is safe for opacity and layout.
  static const Curve emphasized = Cubic(0.16, 1, 0.3, 1);

  /// Stable accent colors for category charts, tuned to read on both themes.
  static const List<Color> chartPalette = <Color>[
    Color(0xFF2FBF8F), // emerald
    Color(0xFFE0B25C), // gold
    Color(0xFF7C93E8), // periwinkle
    Color(0xFFE07A8F), // rose
    Color(0xFFA48BE0), // violet
    Color(0xFF4FB5C9), // cyan
  ];

  static LinearGradient brandGradient(ColorScheme scheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [scheme.primary, Color.lerp(scheme.primary, scheme.tertiary, 0.6)!],
  );

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    if (brightness == Brightness.dark) {
      return base.copyWith(
        primary: const Color(0xFF3DDC97),
        onPrimary: const Color(0xFF03291C),
        primaryContainer: const Color(0xFF124A38),
        onPrimaryContainer: const Color(0xFFBFF3DC),
        secondary: const Color(0xFFE5C07B),
        onSecondary: const Color(0xFF2B1F05),
        tertiary: const Color(0xFF4FD1D9),
        surface: const Color(0xFF090C0B),
        onSurface: const Color(0xFFEDF2EF),
        onSurfaceVariant: const Color(0xFF9AA8A2),
        surfaceContainerLowest: const Color(0xFF060808),
        surfaceContainerLow: const Color(0xFF111614),
        surfaceContainer: const Color(0xFF161C1A),
        surfaceContainerHigh: const Color(0xFF1C2421),
        surfaceContainerHighest: const Color(0xFF232C29),
        outline: const Color(0xFF3A4742),
        outlineVariant: const Color(0xFF232C29),
      );
    }

    return base.copyWith(
      primary: const Color(0xFF0E6B52),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD3EFE3),
      onPrimaryContainer: const Color(0xFF06382B),
      secondary: const Color(0xFFB8893A),
      onSecondary: Colors.white,
      tertiary: const Color(0xFF1B8A8F),
      surface: const Color(0xFFF6F5F0),
      onSurface: const Color(0xFF121614),
      onSurfaceVariant: const Color(0xFF5B6560),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: const Color(0xFFEFEEE8),
      surfaceContainerHigh: const Color(0xFFE8E7E0),
      surfaceContainerHighest: const Color(0xFFE1E0D8),
      outline: const Color(0xFFB9B7AD),
      outlineVariant: const Color(0xFFDEDCD2),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final colorScheme = _scheme(brightness);
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    final text = base.textTheme;

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyMedium: text.bodyMedium?.copyWith(letterSpacing: -0.1),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        suffixIconColor: colorScheme.onSurfaceVariant,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: border(colorScheme.outlineVariant),
        enabledBorder: border(colorScheme.outlineVariant),
        focusedBorder: border(colorScheme.primary, 1.6),
        errorBorder: border(colorScheme.error),
        focusedErrorBorder: border(colorScheme.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
