import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/tables.dart';

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

  Future<void> renamePlan(String id, String name) =>
      _db.renamePlan(id, name);
}