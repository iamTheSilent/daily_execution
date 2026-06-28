import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../theme/app_colors.dart';
import 'app_date.dart';

const _faMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];

/// انتخابگرِ چرخشیِ تاریخ و زمان (شبیهِ آلارمِ آیفون). DateTime برمی‌گردونه.
Future<DateTime?> showWheelDateTime(
  BuildContext context, {
  DateTime? initial,
  required CalendarMode mode,
  bool isFa = true,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WheelSheet(
      initial: initial ?? DateTime.now(),
      mode: mode,
      isFa: isFa,
    ),
  );
}

class _WheelSheet extends StatefulWidget {
  const _WheelSheet({
    required this.initial,
    required this.mode,
    required this.isFa,
  });
  final DateTime initial;
  final CalendarMode mode;
  final bool isFa;

  @override
  State<_WheelSheet> createState() => _WheelSheetState();
}

class _WheelSheetState extends State<_WheelSheet> {
  bool get _shamsi => widget.mode == CalendarMode.shamsi;

  late int _year, _month, _day, _hour, _minute, _minYear;

  late final FixedExtentScrollController _yearCtrl,
      _monthCtrl,
      _dayCtrl,
      _hourCtrl,
      _minuteCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (_shamsi) {
      final j = Jalali.fromDateTime(d);
      _year = j.year;
      _month = j.month;
      _day = j.day;
    } else {
      _year = d.year;
      _month = d.month;
      _day = d.day;
    }
    _hour = d.hour;
    _minute = d.minute;
    _minYear = _year - 5;

    _yearCtrl = FixedExtentScrollController(initialItem: _year - _minYear);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  int get _daysInMonth =>
      _shamsi ? Jalali(_year, _month, 1).monthLength : DateTime(_year, _month + 1, 0).day;

  void _clampDay() {
    final max = _daysInMonth;
    if (_day > max) {
      _day = max;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayCtrl.hasClients) _dayCtrl.jumpToItem(_day - 1);
      });
    }
  }

  DateTime _result() {
    if (_shamsi) {
      final g = Jalali(_year, _month, _day).toGregorian();
      return DateTime(g.year, g.month, g.day, _hour, _minute);
    }
    return DateTime(_year, _month, _day, _hour, _minute);
  }

  String _fa(String s) => widget.isFa ? toFaDigits(s) : s;
  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final years = [for (int y = _minYear; y <= _minYear + 10; y++) _fa('$y')];
    final months =
        _shamsi ? _faMonths : [for (int m = 1; m <= 12; m++) _fa('$m')];
    final days = [for (int d = 1; d <= _daysInMonth; d++) _fa('$d')];
    final hours = [for (int h = 0; h < 24; h++) _fa(_two(h))];
    final minutes = [for (int m = 0; m < 60; m++) _fa(_two(m))];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(widget.isFa ? 'لغو' : 'Cancel',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
                Text(widget.isFa ? 'زمان و تاریخ' : 'Date & time',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () => Navigator.pop(context, _result()),
                  child: Text(widget.isFa ? 'تأیید' : 'Done',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      _wheel(days, _dayCtrl, 2,
                          (i) => setState(() => _day = i + 1)),
                      _wheel(months, _monthCtrl, 3,
                          (i) => setState(() {
                                _month = i + 1;
                                _clampDay();
                              })),
                      _wheel(years, _yearCtrl, 3,
                          (i) => setState(() {
                                _year = _minYear + i;
                                _clampDay();
                              })),
                      const SizedBox(width: 8),
                      _wheel(hours, _hourCtrl, 2,
                          (i) => setState(() => _hour = i)),
                      const _Colon(),
                      _wheel(minutes, _minuteCtrl, 2,
                          (i) => setState(() => _minute = i)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel(List<String> labels, FixedExtentScrollController ctrl, int flex,
      ValueChanged<int> onChanged) {
    return Expanded(
      flex: flex,
      child: ListWheelScrollView.useDelegate(
        controller: ctrl,
        itemExtent: 40,
        perspective: 0.004,
        diameterRatio: 1.3,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: labels.length,
          builder: (_, i) => Center(
            child: Text(labels[i],
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 18, color: AppColors.textPrimary)),
          ),
        ),
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 10,
        child: Center(
            child: Text(':',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary))),
      );
}