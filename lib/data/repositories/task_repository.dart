import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/tables.dart';
import '../../domain/task_logic.dart';

class TaskRepository {
  TaskRepository(this._db);
  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Task>> watchDay(DateTime day, TaskSort sort) =>
      _db.watchDayTasks(day).map((t) => sortDayTasks(t, sort));

  Stream<List<Task>> watchInbox() => _db.watchInbox();
  Stream<int> watchPlanBadge() => _db.watchPlanBadgeCount();

  Future<Task> getById(String id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle();

  Stream<Task> watchById(String id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).watchSingle();

  Future<String> createDayTask({
    required String title,
    required DateTime day,
    bool focus = false,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.upsertTask(TasksCompanion.insert(
      id: id,
      title: title,
      bucket: TaskBucket.day,
      day: Value(day),
      focus: Value(focus),
      orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<void> cycleStatus(Task t) =>
      _db.setStatus(t.id, nextStatus(t.status));

  // ✅ رفعِ باگِ Save: قبلاً toCompanion(true) بود و مقدارهای خالی‌شده ذخیره نمی‌شد.
  Future<void> save(Task t) => _db.upsertTask(
        t.toCompanion(false).copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> delete(String id) => _db.deleteTask(id);
}