import 'package:drift/drift.dart';
import 'connection.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks, Plans, IdeaFolders, IdeaItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(ideaItems, ideaItems.scheduledAt);
          }
        },
      );

  // ─── Tasks (شاملِ ایده‌ها) ───────────────────────────────────────────────────
  Stream<List<Task>> watchDayTasks(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.bucket.equalsValue(TaskBucket.day) &
              t.day.isBiggerOrEqualValue(start) &
              t.day.isSmallerThanValue(end)))
        .watch();
  }

  Stream<List<Task>> watchInbox() => (select(tasks)
        ..where((t) => t.bucket.equalsValue(TaskBucket.inbox))
        ..orderBy([(t) => OrderingTerm.asc(t.orderKey)]))
      .watch();

  Stream<List<Task>> watchPlanTasks(String planId) =>
      (select(tasks)..where((t) => t.planId.equals(planId))).watch();

  Stream<List<Task>> watchIdeaTasks() => (select(tasks)
        ..where((t) => t.bucket.equalsValue(TaskBucket.idea))
        ..orderBy([(t) => OrderingTerm.asc(t.orderKey)]))
      .watch();

  Future<Task> getTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingle();

  Stream<int> watchPlanBadgeCount() {
    final endOfToday =
        DateTime.now().copyWith(hour: 23, minute: 59, second: 59);
    final query = selectOnly(tasks)
      ..addColumns([tasks.id.count()])
      ..where(tasks.bucket.equalsValue(TaskBucket.plan) &
          tasks.dueDate.isSmallerOrEqualValue(endOfToday) &
          tasks.status.equals(TaskStatus.done.index).not());
    return query.map((row) => row.read(tasks.id.count()) ?? 0).watchSingle();
  }

  Future<void> upsertTask(TasksCompanion t) =>
      into(tasks).insertOnConflictUpdate(t);

  Future<void> updateTaskFields(String id, TasksCompanion changes) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(changes);

  Future<void> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<void> setStatus(String id, TaskStatus status) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ─── Plans ───────────────────────────────────────────────────────────────────
  Stream<List<Plan>> watchPlans() =>
      (select(plans)..orderBy([(p) => OrderingTerm.asc(p.orderKey)])).watch();

  Future<void> upsertPlan(PlansCompanion p) =>
      into(plans).insertOnConflictUpdate(p);

  Future<void> deletePlan(String id) =>
      (delete(plans)..where((p) => p.id.equals(id))).go();

  Future<void> renamePlan(String id, String newName) =>
      (update(plans)..where((p) => p.id.equals(id))).write(
        PlansCompanion(
          name: Value(newName),
          updatedAt: Value(DateTime.now()),
        ),
      );
}