import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/enums/muscle_group.dart';
import '../../domain/enums/muscle_region.dart';
import '../../domain/enums/target_muscle.dart';

typedef _MuscleFocus = ({TargetMuscle muscle, MuscleRegion? region});

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
            isVerified: const Value(true),
            description: const Value.absent(),
          ),
        );
    exerciseIds[item.name] = id;

    for (final focus in item.muscles) {
      await db.into(db.exerciseTargetMuscles).insert(
            ExerciseTargetMusclesCompanion(
              exerciseId: Value(id),
              targetMuscle: Value(focus.muscle),
              muscleRegion: Value(focus.region),
            ),
          );
    }

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
  final List<_MuscleFocus> muscles;
  final List<String> equipmentKeys;

  const _SeedExercise(
    this.name,
    this.muscleGroup, {
    this.muscles = const [],
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
      muscles: [
        (muscle: TargetMuscle.pectoralisMajor, region: MuscleRegion.mid),
        (muscle: TargetMuscle.anteriorDeltoid, region: null),
        (muscle: TargetMuscle.tricepsBrachii, region: null),
      ],
      equipmentKeys: ['barbell', 'flatBench']),
  _SeedExercise('inclineBarbellBenchPress', MuscleGroup.chest,
      muscles: [
        (muscle: TargetMuscle.pectoralisMajor, region: MuscleRegion.upper),
        (muscle: TargetMuscle.anteriorDeltoid, region: null),
      ],
      equipmentKeys: ['barbell', 'adjustableBench']),
  _SeedExercise('dumbbellFly', MuscleGroup.chest,
      muscles: [
        (muscle: TargetMuscle.pectoralisMajor, region: MuscleRegion.mid),
      ],
      equipmentKeys: ['dumbbell', 'flatBench']),
  _SeedExercise('pushUp', MuscleGroup.chest, muscles: [
    (muscle: TargetMuscle.pectoralisMajor, region: MuscleRegion.mid),
    (muscle: TargetMuscle.anteriorDeltoid, region: null),
    (muscle: TargetMuscle.tricepsBrachii, region: null),
  ]),
  _SeedExercise('cableCrossover', MuscleGroup.chest,
      muscles: [
        (muscle: TargetMuscle.pectoralisMajor, region: MuscleRegion.mid),
      ],
      equipmentKeys: ['cableMachine']),
  _SeedExercise('machineChestPress', MuscleGroup.chest,
      muscles: [
        (muscle: TargetMuscle.pectoralisMajor, region: MuscleRegion.mid),
        (muscle: TargetMuscle.tricepsBrachii, region: null),
      ],
      equipmentKeys: ['chestPressMachine']),

  // --- Back ---
  _SeedExercise('pullUp', MuscleGroup.back,
      muscles: [
        (muscle: TargetMuscle.latissimusDorsi, region: null),
        (muscle: TargetMuscle.bicepsBrachii, region: null),
        (muscle: TargetMuscle.rhomboids, region: null),
      ],
      equipmentKeys: ['pullUpBar']),
  _SeedExercise('barbellRow', MuscleGroup.back,
      muscles: [
        (muscle: TargetMuscle.latissimusDorsi, region: null),
        (muscle: TargetMuscle.rhomboids, region: null),
        (muscle: TargetMuscle.rearDeltoid, region: null),
      ],
      equipmentKeys: ['barbell']),
  _SeedExercise('latPulldown', MuscleGroup.back,
      muscles: [
        (muscle: TargetMuscle.latissimusDorsi, region: null),
        (muscle: TargetMuscle.bicepsBrachii, region: null),
      ],
      equipmentKeys: ['latPulldownMachine']),
  _SeedExercise('seatedCableRow', MuscleGroup.back,
      muscles: [
        (muscle: TargetMuscle.rhomboids, region: null),
        (muscle: TargetMuscle.latissimusDorsi, region: null),
        (muscle: TargetMuscle.rearDeltoid, region: null),
      ],
      equipmentKeys: ['cableMachine']),
  _SeedExercise('dumbbellRow', MuscleGroup.back,
      muscles: [
        (muscle: TargetMuscle.latissimusDorsi, region: null),
        (muscle: TargetMuscle.rhomboids, region: null),
      ],
      equipmentKeys: ['dumbbell', 'flatBench']),

  // --- Shoulders ---
  _SeedExercise('overheadPress', MuscleGroup.shoulders,
      muscles: [
        (muscle: TargetMuscle.anteriorDeltoid, region: null),
        (muscle: TargetMuscle.lateralDeltoid, region: null),
        (muscle: TargetMuscle.tricepsBrachii, region: null),
      ],
      equipmentKeys: ['barbell']),
  _SeedExercise('lateralRaise', MuscleGroup.shoulders,
      muscles: [
        (muscle: TargetMuscle.lateralDeltoid, region: null),
      ],
      equipmentKeys: ['dumbbell']),
  _SeedExercise('facePull', MuscleGroup.shoulders,
      muscles: [
        (muscle: TargetMuscle.rearDeltoid, region: null),
        (muscle: TargetMuscle.rhomboids, region: null),
      ],
      equipmentKeys: ['cableMachine']),
  _SeedExercise('arnoldPress', MuscleGroup.shoulders,
      muscles: [
        (muscle: TargetMuscle.anteriorDeltoid, region: null),
        (muscle: TargetMuscle.lateralDeltoid, region: null),
      ],
      equipmentKeys: ['dumbbell']),

  // --- Biceps ---
  _SeedExercise('barbellCurl', MuscleGroup.biceps,
      muscles: [
        (muscle: TargetMuscle.bicepsBrachii, region: MuscleRegion.longHead),
      ],
      equipmentKeys: ['barbell']),
  _SeedExercise('dumbbellCurl', MuscleGroup.biceps,
      muscles: [
        (muscle: TargetMuscle.bicepsBrachii, region: null),
      ],
      equipmentKeys: ['dumbbell']),
  _SeedExercise('hammerCurl', MuscleGroup.biceps,
      muscles: [
        (muscle: TargetMuscle.brachialis, region: null),
        (muscle: TargetMuscle.brachioradialis, region: null),
      ],
      equipmentKeys: ['dumbbell']),
  _SeedExercise('preacherCurl', MuscleGroup.biceps,
      muscles: [
        (muscle: TargetMuscle.bicepsBrachii, region: MuscleRegion.shortHead),
      ],
      equipmentKeys: ['ezBar']),

  // --- Triceps ---
  _SeedExercise('tricepsPushdown', MuscleGroup.triceps,
      muscles: [
        (muscle: TargetMuscle.tricepsBrachii, region: MuscleRegion.lateralHead),
      ],
      equipmentKeys: ['cableMachine']),
  _SeedExercise('skullCrusher', MuscleGroup.triceps,
      muscles: [
        (muscle: TargetMuscle.tricepsBrachii, region: MuscleRegion.longHead),
      ],
      equipmentKeys: ['ezBar', 'flatBench']),
  _SeedExercise('overheadTricepsExtension', MuscleGroup.triceps,
      muscles: [
        (muscle: TargetMuscle.tricepsBrachii, region: MuscleRegion.longHead),
      ],
      equipmentKeys: ['dumbbell']),
  _SeedExercise('diamondPushUp', MuscleGroup.triceps, muscles: [
    (muscle: TargetMuscle.tricepsBrachii, region: null),
    (muscle: TargetMuscle.pectoralisMajor, region: null),
  ]),

  // --- Quadriceps ---
  _SeedExercise('barbellSquat', MuscleGroup.quadriceps,
      muscles: [
        (muscle: TargetMuscle.rectusFemoris, region: null),
        (muscle: TargetMuscle.vastusLateralis, region: null),
        (muscle: TargetMuscle.vastusMedialis, region: null),
        (muscle: TargetMuscle.gluteusMaximus, region: null),
        (muscle: TargetMuscle.bicepsFemoris, region: null),
      ],
      equipmentKeys: ['barbell', 'squatRack']),
  _SeedExercise('legPress', MuscleGroup.quadriceps,
      muscles: [
        (muscle: TargetMuscle.rectusFemoris, region: null),
        (muscle: TargetMuscle.vastusLateralis, region: null),
        (muscle: TargetMuscle.gluteusMaximus, region: null),
      ],
      equipmentKeys: ['legPressMachine']),
  _SeedExercise('lunge', MuscleGroup.quadriceps,
      muscles: [
        (muscle: TargetMuscle.rectusFemoris, region: null),
        (muscle: TargetMuscle.vastusLateralis, region: null),
        (muscle: TargetMuscle.gluteusMaximus, region: null),
      ],
      equipmentKeys: ['dumbbell']),
  _SeedExercise('bulgarianSplitSquat', MuscleGroup.quadriceps,
      muscles: [
        (muscle: TargetMuscle.rectusFemoris, region: null),
        (muscle: TargetMuscle.vastusLateralis, region: null),
        (muscle: TargetMuscle.gluteusMaximus, region: null),
      ],
      equipmentKeys: ['dumbbell', 'flatBench']),

  // --- Hamstrings ---
  _SeedExercise('romanianDeadlift', MuscleGroup.hamstrings,
      muscles: [
        (muscle: TargetMuscle.bicepsFemoris, region: null),
        (muscle: TargetMuscle.semitendinosus, region: null),
        (muscle: TargetMuscle.gluteusMaximus, region: null),
        (muscle: TargetMuscle.erectorSpinae, region: null),
      ],
      equipmentKeys: ['barbell']),
  _SeedExercise('nordicCurl', MuscleGroup.hamstrings, muscles: [
    (muscle: TargetMuscle.bicepsFemoris, region: null),
    (muscle: TargetMuscle.semitendinosus, region: null),
  ]),

  // --- Glutes ---
  _SeedExercise('hipThrust', MuscleGroup.glutes,
      muscles: [
        (muscle: TargetMuscle.gluteusMaximus, region: null),
        (muscle: TargetMuscle.bicepsFemoris, region: null),
      ],
      equipmentKeys: ['barbell', 'flatBench']),
  _SeedExercise('gluteBridge', MuscleGroup.glutes, muscles: [
    (muscle: TargetMuscle.gluteusMaximus, region: null),
  ]),
  _SeedExercise('cableKickback', MuscleGroup.glutes,
      muscles: [
        (muscle: TargetMuscle.gluteusMaximus, region: null),
      ],
      equipmentKeys: ['cableMachine']),

  // --- Calves ---
  _SeedExercise('standingCalfRaise', MuscleGroup.calves,
      muscles: [
        (muscle: TargetMuscle.gastrocnemius, region: null),
      ],
      equipmentKeys: ['smithMachine']),

  // --- Abs ---
  _SeedExercise('crunch', MuscleGroup.abs, muscles: [
    (muscle: TargetMuscle.rectusAbdominis, region: MuscleRegion.upper),
  ]),
  _SeedExercise('plank', MuscleGroup.abs, muscles: [
    (muscle: TargetMuscle.rectusAbdominis, region: null),
    (muscle: TargetMuscle.transverseAbdominis, region: null),
    (muscle: TargetMuscle.obliques, region: null),
  ]),
  _SeedExercise('hangingLegRaise', MuscleGroup.abs,
      muscles: [
        (muscle: TargetMuscle.rectusAbdominis, region: MuscleRegion.lower),
        (muscle: TargetMuscle.hipFlexors, region: null),
      ],
      equipmentKeys: ['pullUpBar']),
  _SeedExercise('abWheelRollout', MuscleGroup.abs,
      muscles: [
        (muscle: TargetMuscle.rectusAbdominis, region: null),
        (muscle: TargetMuscle.obliques, region: null),
      ],
      equipmentKeys: ['abWheel']),

  // --- Forearms ---
  _SeedExercise('wristCurl', MuscleGroup.forearms,
      muscles: [
        (muscle: TargetMuscle.wristFlexors, region: null),
      ],
      equipmentKeys: ['barbell']),
  _SeedExercise('reverseWristCurl', MuscleGroup.forearms,
      muscles: [
        (muscle: TargetMuscle.wristExtensors, region: null),
      ],
      equipmentKeys: ['barbell']),

  // --- Full Body ---
  _SeedExercise('deadlift', MuscleGroup.fullBody,
      muscles: [
        (muscle: TargetMuscle.bicepsFemoris, region: null),
        (muscle: TargetMuscle.gluteusMaximus, region: null),
        (muscle: TargetMuscle.erectorSpinae, region: null),
        (muscle: TargetMuscle.trapezius, region: null),
      ],
      equipmentKeys: ['barbell']),
  _SeedExercise('burpee', MuscleGroup.fullBody, muscles: [
    (muscle: TargetMuscle.rectusFemoris, region: null),
    (muscle: TargetMuscle.pectoralisMajor, region: null),
    (muscle: TargetMuscle.anteriorDeltoid, region: null),
  ]),
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
