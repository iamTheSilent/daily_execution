import 'package:drift/drift.dart';
import 'connection.dart';
import 'tables.dart';

part 'database.g.dart';

/// برنامه به‌همراهِ آمارِ پیشرفتش (برای مرتب‌سازی و نوارِ پیشرفت)
class PlanWithProgress {
  const PlanWithProgress({
    required this.plan,
    required this.total,
    required this.done,
    this.dueCount = 0,
    this.overdueCount = 0,
  });
  final Plan plan;
  final int total;
  final int done;

  /// تعدادِ تسک‌هایی که موعدشون امروز یا قبل‌تره و انجام نشده (عددِ قرمز)
  final int dueCount;

  /// تعدادِ تسک‌هایی که موعدشون قبل از امروز گذشته و انجام نشده (نشانِ «عقب‌افتاده»)
  final int overdueCount;

  int get remaining => total - done;
  double get progress => total == 0 ? 0.0 : done / total;
  bool get isCompleted => total > 0 && done >= total;
}

@DriftDatabase(tables: [Tasks, Plans, IdeaFolders, IdeaItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(ideaItems, ideaItems.scheduledAt);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.ideaFolderId);
            await m.addColumn(ideaFolders, ideaFolders.icon);
          }
          if (from < 4) {
            await m.addColumn(plans, plans.icon);
          }
          if (from < 5) {
            await m.addColumn(plans, plans.pinned);
            await m.addColumn(plans, plans.archived);
          }
        },
      );

  // ─── Tasks (شاملِ ایده‌ها) ───
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

  // ─── Plans ───
  Stream<List<Plan>> watchPlans() =>
      (select(plans)..orderBy([(p) => OrderingTerm.asc(p.orderKey)])).watch();

  /// برنامه‌ها + آمارِ پیشرفت (تعدادِ انجام‌شده و کل)
  Stream<List<PlanWithProgress>> watchPlansWithProgress() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final doneExpr = tasks.id.count(
      filter: tasks.status.equalsValue(TaskStatus.done),
    );
    final totalExpr = tasks.id.count();
    // موعدشون امروز یا قبل‌تره و انجام نشده (عددِ قرمز)
    final dueExpr = tasks.id.count(
      filter: tasks.status.equalsValue(TaskStatus.done).not() &
          tasks.dueDate.isSmallerOrEqualValue(endOfToday),
    );
    // موعدشون قبل از امروز گذشته و انجام نشده (نشانِ عقب‌افتاده)
    final overdueExpr = tasks.id.count(
      filter: tasks.status.equalsValue(TaskStatus.done).not() &
          tasks.dueDate.isSmallerThanValue(startOfToday),
    );
    final query = select(plans).join([
      leftOuterJoin(
        tasks,
        tasks.planId.equalsExp(plans.id) &
            tasks.bucket.equalsValue(TaskBucket.plan),
      ),
    ])
      ..addColumns([doneExpr, totalExpr, dueExpr, overdueExpr])
      ..groupBy([plans.id]);
    return query.watch().map(
          (rows) => rows
              .map((row) => PlanWithProgress(
                    plan: row.readTable(plans),
                    total: row.read(totalExpr) ?? 0,
                    done: row.read(doneExpr) ?? 0,
                    dueCount: row.read(dueExpr) ?? 0,
                    overdueCount: row.read(overdueExpr) ?? 0,
                  ))
              .toList(),
        );
  }

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

  /// به‌روزرسانیِ نام + ایموجیِ برنامه
  Future<void> updatePlan(String id, {required String name, String? icon}) =>
      (update(plans)..where((p) => p.id.equals(id))).write(
        PlansCompanion(
          name: Value(name),
          icon: Value(icon),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> setPlanPinned(String id, bool pinned) =>
      (update(plans)..where((p) => p.id.equals(id))).write(
        PlansCompanion(
          pinned: Value(pinned),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> setPlanArchived(String id, bool archived) =>
      (update(plans)..where((p) => p.id.equals(id))).write(
        PlansCompanion(
          archived: Value(archived),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ─── Idea Folders (دیگر در UI استفاده نمی‌شود؛ برای سازگاری نگه داشته شده) ───
  Stream<List<IdeaFolder>> watchIdeaFolders() =>
      (select(ideaFolders)..orderBy([(f) => OrderingTerm.asc(f.orderKey)]))
          .watch();

  Future<void> upsertIdeaFolder(IdeaFoldersCompanion f) =>
      into(ideaFolders).insertOnConflictUpdate(f);

  Future<void> updateIdeaFolder(String id,
          {required String name, String? icon}) =>
      (update(ideaFolders)..where((f) => f.id.equals(id))).write(
        IdeaFoldersCompanion(name: Value(name), icon: Value(icon)),
      );

  Stream<List<Task>> watchIdeasInFolder(String? folderId) {
    return (select(tasks)
          ..where((t) =>
              t.bucket.equalsValue(TaskBucket.idea) &
              (folderId == null
                  ? t.ideaFolderId.isNull()
                  : t.ideaFolderId.equals(folderId)))
          ..orderBy([(t) => OrderingTerm.asc(t.orderKey)]))
        .watch();
  }

  Future<void> moveIdeaToFolder(String ideaId, String? folderId) =>
      (update(tasks)..where((t) => t.id.equals(ideaId))).write(
        TasksCompanion(
          ideaFolderId: Value(folderId),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteFolderAndIdeas(String folderId) async {
    await (delete(tasks)
          ..where((t) =>
              t.bucket.equalsValue(TaskBucket.idea) &
              t.ideaFolderId.equals(folderId)))
        .go();
    await (delete(ideaFolders)..where((f) => f.id.equals(folderId))).go();
  }

  Future<void> deleteFolderKeepIdeas(String folderId) async {
    await (update(tasks)
          ..where((t) =>
              t.bucket.equalsValue(TaskBucket.idea) &
              t.ideaFolderId.equals(folderId)))
        .write(TasksCompanion(
      ideaFolderId: const Value(null),
      updatedAt: Value(DateTime.now()),
    ));
    await (delete(ideaFolders)..where((f) => f.id.equals(folderId))).go();
  }
}