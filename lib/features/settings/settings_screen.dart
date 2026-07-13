import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date/app_date.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/settings_providers.dart';

// App version shown in the About section. Keep in sync with pubspec.yaml.
const String _appVersion = '0.1.0';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _usernameCtrl;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: ref.read(usernameProvider));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(calendarModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final notifOn = ref.watch(notificationsEnabledProvider);
    final p = context.palette;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              s.navSettings,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // ── ظاهر ──
            _section(s.appearance),
            _label(s.theme),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: ThemeMode.light, label: Text(s.themeLight)),
                ButtonSegment(
                    value: ThemeMode.dark, label: Text(s.themeDark)),
                ButtonSegment(
                    value: ThemeMode.system, label: Text(s.themeSystem)),
              ],
              selected: {themeMode},
              onSelectionChanged: (v) =>
                  ref.read(themeModeProvider.notifier).set(v.first),
            ),
            const SizedBox(height: 20),
            _label(s.fontSize),
            const SizedBox(height: 8),
            SegmentedButton<AppFontSize>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: AppFontSize.small, label: Text(s.fontSmall)),
                ButtonSegment(
                    value: AppFontSize.medium, label: Text(s.fontMedium)),
                ButtonSegment(
                    value: AppFontSize.large, label: Text(s.fontLarge)),
              ],
              selected: {fontSize},
              onSelectionChanged: (v) =>
                  ref.read(fontSizeProvider.notifier).set(v.first),
            ),
            const SizedBox(height: 28),

            // ── زبان و تقویم ──
            _section(s.language),
            _label(s.language),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'fa', label: Text('فارسی')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (v) =>
                  ref.read(localeProvider.notifier).state = Locale(v.first),
            ),
            const SizedBox(height: 20),
            _label(s.calendarSystem),
            const SizedBox(height: 8),
            SegmentedButton<CalendarMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: CalendarMode.shamsi, label: Text(s.calShamsi)),
                ButtonSegment(
                    value: CalendarMode.gregorian,
                    label: Text(s.calGregorian)),
              ],
              selected: {mode},
              onSelectionChanged: (v) =>
                  ref.read(calendarModeProvider.notifier).state = v.first,
            ),
            const SizedBox(height: 28),

            // ── نوتیفیکیشن ──
            _section(s.notifications),
            _card(
              p,
              child: SwitchListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                secondary: Icon(Icons.notifications_outlined,
                    color: p.textSecondary),
                title: Text(s.notifications,
                    style: TextStyle(color: p.textPrimary)),
                subtitle: Text(s.notificationsDesc,
                    style:
                        TextStyle(color: p.textSecondary, fontSize: 12)),
                value: notifOn,
                activeColor: p.accent,
                onChanged: (v) => ref
                    .read(notificationsEnabledProvider.notifier)
                    .set(v),
              ),
            ),
            const SizedBox(height: 28),

            // ── نام کاربری ──
            _section(s.username),
            _card(
              p,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _usernameCtrl,
                  style: TextStyle(color: p.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.person_outline,
                        color: p.textSecondary),
                    hintText: s.usernameHint,
                    hintStyle: TextStyle(color: p.textSecondary),
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (v) =>
                      ref.read(usernameProvider.notifier).set(v.trim()),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── حساب کاربری (به‌زودی) ──
            _section(s.account),
            Opacity(
              opacity: 0.55,
              child: _card(
                p,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  leading: Icon(Icons.workspaces_outline,
                      color: p.textSecondary),
                  title: Text(s.accountComingSoon,
                      style: TextStyle(color: p.textPrimary)),
                  enabled: false,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── درباره ──
            _section(s.about),
            _card(
              p,
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                leading: Icon(Icons.info_outline, color: p.textSecondary),
                title:
                    Text(s.appTitle, style: TextStyle(color: p.textPrimary)),
                subtitle: Text('${s.version}: $_appVersion',
                    style:
                        TextStyle(color: p.textSecondary, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _card(AppPalette p, {required Widget child}) => Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        child: child,
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.palette.textPrimary,
          ),
        ),
      );

  Widget _label(String t) => Text(
        t,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.palette.textSecondary,
        ),
      );
}
