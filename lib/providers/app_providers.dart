import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/l10n/app_strings.dart';
import '../data/database/database.dart';
import '../data/database/tables.dart';
import '../data/repositories/task_repository.dart';
import '../domain/task_logic.dart';

// ── زبان و متن‌ها ──
// زبانِ انتخاب‌شده در SharedPreferences ذخیره می‌شود تا با ری‌استارت نپرد.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fa')) {
    _load();
  }
  static const _key = 'settings.locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) state = Locale(code);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

final appStringsProvider =
    Provider<AppStrings>((ref) => AppStrings(ref.watch(localeProvider)));

// ── دیتابیس ──
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── PlanRepository ──
class PlanRepository {
  PlanRepository(this._db);
  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Plan>> watchPlans() => _db.watchPlans();

  Stream<List<PlanWithProgress>> watchPlansWithProgress() =>
      _db.watchPlansWithProgress();

  /// بجِ پایینِ تبِ برنامه‌ها: تسک‌هایی که موعدشون امروز یا قبل‌تره و انجام نشده
  Stream<int> watchDueBadge() => _db.watchPlanBadgeCount();

  Future<void> createPlan(String name,
      {String? icon, String? description}) async {
    final now = DateTime.now();
    await _db.upsertPlan(PlansCompanion.insert(
      id: _uuid.v4(),
      name: name,
      icon: Value(icon),
      description: Value(description),
      orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> updatePlan(String id,
          {required String name, String? icon, String? description}) =>
      _db.updatePlan(id, name: name, icon: icon, description: description);

  Future<void> setPinned(String id, bool pinned) =>
      _db.setPlanPinned(id, pinned);

  Future<void> setArchived(String id, bool archived) =>
      _db.setPlanArchived(id, archived);

  Future<void> deletePlan(String id) => _db.deletePlan(id);

  // تسک‌های داخلِ یک برنامه
  Stream<List<Task>> watchPlanTasks(String planId) =>
      _db.watchPlanTasks(planId);

  Future<void> createPlanTask({
    required String planId,
    required String title,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    await _db.upsertTask(TasksCompanion.insert(
      id: _uuid.v4(),
      title: title,
      bucket: TaskBucket.plan,
      planId: Value(planId),
      dueDate: Value(dueDate),
      orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> cyclePlanTaskStatus(Task task) {
    final next =
        TaskStatus.values[(task.status.index + 1) % TaskStatus.values.length];
    return _db.setStatus(task.id, next);
  }

  Future<void> deletePlanTask(String id) => _db.deleteTask(id);
}

// ── IdeaRepository (ایده = تسک با نوعِ idea) ──
class IdeaRepository {
  IdeaRepository(this._db);
  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Task>> watchIdeas() => _db.watchIdeaTasks();

  Future<Task> getIdea(String id) => _db.getTaskById(id);

  Future<void> addIdea(String title) async {
    final now = DateTime.now();
    await _db.upsertTask(TasksCompanion.insert(
      id: _uuid.v4(),
      title: title,
      bucket: TaskBucket.idea,
      orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> updateIdea(
    String id, {
    required String title,
    required String note,
    required DateTime? scheduledAt,
  }) {
    return _db.updateTaskFields(
      id,
      TasksCompanion(
        title: Value(title),
        note: Value(note.isEmpty ? null : note),
        dueDate: Value(scheduledAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteIdea(String id) => _db.deleteTask(id);

  /// چرخشِ وضعیت (انجام‌نشده ← در حال انجام ← انجام‌شده)
  Future<void> cycleStatus(Task idea) {
    final next =
        TaskStatus.values[(idea.status.index + 1) % TaskStatus.values.length];
    return _db.setStatus(idea.id, next);
  }

  /// ایده → برنامهٔ تازه (با اسم و ایموجیِ دلخواه). خودِ ایده اولین تسکِ برنامه می‌شود.
  Future<void> convertToPlan(Task idea,
      {required String name, String? icon}) async {
    final now = DateTime.now();
    final planId = _uuid.v4();
    await _db.upsertPlan(PlansCompanion.insert(
      id: planId,
      name: name,
      icon: Value(icon),
      orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
      createdAt: now,
      updatedAt: now,
    ));
    await _db.updateTaskFields(
      idea.id,
      TasksCompanion(
        bucket: const Value(TaskBucket.plan),
        planId: Value(planId),
        updatedAt: Value(now),
      ),
    );
  }

  /// ایده → افزودن به یک برنامهٔ موجود
  Future<void> addToPlan(Task idea, String planId) {
    return _db.updateTaskFields(
      idea.id,
      TasksCompanion(
        bucket: const Value(TaskBucket.plan),
        planId: Value(planId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// ایده → تسکِ یک روز (امروز یا هر تاریخِ دیگر)
  Future<void> sendToDay(Task idea, DateTime day) {
    return _db.updateTaskFields(
      idea.id,
      TasksCompanion(
        bucket: const Value(TaskBucket.day),
        day: Value(DateTime(day.year, day.month, day.day)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

// ── پرووایدرها ──
final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => TaskRepository(ref.watch(databaseProvider)));

final planRepositoryProvider = Provider<PlanRepository>(
    (ref) => PlanRepository(ref.watch(databaseProvider)));

final ideaRepositoryProvider = Provider<IdeaRepository>(
    (ref) => IdeaRepository(ref.watch(databaseProvider)));

// ── امروز ──
final selectedDayProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

final todaySortProvider = StateProvider<TaskSort>((ref) => TaskSort.defaultSort);

final dayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final day = ref.watch(selectedDayProvider);
  final sort = ref.watch(todaySortProvider);
  return repo.watchDay(day, sort);
});

// ── برنامه‌ها و ایده‌ها ──
final plansProvider = StreamProvider.autoDispose<List<Plan>>(
    (ref) => ref.watch(planRepositoryProvider).watchPlans());

final plansWithProgressProvider =
    StreamProvider.autoDispose<List<PlanWithProgress>>(
        (ref) => ref.watch(planRepositoryProvider).watchPlansWithProgress());

final ideasProvider = StreamProvider.autoDispose<List<Task>>(
    (ref) => ref.watch(ideaRepositoryProvider).watchIdeas());

final planTasksProvider =
    StreamProvider.autoDispose.family<List<Task>, String>((ref, planId) =>
        ref.watch(planRepositoryProvider).watchPlanTasks(planId));

// ── بج ──
final planBadgeProvider = StreamProvider.autoDispose<int>(
    (ref) => ref.watch(planRepositoryProvider).watchDueBadge());