import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date/app_date.dart';
import '../../providers/app_providers.dart';

// Local palette (kept as literals to avoid guessing AppColors field names).
const _kBg = Color(0xFFF2EEE7);
const _kDark = Color(0xFF1C1C1E);
const _kTextSecondary = Color(0xFF9A958C);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(calendarModeProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.navSettings,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: _kDark)),
            const SizedBox(height: 24),

            // Language
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
            const SizedBox(height: 28),

            // Calendar system
            _label(s.calendarSystem),
            const SizedBox(height: 8),
            SegmentedButton<CalendarMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: CalendarMode.shamsi, label: Text(s.calShamsi)),
                ButtonSegment(
                    value: CalendarMode.gregorian, label: Text(s.calGregorian)),
              ],
              selected: {mode},
              onSelectionChanged: (v) =>
                  ref.read(calendarModeProvider.notifier).state = v.first,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: _kTextSecondary));
}