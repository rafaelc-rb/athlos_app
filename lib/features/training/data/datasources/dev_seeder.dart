import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../profile/domain/enums/body_aesthetic.dart';
import '../../../profile/domain/enums/training_goal.dart';
import '../../../profile/domain/enums/training_style.dart';

/// Seeds the database with realistic test data for development.
///
/// Creates a user profile, selects user equipment, builds workouts with
/// exercises (including supersets), and generates execution history
/// (including drop sets). Only called in debug mode.
Future<void> seedDevData(AppDatabase db) async {
  final exerciseIds = await _resolveExerciseIds(db);
  final equipmentIds = await _resolveEquipmentIds(db);

  await _seedUserProfile(db);
  await _seedUserEquipments(db, equipmentIds);
  await _seedWorkoutsWithExercises(db, exerciseIds);
  await _seedExecutionHistory(db, exerciseIds);
}

Future<Map<String, int>> _resolveExerciseIds(AppDatabase db) async {
  final rows = await db.select(db.exercises).get();
  return {for (final r in rows) r.name: r.id};
}

Future<Map<String, int>> _resolveEquipmentIds(AppDatabase db) async {
  final rows = await db.select(db.equipments).get();
  return {for (final r in rows) r.name: r.id};
}

// ---------------------------------------------------------------------------
// User Profile
// ---------------------------------------------------------------------------

Future<void> _seedUserProfile(AppDatabase db) async {
  await db.into(db.userProfiles).insert(
        UserProfilesCompanion.insert(
          weight: const Value(78.0),
          height: const Value(178.0),
          age: const Value(25),
          goal: const Value(TrainingGoal.hypertrophy),
          bodyAesthetic: const Value(BodyAesthetic.athletic),
          trainingStyle: const Value(TrainingStyle.traditional),
        ),
      );
}

// ---------------------------------------------------------------------------
// User Equipment (what the user has available)
// ---------------------------------------------------------------------------

Future<void> _seedUserEquipments(
    AppDatabase db, Map<String, int> equipmentIds) async {
  const owned = [
    'barbell',
    'dumbbell',
    'ezBar',
    'weightPlates',
    'cableMachine',
    'smithMachine',
    'legPressMachine',
    'latPulldownMachine',
    'chestPressMachine',
    'pullUpBar',
    'dipStation',
    'flatBench',
    'adjustableBench',
    'squatRack',
    'resistanceBands',
  ];

  await db.batch((batch) {
    for (final name in owned) {
      final id = equipmentIds[name];
      if (id != null) {
        batch.insert(
          db.userEquipments,
          UserEquipmentsCompanion(equipmentId: Value(id)),
        );
      }
    }
  });
}

// ---------------------------------------------------------------------------
// Workouts with exercises
// ---------------------------------------------------------------------------

Future<void> _seedWorkoutsWithExercises(
    AppDatabase db, Map<String, int> exerciseIds) async {
  // --- Push Day ---
  final pushId = await db.into(db.workouts).insert(
        WorkoutsCompanion.insert(
          name: 'Push Day',
          description: const Value('Chest, shoulders & triceps'),
          sortOrder: const Value(0),
        ),
      );
  await _insertWorkoutExercises(db, pushId, exerciseIds, [
    _WE('flatBarbellBenchPress', order: 0, sets: 4, reps: 8, rest: 90),
    _WE('inclineBarbellBenchPress', order: 1, sets: 3, reps: 10, rest: 75),
    _WE('dumbbellFly', order: 2, sets: 3, reps: 12, rest: 60),
    _WE('overheadPress', order: 3, sets: 4, reps: 8, rest: 90),
    // Superset: lateral raise + face pull
    _WE('lateralRaise', order: 4, sets: 3, reps: 15, rest: 45, groupId: 1),
    _WE('facePull', order: 5, sets: 3, reps: 15, rest: 60, groupId: 1),
    _WE('tricepsPushdown', order: 6, sets: 3, reps: 12, rest: 60),
  ]);

  // --- Pull Day ---
  final pullId = await db.into(db.workouts).insert(
        WorkoutsCompanion.insert(
          name: 'Pull Day',
          description: const Value('Back & biceps'),
          sortOrder: const Value(1),
        ),
      );
  await _insertWorkoutExercises(db, pullId, exerciseIds, [
    _WE('pullUp', order: 0, sets: 4, reps: 8, rest: 90),
    _WE('barbellRow', order: 1, sets: 4, reps: 8, rest: 90),
    _WE('latPulldown', order: 2, sets: 3, reps: 10, rest: 75),
    _WE('seatedCableRow', order: 3, sets: 3, reps: 12, rest: 60),
    // Superset: barbell curl + hammer curl
    _WE('barbellCurl', order: 4, sets: 3, reps: 10, rest: 45, groupId: 1),
    _WE('hammerCurl', order: 5, sets: 3, reps: 12, rest: 60, groupId: 1),
  ]);

  // --- Leg Day ---
  final legId = await db.into(db.workouts).insert(
        WorkoutsCompanion.insert(
          name: 'Leg Day',
          description: const Value('Quads, hamstrings, glutes & calves'),
          sortOrder: const Value(2),
        ),
      );
  await _insertWorkoutExercises(db, legId, exerciseIds, [
    _WE('barbellSquat', order: 0, sets: 4, reps: 8, rest: 120),
    _WE('legPress', order: 1, sets: 3, reps: 12, rest: 90),
    _WE('romanianDeadlift', order: 2, sets: 3, reps: 10, rest: 90),
    _WE('bulgarianSplitSquat', order: 3, sets: 3, reps: 10, rest: 75),
    _WE('hipThrust', order: 4, sets: 3, reps: 12, rest: 75),
    _WE('standingCalfRaise', order: 5, sets: 4, reps: 15, rest: 45),
  ]);

  // --- Full Body (archived) ---
  await db.into(db.workouts).insert(
        WorkoutsCompanion.insert(
          name: 'Full Body',
          description: const Value('Quick full body session'),
          sortOrder: const Value(3),
          isArchived: const Value(true),
        ),
      );
}

Future<void> _insertWorkoutExercises(
  AppDatabase db,
  int workoutId,
  Map<String, int> exerciseIds,
  List<_WE> entries,
) async {
  await db.batch((batch) {
    for (final e in entries) {
      final exId = exerciseIds[e.exerciseName];
      if (exId == null) continue;
      batch.insert(
        db.workoutExercises,
        WorkoutExercisesCompanion(
          workoutId: Value(workoutId),
          exerciseId: Value(exId),
          order: Value(e.order),
          sets: Value(e.sets),
          reps: Value(e.reps),
          restSeconds: Value(e.rest),
          groupId: Value(e.groupId),
        ),
      );
    }
  });
}

// ---------------------------------------------------------------------------
// Execution History
// ---------------------------------------------------------------------------

Future<void> _seedExecutionHistory(
    AppDatabase db, Map<String, int> exerciseIds) async {
  final now = DateTime.now();

  // --- Execution 1: Push Day — 3 days ago (completed) ---
  final exec1 = await db.into(db.workoutExecutions).insert(
        WorkoutExecutionsCompanion.insert(
          workoutId: 1,
          startedAt: Value(now.subtract(const Duration(days: 3, hours: 1))),
          finishedAt:
              Value(now.subtract(const Duration(days: 3, minutes: 10))),
          notes: const Value('Good session, PR on bench press'),
        ),
      );
  await _insertCompletedSets(db, exec1, exerciseIds['flatBarbellBenchPress']!,
      planned: 8, weights: [80, 80, 82.5, 82.5], reps: [8, 8, 7, 6]);
  await _insertCompletedSets(
      db, exec1, exerciseIds['inclineBarbellBenchPress']!,
      planned: 10, weights: [50, 50, 50], reps: [10, 10, 9]);
  await _insertCompletedSets(db, exec1, exerciseIds['dumbbellFly']!,
      planned: 12, weights: [14, 14, 14], reps: [12, 12, 11]);
  await _insertCompletedSets(db, exec1, exerciseIds['overheadPress']!,
      planned: 8, weights: [40, 40, 42.5, 42.5], reps: [8, 8, 7, 6]);
  await _insertCompletedSets(db, exec1, exerciseIds['lateralRaise']!,
      planned: 15, weights: [8, 8, 8], reps: [15, 14, 13]);
  await _insertCompletedSets(db, exec1, exerciseIds['facePull']!,
      planned: 15, weights: [15, 15, 15], reps: [15, 15, 14]);
  // Triceps pushdown with a drop set on the last set
  await _insertSetsWithDropSet(
    db,
    exec1,
    exerciseIds['tricepsPushdown']!,
    planned: 12,
    normalSets: [
      (weight: 25.0, reps: 12),
      (weight: 25.0, reps: 11),
    ],
    dropSetPrimary: (weight: 25.0, reps: 10),
    dropSegments: [
      (weight: 17.5, reps: 8),
      (weight: 10.0, reps: 10),
    ],
  );

  // --- Execution 2: Pull Day — yesterday (completed) ---
  final exec2 = await db.into(db.workoutExecutions).insert(
        WorkoutExecutionsCompanion.insert(
          workoutId: 2,
          startedAt: Value(now.subtract(const Duration(days: 1, hours: 1))),
          finishedAt:
              Value(now.subtract(const Duration(days: 1, minutes: 5))),
        ),
      );
  await _insertCompletedSets(db, exec2, exerciseIds['pullUp']!,
      planned: 8, weights: [null, null, null, null], reps: [10, 9, 8, 7]);
  await _insertCompletedSets(db, exec2, exerciseIds['barbellRow']!,
      planned: 8, weights: [60, 60, 62.5, 62.5], reps: [8, 8, 7, 7]);
  await _insertCompletedSets(db, exec2, exerciseIds['latPulldown']!,
      planned: 10, weights: [50, 50, 50], reps: [10, 10, 9]);
  await _insertCompletedSets(db, exec2, exerciseIds['seatedCableRow']!,
      planned: 12, weights: [40, 40, 40], reps: [12, 12, 11]);
  await _insertCompletedSets(db, exec2, exerciseIds['barbellCurl']!,
      planned: 10, weights: [25, 25, 25], reps: [10, 10, 8]);
  await _insertCompletedSets(db, exec2, exerciseIds['hammerCurl']!,
      planned: 12, weights: [12, 12, 12], reps: [12, 11, 10]);

  // --- Execution 3: Leg Day — today (completed) ---
  final exec3 = await db.into(db.workoutExecutions).insert(
        WorkoutExecutionsCompanion.insert(
          workoutId: 3,
          startedAt: Value(now.subtract(const Duration(hours: 2))),
          finishedAt: Value(now.subtract(const Duration(minutes: 30))),
          notes: const Value('Legs were shaky after squats'),
        ),
      );
  await _insertCompletedSets(db, exec3, exerciseIds['barbellSquat']!,
      planned: 8, weights: [100, 100, 105, 105], reps: [8, 8, 6, 5]);
  await _insertCompletedSets(db, exec3, exerciseIds['legPress']!,
      planned: 12, weights: [180, 180, 180], reps: [12, 12, 10]);
  await _insertCompletedSets(db, exec3, exerciseIds['romanianDeadlift']!,
      planned: 10, weights: [70, 70, 70], reps: [10, 10, 9]);
  await _insertCompletedSets(
      db, exec3, exerciseIds['bulgarianSplitSquat']!,
      planned: 10, weights: [16, 16, 16], reps: [10, 10, 8]);
  await _insertCompletedSets(db, exec3, exerciseIds['hipThrust']!,
      planned: 12, weights: [80, 80, 80], reps: [12, 12, 11]);
  await _insertCompletedSets(db, exec3, exerciseIds['standingCalfRaise']!,
      planned: 15, weights: [60, 60, 60, 60], reps: [15, 15, 14, 13]);
}

/// Inserts completed normal sets (no drop segments).
Future<void> _insertCompletedSets(
  AppDatabase db,
  int executionId,
  int exerciseId, {
  required int planned,
  required List<double?> weights,
  required List<int> reps,
}) async {
  assert(weights.length == reps.length);
  for (var i = 0; i < weights.length; i++) {
    await db.into(db.executionSets).insert(
          ExecutionSetsCompanion.insert(
            executionId: executionId,
            exerciseId: exerciseId,
            setNumber: i + 1,
            plannedReps: planned,
            reps: reps[i],
            plannedWeight: Value(weights[i]),
            weight: Value(weights[i]),
            isCompleted: const Value(true),
          ),
        );
  }
}

/// Inserts sets where the last set is a drop set with multiple segments.
Future<void> _insertSetsWithDropSet(
  AppDatabase db,
  int executionId,
  int exerciseId, {
  required int planned,
  required List<({double weight, int reps})> normalSets,
  required ({double weight, int reps}) dropSetPrimary,
  required List<({double weight, int reps})> dropSegments,
}) async {
  var setNumber = 1;

  for (final s in normalSets) {
    await db.into(db.executionSets).insert(
          ExecutionSetsCompanion.insert(
            executionId: executionId,
            exerciseId: exerciseId,
            setNumber: setNumber++,
            plannedReps: planned,
            reps: s.reps,
            plannedWeight: Value(s.weight),
            weight: Value(s.weight),
            isCompleted: const Value(true),
          ),
        );
  }

  // Drop set
  final dropSetId = await db.into(db.executionSets).insert(
        ExecutionSetsCompanion.insert(
          executionId: executionId,
          exerciseId: exerciseId,
          setNumber: setNumber,
          plannedReps: planned,
          reps: dropSetPrimary.reps,
          plannedWeight: Value(dropSetPrimary.weight),
          weight: Value(dropSetPrimary.weight),
          isCompleted: const Value(true),
        ),
      );

  // Segment 1: primary
  await db.into(db.executionSetSegments).insert(
        ExecutionSetSegmentsCompanion.insert(
          executionSetId: dropSetId,
          segmentOrder: 1,
          reps: dropSetPrimary.reps,
          weight: Value(dropSetPrimary.weight),
        ),
      );

  // Segment 2+: drops
  for (var i = 0; i < dropSegments.length; i++) {
    await db.into(db.executionSetSegments).insert(
          ExecutionSetSegmentsCompanion.insert(
            executionSetId: dropSetId,
            segmentOrder: i + 2,
            reps: dropSegments[i].reps,
            weight: Value(dropSegments[i].weight),
          ),
        );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _WE {
  final String exerciseName;
  final int order;
  final int sets;
  final int reps;
  final int rest;
  final int? groupId;

  const _WE(
    this.exerciseName, {
    required this.order,
    required this.sets,
    required this.reps,
    required this.rest,
    this.groupId,
  });
}
