/// A step in the training cycle: either a workout or a rest day.
class TrainingCycleStep {
  final int id;
  final int orderIndex;
  final CycleStepType type;
  final int? workoutId;

  const TrainingCycleStep({
    required this.id,
    required this.orderIndex,
    required this.type,
    this.workoutId,
  });
}

enum CycleStepType {
  workout,
  rest,
}
