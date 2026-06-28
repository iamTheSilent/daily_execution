import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';

final taskDetailProvider = AsyncNotifierProvider.autoDispose
    .family<TaskDetailController, Task, String>(TaskDetailController.new);

class TaskDetailController
    extends AutoDisposeFamilyAsyncNotifier<Task, String> {
  @override
  Future<Task> build(String taskId) async {
    final repo = ref.watch(taskRepositoryProvider);
    final sub = repo.watchById(taskId).listen((t) => state = AsyncData(t));
    ref.onDispose(sub.cancel);
    return repo.getById(taskId);
  }

  Task? get _t => state.valueOrNull;

  Future<void> setTitle(String v) async {
    final t = _t;
    if (t == null || v.trim().isEmpty) return;
    await ref.read(taskRepositoryProvider).save(t.copyWith(title: v.trim()));
  }

  Future<void> setNote(String? v) async {
    final t = _t;
    if (t == null) return;
    await ref.read(taskRepositoryProvider).save(
          t.copyWith(note: Value(v?.isEmpty == true ? null : v)));
  }

  Future<void> setStatus(TaskStatus s) async {
    final t = _t;
    if (t == null) return;
    await ref.read(taskRepositoryProvider).save(t.copyWith(status: s));
  }

  Future<void> toggleFocus() async {
    final t = _t;
    if (t == null) return;
    await ref.read(taskRepositoryProvider).save(t.copyWith(focus: !t.focus));
  }

  Future<void> setTime({int? start, int? end}) async {
    final t = _t;
    if (t == null) return;
    await ref.read(taskRepositoryProvider).save(
          t.copyWith(timeStart: Value(start), timeEnd: Value(end)));
  }
}