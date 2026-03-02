import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workouts_table.dart';

/// Junction table: Workout ↔ Exercise (many-to-many with config).
class WorkoutExercises extends Table {
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get order => integer()();
  IntColumn get sets => integer()();

  /// Target reps per set. Null for cardio exercises.
  IntColumn get reps => integer().nullable()();

  /// Rest time between sets in seconds.
  IntColumn get rest => integer().withDefault(const Constant(60))();

  /// Planned duration per set in seconds. Used for cardio exercises.
  IntColumn get duration => integer().nullable()();

  /// Superset group ID within the workout. Exercises sharing the same
  /// non-null groupId are executed back-to-back before rest.
  IntColumn get groupId => integer().nullable()();

  /// Free-text execution notes for this exercise within the workout.
  /// Used for postural cues, technique reminders, or variation hints
  /// (e.g. "deitado no banco", "costas na parede").
  /// Can be set manually or by Chiron when building workouts.
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {workoutId, exerciseId};
}
