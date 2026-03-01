import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/result.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/cycle_step.dart';
import '../../domain/entities/execution_comparison.dart';
import '../../domain/entities/workout.dart';
import 'workout_notifier.dart';

part 'training_analytics_provider.g.dart';

/// Result of "next step" in the cycle: either a workout or rest.
class NextCycleStep {
  final bool isRest;
  final Workout? workout;

  const NextCycleStep({required this.isRest, this.workout});
}

/// Single item in the unified cycle list: either rest or workout (for display as one list).
sealed class CycleListItem {
  int get stepIndex;
}

class CycleListRestItem extends CycleListItem {
  @override
  final int stepIndex;

  CycleListRestItem({required this.stepIndex});
}

class CycleListWorkoutItem extends CycleListItem {
  @override
  final int stepIndex;
  final Workout workout;

  CycleListWorkoutItem({
    required this.stepIndex,
    required this.workout,
  });
}

/// Aggregated session counts for the Training Home summary.
class TrainingHomeAnalytics {
  final Map<int, int> sessionsByActiveWorkoutId;
  final int archivedSessionsTotal;
  final int totalSessions;

  const TrainingHomeAnalytics({
    required this.sessionsByActiveWorkoutId,
    required this.archivedSessionsTotal,
    required this.totalSessions,
  });
}

/// Provides session counts: per active workout, archived total, and overall total.
/// Only finished executions are counted.
@riverpod
Future<TrainingHomeAnalytics> trainingHomeAnalytics(Ref ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final execRepo = ref.watch(workoutExecutionRepositoryProvider);

  final activeResult = await workoutRepo.getActive();
  final activeWorkouts = activeResult.getOrThrow();

  final archivedResult = await workoutRepo.getArchived();
  final archivedWorkouts = archivedResult.getOrThrow();

  final allExecutionsResult = await execRepo.getAll();
  final allExecutions = allExecutionsResult.getOrThrow();

  final sessionsByActiveWorkoutId = <int, int>{};
  for (final w in activeWorkouts) {
    final byWorkoutResult = await execRepo.getByWorkout(w.id);
    final list = byWorkoutResult.getOrThrow();
    sessionsByActiveWorkoutId[w.id] =
        list.where((e) => e.isFinished).length;
  }

  var archivedTotal = 0;
  for (final w in archivedWorkouts) {
    final byWorkoutResult = await execRepo.getByWorkout(w.id);
    final list = byWorkoutResult.getOrThrow();
    archivedTotal += list.where((e) => e.isFinished).length;
  }

  return TrainingHomeAnalytics(
    sessionsByActiveWorkoutId: sessionsByActiveWorkoutId,
    archivedSessionsTotal: archivedTotal,
    totalSessions: allExecutions.length,
  );
}

/// Last two finished executions with volume for a given workout (evolution).
@riverpod
Future<ExecutionComparison?> lastVsPreviousComparison(Ref ref, int workoutId) async {
  final repo = ref.watch(workoutExecutionRepositoryProvider);
  final result = await repo.getLastTwoFinishedWithVolume(workoutId);
  return result.getOrThrow();
}

/// Comparison for the last executed workout (for Home "Evolução recente" card).
/// Returns comparison and workout name, or null if not enough data.
@riverpod
Future<({ExecutionComparison comparison, String workoutName})?>
    lastExecutedWorkoutComparison(Ref ref) async {
  final execRepo = ref.watch(workoutExecutionRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);

  final lastResult = await execRepo.getLastFinished();
  final last = lastResult.getOrThrow();
  if (last == null) return null;

  final comparisonResult =
      await execRepo.getLastTwoFinishedWithVolume(last.workoutId);
  final comparison = comparisonResult.getOrThrow();
  if (comparison == null) return null;

  final workoutResult = await workoutRepo.getById(last.workoutId);
  final workout = workoutResult.getOrThrow();
  final name = workout?.name ?? 'Treino #${last.workoutId}';

  return (comparison: comparison, workoutName: name);
}

/// Ordered cycle steps (workout | rest). Empty when using legacy sortOrder.
@riverpod
Future<List<TrainingCycleStep>> cycleSteps(Ref ref) async {
  final repo = ref.watch(cycleRepositoryProvider);
  final result = await repo.getSteps();
  return result.getOrThrow();
}

/// Ensures every active workout is in the cycle (appends any missing). Run when loading the training module so "next workout" is always cycle-based.
@riverpod
Future<void> ensureCycleSync(Ref ref) async {
  final workouts = await ref.watch(workoutListProvider.future);
  if (workouts.isEmpty) return;
  final activeIds = workouts.map((w) => w.id).toList();
  final steps = await ref.watch(cycleStepsProvider.future);
  final inCycle = {
    for (final s in steps) if (s.workoutId != null) s.workoutId!,
  };
  final missing = activeIds.where((id) => !inCycle.contains(id)).toList();
  if (missing.isEmpty) return;
  final cycleRepo = ref.read(cycleRepositoryProvider);
  final result = await cycleRepo.syncWithActiveWorkoutIds(activeIds);
  result.getOrThrow();
  ref.invalidate(cycleStepsProvider);
}

/// Cycle steps with archived workouts removed (only active workout steps + rest).
/// Use this for display and "next step" logic so archived workouts never appear in the cycle.
@riverpod
Future<List<TrainingCycleStep>> effectiveCycleSteps(Ref ref) async {
  final steps = await ref.watch(cycleStepsProvider.future);
  final active = await ref.watch(workoutListProvider.future);
  final activeIds = {for (final w in active) w.id};
  return steps
      .where((s) =>
          s.type == CycleStepType.rest ||
          (s.workoutId != null && activeIds.contains(s.workoutId)))
      .toList();
}

/// Result of the unified cycle list: items in cycle order (rest + workout) and whether order comes from cycle (true) or fallback sortOrder (false).
class CycleListData {
  final List<CycleListItem> items;
  final bool isFromCycle;

  const CycleListData({required this.items, required this.isFromCycle});
}

/// Unified list for the workouts screen: cycle steps as rest tiles + workout cards in order.
/// When the cycle has steps, [isFromCycle] is true and reorder updates the cycle; when empty, fallback to workout sortOrder.
@riverpod
Future<CycleListData> cycleListItems(Ref ref) async {
  final steps = await ref.watch(effectiveCycleStepsProvider.future);
  final workouts = await ref.watch(workoutListProvider.future);
  final workoutRepo = ref.watch(workoutRepositoryProvider);

  if (steps.isNotEmpty) {
    final items = <CycleListItem>[];
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.type == CycleStepType.rest) {
        items.add(CycleListRestItem(stepIndex: i));
      } else if (s.workoutId != null) {
        final result = await workoutRepo.getById(s.workoutId!);
        final workout = result.getOrThrow();
        if (workout != null) {
          items.add(CycleListWorkoutItem(stepIndex: i, workout: workout));
        }
      }
    }
    return CycleListData(items: items, isFromCycle: true);
  }

  if (workouts.isEmpty) {
    return const CycleListData(items: [], isFromCycle: false);
  }

  final ordered = workouts
      .where((w) => w.sortOrder != null)
      .toList()
    ..sort((a, b) => a.sortOrder!.compareTo(b.sortOrder!));
  if (ordered.isEmpty) {
    return CycleListData(
      items: workouts
          .map((w) => CycleListWorkoutItem(stepIndex: 0, workout: w))
          .toList(),
      isFromCycle: false,
    );
  }
  return CycleListData(
    items: ordered
        .asMap()
        .entries
        .map((e) => CycleListWorkoutItem(
              stepIndex: e.key,
              workout: e.value,
            ))
        .toList(),
    isFromCycle: false,
  );
}

/// Next step in the cycle: workout or rest.
/// When cycle steps are empty, returns null and UI should use [nextWorkoutProvider].
/// Uses [effectiveCycleStepsProvider] so archived workouts are ignored.
@riverpod
Future<NextCycleStep?> nextCycleStep(Ref ref) async {
  final stepsAsync = ref.watch(effectiveCycleStepsProvider);
  final lastIdAsync = ref.watch(lastFinishedWorkoutIdProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);

  final steps = stepsAsync.value;
  if (steps == null || steps.isEmpty) return null;

  final workoutStepIndices = <int>[];
  for (var i = 0; i < steps.length; i++) {
    if (steps[i].type == CycleStepType.workout) workoutStepIndices.add(i);
  }
  if (workoutStepIndices.isEmpty) return null;

  final lastWorkoutId = lastIdAsync.value;
  int nextStepIndex;
  if (lastWorkoutId == null) {
    nextStepIndex = 0;
  } else {
    var lastStepIndex = -1;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].type == CycleStepType.workout &&
          steps[i].workoutId == lastWorkoutId) {
        lastStepIndex = i;
        break;
      }
    }
    nextStepIndex = lastStepIndex < 0 ? 0 : (lastStepIndex + 1) % steps.length;
  }

  final next = steps[nextStepIndex];
  if (next.type == CycleStepType.rest) {
    return const NextCycleStep(isRest: true, workout: null);
  }
  if (next.workoutId == null) return null;
  final workoutResult = await workoutRepo.getById(next.workoutId!);
  final workout = workoutResult.getOrThrow();
  return NextCycleStep(isRest: false, workout: workout);
}

/// Workout to start when the user taps "Iniciar próximo treino".
/// When the next step is rest, returns the first workout after that rest so the user can start training again.
@riverpod
Future<Workout?> nextWorkoutToStart(Ref ref) async {
  final nextStepAsync = ref.watch(nextCycleStepProvider);
  final nextStep = nextStepAsync.value;
  if (nextStep == null) {
    return ref.watch(nextWorkoutProvider);
  }
  if (!nextStep.isRest && nextStep.workout != null) {
    return nextStep.workout;
  }
  if (!nextStep.isRest) return null;
  final stepsAsync = ref.watch(effectiveCycleStepsProvider);
  final steps = stepsAsync.value;
  if (steps == null || steps.isEmpty) return null;
  final nextIndexAsync = ref.watch(nextCycleStepIndexProvider);
  final nextIndex = nextIndexAsync.value;
  if (nextIndex == null) return null;
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  for (var i = 1; i < steps.length; i++) {
    final idx = (nextIndex + i) % steps.length;
    final step = steps[idx];
    if (step.type == CycleStepType.workout && step.workoutId != null) {
      final result = await workoutRepo.getById(step.workoutId!);
      return result.getOrThrow();
    }
  }
  return null;
}

/// Index of the next step in the cycle (for UI highlighting). Null if no cycle or empty.
/// Uses [effectiveCycleStepsProvider] so archived workouts are ignored.
@riverpod
Future<int?> nextCycleStepIndex(Ref ref) async {
  final stepsAsync = ref.watch(effectiveCycleStepsProvider);
  final lastIdAsync = ref.watch(lastFinishedWorkoutIdProvider);

  final steps = stepsAsync.value;
  if (steps == null || steps.isEmpty) return null;

  final lastWorkoutId = lastIdAsync.value;
  if (lastWorkoutId == null) return 0;

  var lastStepIndex = -1;
  for (var i = 0; i < steps.length; i++) {
    if (steps[i].type == CycleStepType.workout &&
        steps[i].workoutId == lastWorkoutId) {
      lastStepIndex = i;
      break;
    }
  }
  return lastStepIndex < 0 ? 0 : (lastStepIndex + 1) % steps.length;
}

/// Number of consecutive finished executions (newest to oldest) that follow
/// the cycle order. Rest days do not break the streak.
/// Uses [effectiveCycleStepsProvider] when non-empty; otherwise active workouts by sortOrder.
@riverpod
Future<int> executionStreak(Ref ref) async {
  final execRepo = ref.watch(workoutExecutionRepositoryProvider);
  final stepsAsync = ref.watch(effectiveCycleStepsProvider);
  final workoutsAsync = ref.watch(workoutListProvider);

  final allResult = await execRepo.getAll();
  final executions = allResult.getOrThrow();
  if (executions.isEmpty) return 0;

  final steps = stepsAsync.value;
  List<int> cycleWorkoutIds;
  Map<int, int> cycleIndexById;

  if (steps != null && steps.isNotEmpty) {
    cycleWorkoutIds = [
      for (final s in steps)
        if (s.type == CycleStepType.workout && s.workoutId != null) s.workoutId!,
    ];
    cycleIndexById = {
      for (var i = 0; i < cycleWorkoutIds.length; i++) cycleWorkoutIds[i]: i,
    };
  } else {
    final workouts = workoutsAsync.value;
    if (workouts == null || workouts.isEmpty) return 0;
    final ordered = workouts
        .where((w) => w.sortOrder != null)
        .toList()
      ..sort((a, b) => a.sortOrder!.compareTo(b.sortOrder!));
    if (ordered.isEmpty) return 0;
    cycleWorkoutIds = ordered.map((w) => w.id).toList();
    cycleIndexById = {
      for (var i = 0; i < cycleWorkoutIds.length; i++) cycleWorkoutIds[i]: i,
    };
  }

  if (cycleWorkoutIds.isEmpty) return 0;

  int previousWorkoutInCycle(int workoutId) {
    final idx = cycleIndexById[workoutId];
    if (idx == null) return -1;
    return cycleWorkoutIds[(idx - 1 + cycleWorkoutIds.length) % cycleWorkoutIds.length];
  }

  var streak = 1;
  for (var i = 1; i < executions.length; i++) {
    final expected = previousWorkoutInCycle(executions[i - 1].workoutId);
    if (expected < 0 || executions[i].workoutId != expected) break;
    streak++;
  }
  return streak;
}
