import 'package:drift/drift.dart';

/// Training programs (mesocycles).
class Programs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get focus => text()();
  TextColumn get durationMode => text()();
  IntColumn get durationValue => integer()();
  IntColumn get defaultRestSeconds => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
