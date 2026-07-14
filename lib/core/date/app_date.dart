import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalendarMode { shamsi, gregorian }

/// حالت فعلی تقویم (پیش‌فرض: شمسی) — با ماندگاری در SharedPreferences.
class CalendarModeNotifier extends StateNotifier<CalendarMode> {
  CalendarModeNotifier() : super(CalendarMode.shamsi) {
    _load();
  }
  static const _key = 'settings.calendarMode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v != null) {
      state = CalendarMode.values.firstWhere(
        (e) => e.name == v,
        orElse: () => CalendarMode.shamsi,
      );
    }
  }

  Future<void> set(CalendarMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final calendarModeProvider =
    StateNotifierProvider<CalendarModeNotifier, CalendarMode>(
        (ref) => CalendarModeNotifier());

/// تبدیل ارقام انگلیسی به فارسی
String toFaDigits(String input) {
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  var out = input;
  for (var i = 0; i < en.length; i++) {
    out = out.replaceAll(en[i], fa[i]);
  }
  return out;
}

/// «مترجمِ تاریخِ» مرکزی اپ.
///
/// mode  -> نوعِ تقویم (شمسی/میلادی)
/// faDigits -> زبانِ ارقام (فارسی/انگلیسی). اگر داده نشود از mode حدس می‌زند
///            (سازگاری با کدهای قدیمی).
class AppDate {
  static bool _fa(CalendarMode mode, bool? faDigits) =>
      faDigits ?? (mode == CalendarMode.shamsi);

  static String primaryLong(DateTime dt, CalendarMode mode, {bool? faDigits}) {
    final String out;
    if (mode == CalendarMode.shamsi) {
      final j = Jalali.fromDateTime(dt);
      final f = j.formatter;
      out = '${f.wN} ${j.day} ${f.mN} ${j.year}';
    } else {
      out = DateFormat('EEEE, d MMMM yyyy').format(dt);
    }
    return _fa(mode, faDigits) ? toFaDigits(out) : out;
  }

  static String secondaryShort(DateTime dt, CalendarMode mode,
      {bool? faDigits}) {
    final String out;
    if (mode == CalendarMode.shamsi) {
      out = DateFormat('d MMM yyyy').format(dt);
    } else {
      final j = Jalali.fromDateTime(dt);
      out = '${j.day} ${j.formatter.mN} ${j.year}';
    }
    return _fa(mode, faDigits) ? toFaDigits(out) : out;
  }

  /// عنوانِ ماه/سال برای هدرِ تقویم (مثلاً «تیر ۱۴۰۵» یا «June 2026»).
  static String monthYear(DateTime dt, CalendarMode mode, {bool? faDigits}) {
    final String out;
    if (mode == CalendarMode.shamsi) {
      final j = Jalali.fromDateTime(dt);
      out = '${j.formatter.mN} ${j.year}';
    } else {
      out = DateFormat('MMMM yyyy').format(dt);
    }
    return _fa(mode, faDigits) ? toFaDigits(out) : out;
  }

  /// شماره‌ی روزِ ماه.
  static String dayNum(DateTime dt, CalendarMode mode, {bool? faDigits}) {
    final out = mode == CalendarMode.shamsi
        ? '${Jalali.fromDateTime(dt).day}'
        : '${dt.day}';
    return _fa(mode, faDigits) ? toFaDigits(out) : out;
  }

  /// برچسب‌های ردیفِ روزهای هفته، از شنبه تا جمعه.
  static List<String> weekdayHeaders(CalendarMode mode) {
    if (mode == CalendarMode.shamsi) {
      return const ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    }
    return const ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'];
  }

  /// برچسبِ کوتاهِ یک روز برای نوارِ هفته (هماهنگ با weekdayHeaders).
  static String weekdayShort(DateTime dt, CalendarMode mode) {
    final idx = (dt.weekday + 1) % 7; // 0 = Saturday
    return weekdayHeaders(mode)[idx];
  }
}