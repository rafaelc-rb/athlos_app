import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/muscle_group.dart';

/// Maps a verified exercise's English key [name] to its localized display name.
/// Falls back to [name] directly for custom (user-created) items.
String localizedExerciseName(
  String name, {
  required bool isCustom,
  required AppLocalizations l10n,
}) {
  if (isCustom) return name;
  return _exerciseNameMap(l10n)[name] ?? name;
}

/// Returns the localized display name for a [MuscleGroup].
String localizedMuscleGroupName(MuscleGroup group, AppLocalizations l10n) =>
    switch (group) {
      MuscleGroup.chest => l10n.muscleGroupChest,
      MuscleGroup.back => l10n.muscleGroupBack,
      MuscleGroup.shoulders => l10n.muscleGroupShoulders,
      MuscleGroup.biceps => l10n.muscleGroupBiceps,
      MuscleGroup.triceps => l10n.muscleGroupTriceps,
      MuscleGroup.forearms => l10n.muscleGroupForearms,
      MuscleGroup.abs => l10n.muscleGroupAbs,
      MuscleGroup.quadriceps => l10n.muscleGroupQuadriceps,
      MuscleGroup.hamstrings => l10n.muscleGroupHamstrings,
      MuscleGroup.glutes => l10n.muscleGroupGlutes,
      MuscleGroup.calves => l10n.muscleGroupCalves,
      MuscleGroup.fullBody => l10n.muscleGroupFullBody,
    };

/// Maps target muscle English keys to localized names.
String localizedTargetMuscle(String key, AppLocalizations l10n) =>
    _targetMuscleMap(l10n)[key] ?? key;

/// Parses a comma-separated target muscles string into localized names.
String localizedTargetMuscles(String? raw, AppLocalizations l10n) {
  if (raw == null || raw.isEmpty) return '';
  return raw
      .split(',')
      .map((s) => s.trim())
      .map((key) => localizedTargetMuscle(key, l10n))
      .join(', ');
}

/// Maps muscle region English keys to localized names.
String localizedMuscleRegion(String? key, AppLocalizations l10n) {
  if (key == null || key.isEmpty) return '';
  return _muscleRegionMap(l10n)[key] ?? key;
}

Map<String, String> _exerciseNameMap(AppLocalizations l10n) => {
      'flatBarbellBenchPress': l10n.exerciseFlatBarbellBenchPress,
      'inclineBarbellBenchPress': l10n.exerciseInclineBarbellBenchPress,
      'dumbbellFly': l10n.exerciseDumbbellFly,
      'pushUp': l10n.exercisePushUp,
      'cableCrossover': l10n.exerciseCableCrossover,
      'machineChestPress': l10n.exerciseMachineChestPress,
      'pullUp': l10n.exercisePullUp,
      'barbellRow': l10n.exerciseBarbellRow,
      'latPulldown': l10n.exerciseLatPulldown,
      'seatedCableRow': l10n.exerciseSeatedCableRow,
      'dumbbellRow': l10n.exerciseDumbbellRow,
      'overheadPress': l10n.exerciseOverheadPress,
      'lateralRaise': l10n.exerciseLateralRaise,
      'facePull': l10n.exerciseFacePull,
      'arnoldPress': l10n.exerciseArnoldPress,
      'barbellCurl': l10n.exerciseBarbellCurl,
      'dumbbellCurl': l10n.exerciseDumbbellCurl,
      'hammerCurl': l10n.exerciseHammerCurl,
      'preacherCurl': l10n.exercisePreacherCurl,
      'tricepsPushdown': l10n.exerciseTricepsPushdown,
      'skullCrusher': l10n.exerciseSkullCrusher,
      'overheadTricepsExtension': l10n.exerciseOverheadTricepsExtension,
      'diamondPushUp': l10n.exerciseDiamondPushUp,
      'barbellSquat': l10n.exerciseBarbellSquat,
      'legPress': l10n.exerciseLegPress,
      'lunge': l10n.exerciseLunge,
      'bulgarianSplitSquat': l10n.exerciseBulgarianSplitSquat,
      'romanianDeadlift': l10n.exerciseRomanianDeadlift,
      'nordicCurl': l10n.exerciseNordicCurl,
      'hipThrust': l10n.exerciseHipThrust,
      'gluteBridge': l10n.exerciseGluteBridge,
      'cableKickback': l10n.exerciseCableKickback,
      'standingCalfRaise': l10n.exerciseStandingCalfRaise,
      'crunch': l10n.exerciseCrunch,
      'plank': l10n.exercisePlank,
      'hangingLegRaise': l10n.exerciseHangingLegRaise,
      'abWheelRollout': l10n.exerciseAbWheelRollout,
      'wristCurl': l10n.exerciseWristCurl,
      'reverseWristCurl': l10n.exerciseReverseWristCurl,
      'deadlift': l10n.exerciseDeadlift,
      'burpee': l10n.exerciseBurpee,
    };

Map<String, String> _targetMuscleMap(AppLocalizations l10n) => {
      'pectoralisMajor': l10n.musclePectoralisMajor,
      'anteriorDeltoid': l10n.muscleAnteriorDeltoid,
      'lateralDeltoid': l10n.muscleLateralDeltoid,
      'rearDeltoid': l10n.muscleRearDeltoid,
      'triceps': l10n.muscleTriceps,
      'bicepsBrachii': l10n.muscleBicepsBrachii,
      'brachialis': l10n.muscleBrachialis,
      'brachioradialis': l10n.muscleBrachioradialis,
      'latissimusDorsi': l10n.muscleLatissimusDorsi,
      'rhomboids': l10n.muscleRhomboids,
      'traps': l10n.muscleTraps,
      'erectorSpinae': l10n.muscleErectorSpinae,
      'tricepsBrachii': l10n.muscleTricepsBrachii,
      'quadriceps': l10n.muscleQuadriceps,
      'hamstrings': l10n.muscleHamstrings,
      'glutes': l10n.muscleGlutes,
      'gluteusMaximus': l10n.muscleGluteusMaximus,
      'gastrocnemius': l10n.muscleGastrocnemius,
      'rectusAbdominis': l10n.muscleRectusAbdominis,
      'transverseAbdominis': l10n.muscleTransverseAbdominis,
      'obliques': l10n.muscleObliques,
      'hipFlexors': l10n.muscleHipFlexors,
      'wristFlexors': l10n.muscleWristFlexors,
      'wristExtensors': l10n.muscleWristExtensors,
      'fullBody': l10n.muscleFullBody,
      'biceps': l10n.muscleGroupBiceps,
    };

Map<String, String> _muscleRegionMap(AppLocalizations l10n) => {
      'upper': l10n.regionUpper,
      'mid': l10n.regionMid,
      'lower': l10n.regionLower,
      'lats': l10n.regionLats,
      'front': l10n.regionFront,
      'lateral': l10n.regionLateral,
      'rear': l10n.regionRear,
      'longHead': l10n.regionLongHead,
      'shortHead': l10n.regionShortHead,
      'lateralHead': l10n.regionLateralHead,
    };
