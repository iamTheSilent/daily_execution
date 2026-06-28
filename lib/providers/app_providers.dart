import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../core/l10n/app_strings.dart';
import '../data/database/database.dart';
import '../data/database/tables.dart';
import '../data/repositories/task_repository.dart';
import '../domain/task_logic.dart';

// ── زبان و متن‌ها ──────────────────────────────────────────────────────────────

final localeProvider = StateProvider<Locale>((ref) => const Locale('fa'));

final appStringsProvider = Provider<AppStrings>(
    (ref) => AppStrings(ref.watch(localeProvider)));

// ── دیتابیس ────────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── PlanRepository ─────────────────────────────────────────────────────────────

class PlanRepository {
  PlanRepository(this._db);
  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Plan>> watchPlans() => _db.watchPlans();

  Future<void> createPlan(String name) async {
    final now = DateTime.now();
    await _db.upsertPlan(PlansCompanion.insert(
      id: _uuid.v4(),
      name: name,
      orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> deletePlan(String id) => _db.deletePlan(id);
  Future<void> renamePlan(String id, String name) => _db.renamePlan(id, name);

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
    final next = TaskStatus
        .values[(task.status.index + 1) % TaskStatus.values.length];
    return _db.setStatus(task.id, next);
  }

  Future<void> deletePlanTask(String id) => _db.deleteTask(id);
}

// ── IdeaRepository (ایده = تسک با نوعِ idea) ─────────────────────────────────────

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

  /// ایده → برنامه: یه برنامه می‌سازه و خودِ ایده (با توضیحات/زمان) می‌شه اولین تسکِ داخلش
  Future<void> convertToPlan(Task idea) async {
    final now = DateTime.now();
    final planId = _uuid.v4();
    await _db.upsertPlan(PlansCompanion.insert(
      id: planId,
      name: idea.title,
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

  /// ایده → تسکِ یک روز (پیش‌فرض: امروز) با حفظِ توضیحات/زمان
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

// ── پرووایدرها ─────────────────────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => TaskRepository(ref.watch(databaseProvider)));

final planRepositoryProvider = Provider<PlanRepository>(
    (ref) => PlanRepository(ref.watch(databaseProvider)));

final ideaRepositoryProvider = Provider<IdeaRepository>(
    (ref) => IdeaRepository(ref.watch(databaseProvider)));

// ── امروز ──────────────────────────────────────────────────────────────────────

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

final todaySortProvider =
    StateProvider<TaskSort>((ref) => TaskSort.defaultSort);

final dayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final day = ref.watch(selectedDayProvider);
  final sort = ref.watch(todaySortProvider);
  return repo.watchDay(day, sort);
});

// ── برنامه‌ها و ایده‌ها ──────────────────────────────────────────────────────────

final plansProvider = StreamProvider.autoDispose<List<Plan>>(
    (ref) => ref.watch(planRepositoryProvider).watchPlans());

final ideasProvider = StreamProvider.autoDispose<List<Task>>(
    (ref) => ref.watch(ideaRepositoryProvider).watchIdeas());

final planTasksProvider =
    StreamProvider.autoDispose.family<List<Task>, String>(
        (ref, planId) =>
            ref.watch(planRepositoryProvider).watchPlanTasks(planId));

// ── بج ─────────────────────────────────────────────────────────────────────────

final planBadgeProvider = StreamProvider.autoDispose<int>(
    (ref) => ref.watch(taskRepositoryProvider).watchPlanBadge());