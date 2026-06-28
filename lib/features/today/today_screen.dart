import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/date/app_date.dart';
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _quickAdd(context, ref),
        ),
        centerTitle: true,
        title: Column(children: [
          Text(AppDate.primaryLong(day, mode),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(AppDate.secondaryShort(day, mode),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: () => _sortSheet(context, ref),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v == 0) return;
          ref.read(selectedDayProvider.notifier).state =
              day.add(Duration(days: v < 0 ? 1 : -1));
        },
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطا: $e')),
          data: (tasks) => tasks.isEmpty
              ? const Center(child: Text('برای افزودن کار، + را بزن'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final t = tasks[i];
                    return TaskRow(
                      task: t,
                      onCycleStatus: () =>
                          ref.read(taskRepositoryProvider).cycleStatus(t),
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(taskId: t.id),
                        ),
                      ),
                    );
                  },
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