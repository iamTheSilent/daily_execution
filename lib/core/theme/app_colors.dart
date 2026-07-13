import 'package:flutter/material.dart';

class AppColors {
  // ── پایه (روشن) ──
  static const background = Color(0xFFF2EEE7); // کرمِ گرمِ پس‌زمینه
  static const surface = Color(0xFFFCFBF7);    // کارت‌ها (سفیدِ شیری)
  static const dark = Color(0xFF1C1C1E);       // دکمه‌های مشکی / سگمنتِ فعال

  // ── اکسنت و وضعیت‌ها ──
  static const accent = Color(0xFFFF9500);     // نارنجی
  static const doing = accent;                 // سازگاری با کدِ قبلی
  static const green = Color(0xFF34C759);      // انجام‌شده
  static const red = Color(0xFFFF3B30);        // overdue

  // ── متن ──
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF9A958C);

  // ── تینت‌ها / ابعاد ──
  static const focusTint = Color(0xFFFBEAD5);   // کارتِ فوکوس (پیچ)
  static const doneBg = Color(0xFFEAEAF0);      // کارتِ انجام‌شده
  static const doneTint = Color(0x0A000000);    // سازگاری با کدِ قبلی
  static const progressTrack = Color(0xFFE6E2DA);
  static const divider = Color(0xFFE8E4DC);

  // ── حالتِ تاریک ──
  static const darkBackground = Color(0xFF141414);
  static const darkSurface = Color(0xFF1F1F1F);
  static const darkTextPrimary = Color(0xFFF3F1EC);
  static const darkTextSecondary = Color(0xFF908B82);
  static const darkFocusTint = Color(0xFF3A2E1C);
  static const darkDoneBg = Color(0xFF26262B);
  static const darkProgressTrack = Color(0xFF33322F);
  static const darkDivider = Color(0xFF2E2E2E);

  static const cardRadius = 18.0;
}

/// پالتِ وابسته به تم (روشن/تاریک). در صفحه‌ها با context.palette خوانده می‌شود.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.progressTrack,
    required this.doneBg,
    required this.focusTint,
    required this.accent,
    required this.green,
    required this.red,
    required this.segmentActive,
  });

  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color progressTrack;
  final Color doneBg;
  final Color focusTint;
  final Color accent;
  final Color green;
  final Color red;
  final Color segmentActive;

  static const light = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
    progressTrack: AppColors.progressTrack,
    doneBg: AppColors.doneBg,
    focusTint: AppColors.focusTint,
    accent: AppColors.accent,
    green: AppColors.green,
    red: AppColors.red,
    segmentActive: AppColors.dark,
  );

  static const dark = AppPalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    divider: AppColors.darkDivider,
    progressTrack: AppColors.darkProgressTrack,
    doneBg: AppColors.darkDoneBg,
    focusTint: AppColors.darkFocusTint,
    accent: AppColors.accent,
    green: AppColors.green,
    red: AppColors.red,
    segmentActive: AppColors.accent,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? progressTrack,
    Color? doneBg,
    Color? focusTint,
    Color? accent,
    Color? green,
    Color? red,
    Color? segmentActive,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      progressTrack: progressTrack ?? this.progressTrack,
      doneBg: doneBg ?? this.doneBg,
      focusTint: focusTint ?? this.focusTint,
      accent: accent ?? this.accent,
      green: green ?? this.green,
      red: red ?? this.red,
      segmentActive: segmentActive ?? this.segmentActive,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      doneBg: Color.lerp(doneBg, other.doneBg, t)!,
      focusTint: Color.lerp(focusTint, other.focusTint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      segmentActive: Color.lerp(segmentActive, other.segmentActive, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
