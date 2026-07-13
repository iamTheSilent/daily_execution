import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/date/app_date.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../domain/task_logic.dart';
import '../../providers/app_providers.dart';

/// Tasks of a single day (day = normalized midnight local).
final calendarDayTasksProvider =
    StreamProvider.autoDispose.family<List<Task>, DateTime>((ref, day) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchDay(day, TaskSort.defaultSort);
});

DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _today() => _norm(DateTime.now());
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtTime(int minutes, bool fa) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final str = '$h:${m.toString().padLeft(2, '0')}';
  return fa ? toFaDigits(str) : str;
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selected = _today();
  bool _monthView = false;

  DateTime _saturdayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - ((d.weekday + 1) % 7));

  List<DateTime?> _monthCells(DateTime sel, CalendarMode mode) {
    late DateTime first;
    late int len;
    if (mode == CalendarMode.shamsi) {
      final j = Jalali.fromDateTime(sel);
      final jf = Jalali(j.year, j.month, 1);
      first = jf.toDateTime();
      len = jf.monthLength;
    } else {
      first = DateTime(sel.year, sel.month, 1);
      len = DateUtils.getDaysInMonth(sel.year, sel.month);
    }
    final lead = (first.weekday + 1) % 7;
    final cells = <DateTime?>[];
    for (var i = 0; i < lead; i++) {
      cells.add(null);
    }
    for (var i = 0; i < len; i++) {
      cells.add(DateTime(first.year, first.month, first.day + i));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  void _shiftBack(CalendarMode mode) {
    if (_monthView) {
      _shiftMonth(mode, -1);
    } else {
      setState(() => _selected =
          DateTime(_selected.year, _selected.month, _selected.day - 7));
    }
  }

  void _shiftFwd(CalendarMode mode) {
    if (_monthView) {
      _shiftMonth(mode, 1);
    } else {
      setState(() => _selected =
          DateTime(_selected.year, _selected.month, _selected.day + 7));
    }
  }

  void _shiftMonth(CalendarMode mode, int delta) {
    setState(() {
      if (mode == CalendarMode.shamsi) {
        final j = Jalali.fromDateTime(_selected);
        var jy = j.year;
        var jm = j.month + delta;
        while (jm < 1) {
          jm += 12;
          jy--;
        }
        while (jm > 12) {
          jm -= 12;
          jy++;
        }
        final len = Jalali(jy, jm, 1).monthLength;
        final day = j.day > len ? len : j.day;
        _selected = Jalali(jy, jm, day).toDateTime();
      } else {
        final m = DateTime(_selected.year, _selected.month + delta, 1);
        final len = DateUtils.getDaysInMonth(m.year, m.month);
        final day = _selected.day > len ? len : _selected.day;
        _selected = DateTime(m.year, m.month, day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = ref.watch(appStringsProvider);
    final mode = ref.watch(calendarModeProvider);
    final fa = ref.watch(localeProvider).languageCode == 'fa';
    final dayTasks = ref.watch(calendarDayTasksProvider(_norm(_selected)));

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(s.navCalendar,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selected = _today()),
                    child: Text(s.today),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () => _shiftBack(mode),
                    icon: Icon(Icons.chevron_left, color: p.textPrimary)),
                Expanded(
                  child: Center(
                    child: Text(AppDate.monthYear(_selected, mode, faDigits: fa),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary)),
                  ),
                ),
                IconButton(
                    onPressed: () => _shiftFwd(mode),
                    icon: Icon(Icons.chevron_right, color: p.textPrimary)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Center(
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: false, label: Text(s.week)),
                    ButtonSegment(value: true, label: Text(s.month)),
                  ],
                  selected: {_monthView},
                  onSelectionChanged: (v) =>
                      setState(() => _monthView = v.first),
                ),
              ),
            ),
            if (_monthView) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _weekdayHeader(mode),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: _monthGrid(mode, fa),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: _weekStrip(mode, fa),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(AppDate.primaryLong(_selected, mode, faDigits: fa),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
              ),
            ),
            Divider(height: 1, color: p.divider),
            Expanded(
              child: dayTasks.when(
                data: (list) => list.isEmpty
                    ? Center(
                        child: Text(s.calEmptyDay,
                            style: TextStyle(color: p.textSecondary)))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: p.divider,
                            indent: 16,
                            endIndent: 16),
                        itemBuilder: (_, i) => _taskRow(list[i], fa),
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayHeader(CalendarMode mode) {
    final p = context.palette;
    return Row(
      children: [
        for (final l in AppDate.weekdayHeaders(mode))
          Expanded(
            child: Center(
              child: Text(l,
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ),
          ),
      ],
    );
  }

  Widget _weekStrip(CalendarMode mode, bool fa) {
    final start = _saturdayOf(_selected);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i)
    ];
    return Row(
      children: [
        for (final d in days)
          Expanded(child: _dayCell(d, mode, fa, week: true)),
      ],
    );
  }

  Widget _monthGrid(CalendarMode mode, bool fa) {
    final cells = _monthCells(_selected, mode);
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children: [
          for (var j = i; j < i + 7; j++)
            Expanded(
              child: cells[j] == null
                  ? const SizedBox(height: 44)
                  : _dayCell(cells[j]!, mode, fa, week: false),
            ),
        ],
      ));
    }
    return Column(children: rows);
  }

  Widget _dayCell(DateTime day, CalendarMode mode, bool fa,
      {required bool week}) {
    final p = context.palette;
    final isSel = _sameDay(day, _selected);
    final isToday = _sameDay(day, _today());
    final hasTasks =
        ref.watch(calendarDayTasksProvider(_norm(day))).value?.isNotEmpty ??
            false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = _norm(day)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (week) ...[
              Text(AppDate.weekdayShort(day, mode),
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 6),
            ],
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Selected day: high-contrast chip that inverts with the theme
                // (dark chip in light mode, light chip in dark mode).
                color: isSel ? p.textPrimary : Colors.transparent,
              ),
              child: Text(
                AppDate.dayNum(day, mode, faDigits: fa),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      (isSel || isToday) ? FontWeight.w700 : FontWeight.normal,
                  color: isSel
                      ? p.background
                      : (isToday ? p.accent : p.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (hasTasks && !isSel) ? p.accent : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskRow(Task t, bool fa) {
    final p = context.palette;
    final done = t.status == TaskStatus.done;
    String? timeStr;
    if (t.timeStart != null) {
      timeStr = t.timeEnd != null
          ? '${_fmtTime(t.timeStart!, fa)}-${_fmtTime(t.timeEnd!, fa)}'
          : _fmtTime(t.timeStart!, fa);
    }
    return InkWell(
      onTap: () => ref.read(taskRepositoryProvider).cycleStatus(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _statusDot(t.status),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.title,
                style: TextStyle(
                  fontSize: 15,
                  color: done ? p.textSecondary : p.textPrimary,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: done ? p.textSecondary : null,
                ),
              ),
            ),
            if (timeStr != null) ...[
              const SizedBox(width: 8),
              Text(timeStr,
                  style: TextStyle(fontSize: 13, color: p.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusDot(TaskStatus st) {
    final p = context.palette;
    return switch (st) {
      TaskStatus.done =>
        Icon(Icons.check_circle, size: 20, color: p.green),
      TaskStatus.doing => Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.accent, width: 2),
          ),
        ),
      TaskStatus.todo => Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.textSecondary, width: 1.5),
          ),
        ),
    };
  }
}
