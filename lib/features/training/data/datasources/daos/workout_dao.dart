import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/workout_exercises_table.dart';
import '../tables/workouts_table.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [Workouts, WorkoutExercises, Exercises])
class WorkoutDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Future<List<Workout>> getAll() => select(workouts).get();

  Future<Workout?> getById(int id) =>
      (select(workouts)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<int> create(WorkoutsCompanion entry) =>
      into(workouts).insert(entry);

  Future<void> updateById(int id, WorkoutsCompanion entry) =>
      (update(workouts)..where((w) => w.id.equals(id))).write(entry);

  Future<void> deleteById(int id) async {
    await (delete(workoutExercises)
          ..where((we) => we.workoutId.equals(id)))
        .go();
    await (delete(workouts)..where((w) => w.id.equals(id))).go();
  }

  // --- Workout exercises ---

  Future<List<WorkoutExercise>> getExercises(int workoutId) =>
      (select(workoutExercises)
            ..where((we) => we.workoutId.equals(workoutId))
            ..orderBy([(we) => OrderingTerm.asc(we.order)]))
          .get();

  Future<void> setExercises(
    int workoutId,
    List<WorkoutExercisesCompanion> entries,
  ) async {
    await (delete(workoutExercises)
          ..where((we) => we.workoutId.equals(workoutId)))
        .go();
    for (final entry in entries) {
      await into(workoutExercises).insert(entry);
    }
  }
}
