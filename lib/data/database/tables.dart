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
  TextColumn get ideaFolderId => text().nullable()(); // ← دیگر استفاده نمی‌شود
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get timeStart => integer().nullable()();
  IntColumn get timeEnd => integer().nullable()();
  TextColumn get note => text().nullable()();
  RealColumn get orderKey => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // Completion time for stats. Set only when status == done.
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()(); // ← ایموجیِ برنامه
  // Optional short description shown under the plan name.
  TextColumn get description => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get pinned =>
      boolean().withDefault(const Constant(false))(); // ← جدید: سنجاق
  BoolColumn get archived =>
      boolean().withDefault(const Constant(false))(); // ← جدید: بایگانی
  RealColumn get orderKey => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class IdeaFolders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
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