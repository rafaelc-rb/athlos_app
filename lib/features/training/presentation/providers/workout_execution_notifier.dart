import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/result.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/workout_execution.dart';
import 'workout_notifier.dart';

part 'workout_execution_notifier.g.dart';

/// All finished workout executions, most recent first.
@riverpod
class WorkoutExecutionList extends _$WorkoutExecutionList {
  @override
  Future<List<WorkoutExecution>> build() async {
    final repo = ref.watch(workoutExecutionRepositoryProvider);
    final result = await repo.getAll();
    return result.getOrThrow();
  }

  Future<void> deleteExecution(int id) async {
    final repo = ref.read(workoutExecutionRepositoryProvider);
    final result = await repo.delete(id);
    result.getOrThrow();
    ref.invalidateSelf();
    ref.invalidate(lastFinishedWorkoutIdProvider);
  }
}
