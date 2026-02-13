import '../enums/muscle_group.dart';

/// Exercise with muscle targeting details.
class Exercise {
  final int id;
  final String name;
  final MuscleGroup muscleGroup;

  /// Specific muscles worked (e.g. "biceps brachii, brachialis").
  final String? targetMuscles;

  /// Portion of the muscle emphasized (e.g. "upper", "mid", "lower").
  final String? muscleRegion;

  final String? description;
  final bool isCustom;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.targetMuscles,
    this.muscleRegion,
    this.description,
    this.isCustom = false,
  });
}
