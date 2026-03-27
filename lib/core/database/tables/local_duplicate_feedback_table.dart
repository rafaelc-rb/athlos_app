import 'package:drift/drift.dart';

class LocalDuplicateFeedback extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => text()();

  TextColumn get leftFingerprint => text()();

  TextColumn get rightFingerprint => text()();

  TextColumn get decision =>
      text().withDefault(const Constant('not_duplicate'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {entityType, leftFingerprint, rightFingerprint},
  ];
}
