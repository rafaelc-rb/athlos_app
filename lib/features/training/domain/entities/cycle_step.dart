/// A step in the training cycle: an ordered workout reference.
class TrainingCycleStep {
  final int id;
  final int orderIndex;
  final int workoutId;

  const TrainingCycleStep({
    required this.id,
    required this.orderIndex,
    required this.workoutId,
  });
}
