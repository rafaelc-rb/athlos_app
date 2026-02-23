import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/enums/muscle_group.dart';

/// Seeds the database with verified exercises on first creation.
///
/// Each exercise uses an English key as [name] (localized via ARB in the UI).
/// Equipment and variation relations are resolved by name against seeded data.
Future<void> seedExercises(AppDatabase db) async {
  final equipmentIds = await _resolveEquipmentIds(db);

  final exerciseIds = <String, int>{};

  for (final item in _seedItems) {
    final id = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: item.name,
            muscleGroup: item.muscleGroup,
            targetMuscles: Value(item.targetMuscles),
            muscleRegion: Value(item.muscleRegion),
            isVerified: const Value(true),
          ),
        );
    exerciseIds[item.name] = id;

    for (final eqName in item.equipmentKeys) {
      final eqId = equipmentIds[eqName];
      if (eqId != null) {
        await db.into(db.exerciseEquipments).insert(
              ExerciseEquipmentsCompanion(
                exerciseId: Value(id),
                equipmentId: Value(eqId),
              ),
            );
      }
    }
  }

  for (final link in _variations) {
    final fromId = exerciseIds[link.from];
    final toId = exerciseIds[link.to];
    if (fromId != null && toId != null) {
      await db.into(db.exerciseVariations).insert(
            ExerciseVariationsCompanion(
              exerciseId: Value(fromId),
              variationId: Value(toId),
            ),
          );
      await db.into(db.exerciseVariations).insert(
            ExerciseVariationsCompanion(
              exerciseId: Value(toId),
              variationId: Value(fromId),
            ),
          );
    }
  }
}

Future<Map<String, int>> _resolveEquipmentIds(AppDatabase db) async {
  final rows = await db.select(db.equipments).get();
  return {for (final r in rows) r.name: r.id};
}

class _SeedExercise {
  final String name;
  final MuscleGroup muscleGroup;
  final String? targetMuscles;
  final String? muscleRegion;
  final List<String> equipmentKeys;

  const _SeedExercise(
    this.name,
    this.muscleGroup, {
    this.targetMuscles,
    this.muscleRegion,
    this.equipmentKeys = const [],
  });
}

class _Variation {
  final String from;
  final String to;
  const _Variation(this.from, this.to);
}

const _seedItems = [
  // --- Chest ---
  _SeedExercise('flatBarbellBenchPress', MuscleGroup.chest,
      targetMuscles: 'pectoralisMajor, anteriorDeltoid, triceps',
      muscleRegion: 'mid',
      equipmentKeys: ['barbell', 'flatBench']),
  _SeedExercise('inclineBarbellBenchPress', MuscleGroup.chest,
      targetMuscles: 'pectoralisMajor, anteriorDeltoid',
      muscleRegion: 'upper',
      equipmentKeys: ['barbell', 'adjustableBench']),
  _SeedExercise('dumbbellFly', MuscleGroup.chest,
      targetMuscles: 'pectoralisMajor',
      muscleRegion: 'mid',
      equipmentKeys: ['dumbbell', 'flatBench']),
  _SeedExercise('pushUp', MuscleGroup.chest,
      targetMuscles: 'pectoralisMajor, anteriorDeltoid, triceps',
      muscleRegion: 'mid'),
  _SeedExercise('cableCrossover', MuscleGroup.chest,
      targetMuscles: 'pectoralisMajor',
      muscleRegion: 'mid',
      equipmentKeys: ['cableMachine']),
  _SeedExercise('machineChestPress', MuscleGroup.chest,
      targetMuscles: 'pectoralisMajor, triceps',
      muscleRegion: 'mid',
      equipmentKeys: ['chestPressMachine']),

  // --- Back ---
  _SeedExercise('pullUp', MuscleGroup.back,
      targetMuscles: 'latissimusDorsi, biceps, rhomboids',
      muscleRegion: 'lats',
      equipmentKeys: ['pullUpBar']),
  _SeedExercise('barbellRow', MuscleGroup.back,
      targetMuscles: 'latissimusDorsi, rhomboids, rearDeltoid',
      muscleRegion: 'mid',
      equipmentKeys: ['barbell']),
  _SeedExercise('latPulldown', MuscleGroup.back,
      targetMuscles: 'latissimusDorsi, biceps',
      muscleRegion: 'lats',
      equipmentKeys: ['latPulldownMachine']),
  _SeedExercise('seatedCableRow', MuscleGroup.back,
      targetMuscles: 'rhomboids, latissimusDorsi, rearDeltoid',
      muscleRegion: 'mid',
      equipmentKeys: ['cableMachine']),
  _SeedExercise('dumbbellRow', MuscleGroup.back,
      targetMuscles: 'latissimusDorsi, rhomboids',
      muscleRegion: 'mid',
      equipmentKeys: ['dumbbell', 'flatBench']),

  // --- Shoulders ---
  _SeedExercise('overheadPress', MuscleGroup.shoulders,
      targetMuscles: 'anteriorDeltoid, lateralDeltoid, triceps',
      muscleRegion: 'front',
      equipmentKeys: ['barbell']),
  _SeedExercise('lateralRaise', MuscleGroup.shoulders,
      targetMuscles: 'lateralDeltoid',
      muscleRegion: 'lateral',
      equipmentKeys: ['dumbbell']),
  _SeedExercise('facePull', MuscleGroup.shoulders,
      targetMuscles: 'rearDeltoid, rhomboids',
      muscleRegion: 'rear',
      equipmentKeys: ['cableMachine']),
  _SeedExercise('arnoldPress', MuscleGroup.shoulders,
      targetMuscles: 'anteriorDeltoid, lateralDeltoid',
      muscleRegion: 'front',
      equipmentKeys: ['dumbbell']),

  // --- Biceps ---
  _SeedExercise('barbellCurl', MuscleGroup.biceps,
      targetMuscles: 'bicepsBrachii',
      muscleRegion: 'longHead',
      equipmentKeys: ['barbell']),
  _SeedExercise('dumbbellCurl', MuscleGroup.biceps,
      targetMuscles: 'bicepsBrachii',
      equipmentKeys: ['dumbbell']),
  _SeedExercise('hammerCurl', MuscleGroup.biceps,
      targetMuscles: 'brachialis, brachioradialis',
      equipmentKeys: ['dumbbell']),
  _SeedExercise('preacherCurl', MuscleGroup.biceps,
      targetMuscles: 'bicepsBrachii',
      muscleRegion: 'shortHead',
      equipmentKeys: ['ezBar']),

  // --- Triceps ---
  _SeedExercise('tricepsPushdown', MuscleGroup.triceps,
      targetMuscles: 'tricepsBrachii',
      muscleRegion: 'lateralHead',
      equipmentKeys: ['cableMachine']),
  _SeedExercise('skullCrusher', MuscleGroup.triceps,
      targetMuscles: 'tricepsBrachii',
      muscleRegion: 'longHead',
      equipmentKeys: ['ezBar', 'flatBench']),
  _SeedExercise('overheadTricepsExtension', MuscleGroup.triceps,
      targetMuscles: 'tricepsBrachii',
      muscleRegion: 'longHead',
      equipmentKeys: ['dumbbell']),
  _SeedExercise('diamondPushUp', MuscleGroup.triceps,
      targetMuscles: 'tricepsBrachii, pectoralisMajor'),

  // --- Quadriceps ---
  _SeedExercise('barbellSquat', MuscleGroup.quadriceps,
      targetMuscles: 'quadriceps, glutes, hamstrings',
      equipmentKeys: ['barbell', 'squatRack']),
  _SeedExercise('legPress', MuscleGroup.quadriceps,
      targetMuscles: 'quadriceps, glutes',
      equipmentKeys: ['legPressMachine']),
  _SeedExercise('lunge', MuscleGroup.quadriceps,
      targetMuscles: 'quadriceps, glutes',
      equipmentKeys: ['dumbbell']),
  _SeedExercise('bulgarianSplitSquat', MuscleGroup.quadriceps,
      targetMuscles: 'quadriceps, glutes',
      equipmentKeys: ['dumbbell', 'flatBench']),

  // --- Hamstrings ---
  _SeedExercise('romanianDeadlift', MuscleGroup.hamstrings,
      targetMuscles: 'hamstrings, glutes, erectorSpinae',
      equipmentKeys: ['barbell']),
  _SeedExercise('nordicCurl', MuscleGroup.hamstrings,
      targetMuscles: 'hamstrings'),

  // --- Glutes ---
  _SeedExercise('hipThrust', MuscleGroup.glutes,
      targetMuscles: 'gluteusMaximus, hamstrings',
      equipmentKeys: ['barbell', 'flatBench']),
  _SeedExercise('gluteBridge', MuscleGroup.glutes,
      targetMuscles: 'gluteusMaximus'),
  _SeedExercise('cableKickback', MuscleGroup.glutes,
      targetMuscles: 'gluteusMaximus',
      equipmentKeys: ['cableMachine']),

  // --- Calves ---
  _SeedExercise('standingCalfRaise', MuscleGroup.calves,
      targetMuscles: 'gastrocnemius',
      equipmentKeys: ['smithMachine']),

  // --- Abs ---
  _SeedExercise('crunch', MuscleGroup.abs,
      targetMuscles: 'rectusAbdominis', muscleRegion: 'upper'),
  _SeedExercise('plank', MuscleGroup.abs,
      targetMuscles: 'rectusAbdominis, transverseAbdominis, obliques'),
  _SeedExercise('hangingLegRaise', MuscleGroup.abs,
      targetMuscles: 'rectusAbdominis, hipFlexors',
      muscleRegion: 'lower',
      equipmentKeys: ['pullUpBar']),
  _SeedExercise('abWheelRollout', MuscleGroup.abs,
      targetMuscles: 'rectusAbdominis, obliques',
      equipmentKeys: ['abWheel']),

  // --- Forearms ---
  _SeedExercise('wristCurl', MuscleGroup.forearms,
      targetMuscles: 'wristFlexors',
      equipmentKeys: ['barbell']),
  _SeedExercise('reverseWristCurl', MuscleGroup.forearms,
      targetMuscles: 'wristExtensors',
      equipmentKeys: ['barbell']),

  // --- Full Body ---
  _SeedExercise('deadlift', MuscleGroup.fullBody,
      targetMuscles: 'hamstrings, glutes, erectorSpinae, traps',
      equipmentKeys: ['barbell']),
  _SeedExercise('burpee', MuscleGroup.fullBody,
      targetMuscles: 'fullBody'),
];

const _variations = [
  _Variation('flatBarbellBenchPress', 'inclineBarbellBenchPress'),
  _Variation('flatBarbellBenchPress', 'machineChestPress'),
  _Variation('flatBarbellBenchPress', 'pushUp'),
  _Variation('pullUp', 'latPulldown'),
  _Variation('barbellRow', 'dumbbellRow'),
  _Variation('barbellRow', 'seatedCableRow'),
  _Variation('overheadPress', 'arnoldPress'),
  _Variation('barbellCurl', 'dumbbellCurl'),
  _Variation('barbellCurl', 'preacherCurl'),
  _Variation('dumbbellCurl', 'hammerCurl'),
  _Variation('barbellSquat', 'legPress'),
  _Variation('lunge', 'bulgarianSplitSquat'),
  _Variation('hipThrust', 'gluteBridge'),
  _Variation('romanianDeadlift', 'nordicCurl'),
  _Variation('wristCurl', 'reverseWristCurl'),
  _Variation('diamondPushUp', 'tricepsPushdown'),
  _Variation('crunch', 'hangingLegRaise'),
];
