import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════ Font size ═══════════════════════════
enum AppFontSize { small, medium, large }

extension AppFontSizeScale on AppFontSize {
  double get scale {
    switch (this) {
      case AppFontSize.small:
        return 0.90;
      case AppFontSize.medium:
        return 1.00;
      case AppFontSize.large:
        return 1.15;
    }
  }
}

// ═══════════════════════════ Theme mode ═══════════════════════════
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }
  static const _key = 'settings.themeMode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
        (ref) => ThemeModeNotifier());

// ═══════════════════════════ Font size state ═══════════════════════════
class FontSizeNotifier extends StateNotifier<AppFontSize> {
  FontSizeNotifier() : super(AppFontSize.medium) {
    _load();
  }
  static const _key = 'settings.fontSize';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v != null) {
      state = AppFontSize.values.firstWhere(
        (e) => e.name == v,
        orElse: () => AppFontSize.medium,
      );
    }
  }

  Future<void> set(AppFontSize size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, size.name);
  }
}

final fontSizeProvider =
    StateNotifierProvider<FontSizeNotifier, AppFontSize>(
        (ref) => FontSizeNotifier());

/// Scale factor derived from the chosen font size. Watched by the app root.
final fontScaleProvider =
    Provider<double>((ref) => ref.watch(fontSizeProvider).scale);

// ═══════════════════════════ Notifications on/off ═══════════════════════════
class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _load();
  }
  static const _key = 'settings.notifications';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_key);
    if (v != null) state = v;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsNotifier, bool>(
        (ref) => NotificationsNotifier());

// ═══════════════════════════ Username ═══════════════════════════
class UsernameNotifier extends StateNotifier<String> {
  UsernameNotifier() : super('') {
    _load();
  }
  static const _key = 'settings.username';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? '';
  }

  Future<void> set(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
  }
}

final usernameProvider =
    StateNotifierProvider<UsernameNotifier, String>(
        (ref) => UsernameNotifier());
