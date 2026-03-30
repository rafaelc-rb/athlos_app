import '../../../../core/errors/result.dart';
import '../entities/progression_rule.dart';

/// Contract for progression rule persistence.
abstract interface class ProgressionRuleRepository {
  /// All rules for a given program.
  Future<Result<List<ProgressionRule>>> getByProgram(int programId);

  /// Single rule for a program + exercise pair, or null.
  Future<Result<ProgressionRule?>> getByProgramAndExercise(
    int programId,
    int exerciseId,
  );

  Future<Result<int>> create(ProgressionRule rule);
  Future<Result<void>> update(ProgressionRule rule);
  Future<Result<void>> delete(int ruleId);

  /// Replace all rules for a program atomically.
  Future<Result<void>> replaceAllForProgram(
    int programId,
    List<ProgressionRule> rules,
  );
}
