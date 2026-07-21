import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date/app_date.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';

/// Stats screen (replaces the old inbox): today ring + streak + heatmap.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isFa = ref.watch(localeProvider).languageCode == 'fa';
    final todayAsync = ref.watch(todayTasksProvider);
    final datesAsync = ref.watch(completionDatesProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(
          isFa ? 'آمار' : 'Stats',
          style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          todayAsync.when(
            data: (tasks) => _TodayRingCard(tasks: tasks, isFa: isFa),
            loading: () => const _LoadingCard(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          datesAsync.when(
            data: (dates) {
              final dayCounts = _toDayCounts(dates);
              return Column(
                children: [
                  _StreakCard(dayCounts: dayCounts, isFa: isFa),
                  const SizedBox(height: 16),
                  _HeatmapCard(dayCounts: dayCounts, isFa: isFa),
                ],
              );
            },
            loading: () => const _LoadingCard(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──

/// Group completion timestamps into a map of date-only -> count.
Map<DateTime, int> _toDayCounts(List<DateTime> dates) {
  final map = <DateTime, int>{};
  for (final d in dates) {
    final key = DateTime(d.year, d.month, d.day);
    map[key] = (map[key] ?? 0) + 1;
  }
  return map;
}

String _num(int n, bool isFa) => isFa ? toFaDigits('$n') : '$n';

Widget _card(BuildContext context, {required Widget child}) {
  final p = context.palette;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

/// Blend from the track color to the accent based on how many tasks were done.
Color _cellColor(int count, Color track, Color accent) {
  if (count <= 0) return track;
  const levels = [0.0, 0.35, 0.6, 0.8, 1.0];
  final idx = count >= 4 ? 4 : count;
  return Color.lerp(track, accent, levels[idx])!;
}

// ── Cards ──

class _TodayRingCard extends StatelessWidget {
  const _TodayRingCard({required this.tasks, required this.isFa});
  final List<Task> tasks;
  final bool isFa;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = tasks.length;
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final ratio = total == 0 ? 0.0 : done / total;
    final pct = (ratio * 100).round();
    return _card(
      context,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : ratio,
                    strokeWidth: 9,
                    backgroundColor: p.progressTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(p.accent),
                  ),
                ),
                Text(
                  total == 0 ? '—' : '${_num(pct, isFa)}${isFa ? '٪' : '%'}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFa ? 'پیشرفتِ امروز' : "Today's progress",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? (isFa ? 'امروز تسکی نداری' : 'No tasks today')
                      : (isFa
                          ? '${_num(done, isFa)} از ${_num(total, isFa)} تسک انجام شد'
                          : '${_num(done, isFa)} of ${_num(total, isFa)} tasks done'),
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.dayCounts, required this.isFa});
  final Map<DateTime, int> dayCounts;
  final bool isFa;

  int _computeStreak() {
    if (dayCounts.isEmpty) return 0;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    // If today has nothing yet, start from yesterday so an active streak
    // isn't shown as broken mid-day.
    if (!dayCounts.containsKey(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!dayCounts.containsKey(cursor)) return 0;
    }
    var streak = 0;
    while (dayCounts.containsKey(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final streak = _computeStreak();
    return _card(
      context,
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFa
                      ? '${_num(streak, isFa)} روزِ پیاپی'
                      : '${_num(streak, isFa)} day streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak == 0
                      ? (isFa
                          ? 'امروز یه تسک انجام بده تا شروع شه'
                          : 'Finish a task today to start')
                      : (isFa ? 'ادامه بده!' : 'Keep it up!'),
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.dayCounts, required this.isFa});
  final Map<DateTime, int> dayCounts;
  final bool isFa;

  static const _weeks = 18;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    // Persian week starts on Saturday; align columns to Saturday.
    final daysSinceSat = (todayDate.weekday - DateTime.saturday) % 7;
    final currentWeekStart = todayDate.subtract(Duration(days: daysSinceSat));
    final firstWeekStart =
        currentWeekStart.subtract(const Duration(days: 7 * (_weeks - 1)));

    const cell = 15.0;
    const gap = 4.0;

    final columns = <Widget>[];
    for (var w = 0; w < _weeks; w++) {
      final cells = <Widget>[];
      for (var r = 0; r < 7; r++) {
        final day = firstWeekStart.add(Duration(days: w * 7 + r));
        final key = DateTime(day.year, day.month, day.day);
        final isFuture = key.isAfter(todayDate);
        final count = dayCounts[key] ?? 0;
        cells.add(Container(
          width: cell,
          height: cell,
          margin: const EdgeInsets.all(gap / 2),
          decoration: BoxDecoration(
            color: isFuture
                ? Colors.transparent
                : _cellColor(count, p.progressTrack, p.accent),
            borderRadius: BorderRadius.circular(4),
          ),
        ));
      }
      columns.add(Column(children: cells));
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFa ? 'نقشه‌ی فعالیت' : 'Activity map',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFa
                ? 'هر خانه یک روز؛ پررنگ‌تر یعنی تسک‌های بیشتری انجام دادی'
                : 'Each cell is a day; darker means more done',
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: isFa,
            child: Row(children: columns),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return _card(
      context,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
