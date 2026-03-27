import '../../../../core/errors/result.dart';
import '../entities/training_program.dart';

/// Contract for training program (mesocycle) persistence.
abstract interface class ProgramRepository {
  Future<Result<List<TrainingProgram>>> getAll();
  Future<Result<TrainingProgram?>> getById(int id);
  Future<Result<TrainingProgram?>> getActive();
  Future<Result<int>> create(TrainingProgram program);
  Future<Result<void>> update(TrainingProgram program);

  /// Activates [programId] and archives any currently active program.
  Future<Result<void>> activate(int programId);
  Future<Result<void>> archive(int programId);

  /// Number of finished sessions for this program.
  Future<Result<int>> getSessionCount(int programId);
}
