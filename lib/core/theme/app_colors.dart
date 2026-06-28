import 'package:flutter/material.dart';

class AppColors {
  // ── پایه ──
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

  static const cardRadius = 18.0;
}