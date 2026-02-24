import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/result.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/execution_set.dart';
import '../../domain/entities/execution_set_segment.dart';
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

/// Sets for a specific execution, with segments loaded.
@riverpod
Future<List<ExecutionSet>> executionSetsWithSegments(
    Ref ref, int executionId) async {
  final repo = ref.watch(workoutExecutionRepositoryProvider);
  final setsResult = await repo.getSets(executionId);
  final sets = setsResult.getOrThrow();

  final allSegments =
      (await repo.getSegmentsForExecution(executionId)).getOrThrow();

  // Group segments by executionSetId
  final segmentsBySetId = <int, List<ExecutionSetSegment>>{};
  for (final seg in allSegments) {
    segmentsBySetId.putIfAbsent(seg.executionSetId, () => []).add(seg);
  }

  return sets
      .map((s) {
        final segments = segmentsBySetId[s.id];
        if (segments != null && segments.isNotEmpty) {
          return ExecutionSet(
            id: s.id,
            executionId: s.executionId,
            exerciseId: s.exerciseId,
            setNumber: s.setNumber,
            plannedReps: s.plannedReps,
            plannedWeight: s.plannedWeight,
            reps: s.reps,
            weight: s.weight,
            isCompleted: s.isCompleted,
            notes: s.notes,
            segments: segments,
          );
        }
        return s;
      })
      .toList();
}
