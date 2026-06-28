import 'package:drift/drift.dart';

enum TaskStatus { todo, doing, done }
enum TaskBucket { day, inbox, plan, idea } // ← idea اضافه شد

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get status =>
      intEnum<TaskStatus>().withDefault(const Constant(0))();
  IntColumn get bucket => intEnum<TaskBucket>()();
  BoolColumn get focus => boolean().withDefault(const Constant(false))();
  DateTimeColumn get day => dateTime().nullable()();
  TextColumn get planId => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get timeStart => integer().nullable()();
  IntColumn get timeEnd => integer().nullable()();
  TextColumn get note => text().nullable()();
  RealColumn get orderKey => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  RealColumn get orderKey => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class IdeaFolders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get orderKey => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class IdeaItems extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  RealColumn get orderKey => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}