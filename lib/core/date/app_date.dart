import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

enum CalendarMode { shamsi, gregorian }

/// حالت فعلی تقویم (پیش‌فرض: شمسی).
final calendarModeProvider =
    StateProvider<CalendarMode>((ref) => CalendarMode.shamsi);

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
class AppDate {
  static String primaryLong(DateTime dt, CalendarMode mode) {
    if (mode == CalendarMode.shamsi) {
      final j = Jalali.fromDateTime(dt);
      final f = j.formatter;
      return toFaDigits('${f.wN} ${j.day} ${f.mN} ${j.year}');
    }
    return DateFormat('EEEE, d MMMM yyyy').format(dt);
  }

  static String secondaryShort(DateTime dt, CalendarMode mode) {
    if (mode == CalendarMode.shamsi) {
      return DateFormat('d MMM yyyy').format(dt);
    }
    final j = Jalali.fromDateTime(dt);
    final f = j.formatter;
    return toFaDigits('${j.day} ${f.mN} ${j.year}');
  }
}