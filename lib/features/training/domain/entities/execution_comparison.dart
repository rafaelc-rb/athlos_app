import 'workout_execution.dart';

/// Compares the last two finished executions of a workout (for evolution feedback).
class ExecutionComparison {
  final WorkoutExecution last;
  final WorkoutExecution previous;
  final double volumeLast;
  final double volumePrevious;

  const ExecutionComparison({
    required this.last,
    required this.previous,
    required this.volumeLast,
    required this.volumePrevious,
  });

  /// Delta in volume (last - previous). Positive = progress.
  double get volumeDelta => volumeLast - volumePrevious;

  /// Percentage change in volume, or null if previous was zero.
  double? get volumePercentChange =>
      volumePrevious > 0 ? (volumeDelta / volumePrevious) * 100 : null;
}
