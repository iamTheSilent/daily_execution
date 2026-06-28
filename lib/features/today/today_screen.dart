import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/date/app_date.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../domain/task_logic.dart';
import '../../providers/app_providers.dart';
import 'task_detail_screen.dart';
import 'widgets/task_row.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final mode = ref.watch(calendarModeProvider);
    final tasksAsync = ref.watch(dayTasksProvider);
    final isFa = ref.watch(localeProvider).languageCode == 'fa';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        day.year == today.year && day.month == today.month && day.day == today.day;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v == 0) return;
            ref.read(selectedDayProvider.notifier).state =
                day.add(Duration(days: v < 0 ? 1 : -1));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── سربرگ: تیترِ درشت + مرتب‌سازی + دکمهٔ + مشکی ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDate.primaryLong(day, mode),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppDate.secondaryShort(day, mode),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_vert,
                          color: AppColors.textSecondary),
                      onPressed: () => _sortSheet(context, ref),
                    ),
                    const SizedBox(width: 2),
                    _AddButton(onTap: () => _quickAdd(context, ref)),
                  ],
                ),
              ),
              // ── ردیفِ راهنما + میان‌برِ «امروز» ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    if (!isToday) ...[
                      _TodayPill(
                        isFa: isFa,
                        onTap: () => ref
                            .read(selectedDayProvider.notifier)
                            .state = today,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        isFa
                            ? 'برای جابه‌جایی بینِ روزها، صفحه را بکش'
                            : 'Swipe sideways to change the day',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // ── لیستِ کارها ──
              Expanded(
                child: tasksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('${isFa ? 'خطا' : 'Error'}: $e')),
                  data: (tasks) => tasks.isEmpty
                      ? _EmptyDay(isFa: isFa)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                          itemCount: tasks.length,
                          itemBuilder: (_, i) {
                            final t = tasks[i];
                            return TaskRow(
                              task: t,
                              onCycleStatus: () => ref
                                  .read(taskRepositoryProvider)
                                  .cycleStatus(t),
                              onOpen: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TaskDetailScreen(taskId: t.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'کار جدید…'),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(ctx, ctrl.text)),
        ]),
      ),
    );
    if (title == null || title.trim().isEmpty) return;
    final now = DateTime.now();
    final day = ref.read(selectedDayProvider);
    await ref.read(databaseProvider).upsertTask(TasksCompanion.insert(
          id: const Uuid().v4(),
          title: title.trim(),
          bucket: TaskBucket.day,
          day: Value(day),
          orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> _sortSheet(BuildContext context, WidgetRef ref) async {
    final current = ref.read(todaySortProvider);
    final picked = await showModalBottomSheet<TaskSort>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskSort.values
              .map((s) => RadioListTile<TaskSort>(
                    value: s,
                    groupValue: current,
                    title: Text(_sortLabel(s)),
                    onChanged: (v) => Navigator.pop(ctx, v),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) {
      ref.read(todaySortProvider.notifier).state = picked;
    }
  }

  String _sortLabel(TaskSort s) => switch (s) {
        TaskSort.defaultSort => 'پیش‌فرض (فوکوس، عادی، انجام‌شده)',
        TaskSort.timeFirst => 'اول زمان‌دارها',
        TaskSort.statusOrder => 'بر اساس وضعیت',
        TaskSort.manual => 'دستی (کشیدن)',
      };
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill({required this.onTap, required this.isFa});
  final VoidCallback onTap;
  final bool isFa;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.focusTint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.today, size: 15, color: AppColors.accent),
            const SizedBox(width: 5),
            Text(
              isFa ? 'برو به امروز' : 'Today',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isFa});
  final bool isFa;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_outlined,
              size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            isFa ? 'برای افزودن کار، + را بزن' : 'Tap + to add a task',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}