import '../enums/exercise_type.dart';
import '../enums/muscle_group.dart';
import '../enums/muscle_region.dart';
import '../enums/target_muscle.dart';

/// A specific muscle targeted by an exercise, with an optional region emphasis.
class ExerciseMuscleFocus {
  final TargetMuscle muscle;
  final MuscleRegion? region;

  const ExerciseMuscleFocus(this.muscle, [this.region]);
}

/// Exercise with muscle targeting details.
class Exercise {
  final int id;
  final String name;
  final MuscleGroup muscleGroup;
  final ExerciseType type;
  final String? description;
  final bool isVerified;

  /// Muscles this exercise targets, loaded from the junction table.
  final List<ExerciseMuscleFocus> muscles;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.type = ExerciseType.strength,
    this.description,
    this.isVerified = false,
    this.muscles = const [],
  });

  bool get isCardio => type == ExerciseType.cardio;
}
