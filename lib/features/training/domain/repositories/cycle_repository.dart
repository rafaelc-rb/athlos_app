import '../../../../core/errors/result.dart';
import '../entities/cycle_step.dart';

/// Contract for training cycle (ordered steps: workout or rest).
abstract interface class CycleRepository {
  Future<Result<List<TrainingCycleStep>>> getSteps();
  Future<Result<void>> setSteps(List<TrainingCycleStep> steps);
}
