import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
    ).copyWith(
      primary: p.accent,
      onPrimary: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      secondary: p.accent,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      dividerColor: p.divider,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: p.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.progressTrack,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.background,
        selectedItemColor: p.accent,
        unselectedItemColor: p.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.background,
        indicatorColor: p.focusTint,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? p.segmentActive
                  : p.surface),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? Colors.white
                  : p.textPrimary),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
