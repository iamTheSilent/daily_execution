import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CalendarMode { shamsi, gregorian }

/// حالت فعلی تقویم (پیش‌فرض: شمسی).
/// بعداً از Settings می‌تونیم عوضش کنیم.
final calendarModeProvider =
    StateProvider<CalendarMode>((ref) => CalendarMode.shamsi);