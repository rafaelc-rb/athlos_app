import 'package:drift/drift.dart';

import 'workouts_table.dart';

class WorkoutExecutions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  DateTimeColumn get startedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}
