import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/tables.dart';

class IdeaRepository {
  IdeaRepository(this._db);
  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<IdeaItem>> watchIdeas() => _db.watchAllIdeas();

  Future<void> addIdea(String title) async {
    final folderId = await _db.getOrCreateDefaultFolder();
    final now = DateTime.now();
    await _db.upsertIdeaItem(IdeaItemsCompanion.insert(
      id: _uuid.v4(),
      folderId: folderId,
      title: title,
      orderKey: Value(now.millisecondsSinceEpoch.toDouble()),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> deleteIdea(String id) => _db.deleteIdeaItem(id);
}