import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/result.dart';
import '../../../profile/data/repositories/profile_providers.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/helpers/training_metrics.dart';
import 'exercise_notifier.dart';

part 'training_metrics_provider.g.dart';

/// Personal record for an exercise: best estimated 1RM ever achieved.
class ExercisePR {
  final int exerciseId;

  /// Best estimated 1RM across all completed sets.
  final double best1RM;

  /// Weight and reps of the set that produced the best 1RM.
  final double weight;
  final int reps;

  const ExercisePR({
    required this.exerciseId,
    required this.best1RM,
    required this.weight,
    required this.reps,
  });
}

/// Returns the personal record (best estimated 1RM) for [exerciseId],
/// accounting for bodyweight exercises using profile weight.
@riverpod
Future<ExercisePR?> exercisePR(Ref ref, int exerciseId) async {
  final execRepo = ref.watch(workoutExecutionRepositoryProvider);
  final exercises = await ref.watch(exerciseListProvider.future);
  final exercise =
      exercises.where((e) => e.id == exerciseId).firstOrNull;
  if (exercise == null) return null;

  final profileRepo = ref.watch(userProfileRepositoryProvider);
  final profileResult = await profileRepo.get();
  final profileWeight = profileResult.isSuccess
      ? profileResult.getOrThrow()?.weight?.toDouble()
      : null;

  final setsResult =
      await execRepo.getAllCompletedSetsForExercise(exerciseId);
  if (!setsResult.isSuccess) return null;
  final sets = setsResult.getOrThrow();
  if (sets.isEmpty) return null;

  ExercisePR? best;
  for (final s in sets) {
    final load = effectiveLoad(
      isBodyweight: exercise.isBodyweight,
      setWeight: s.weight,
      profileWeight: profileWeight,
    );
    final e1rm = estimated1RM(weight: load, reps: s.reps);
    if (e1rm != null && (best == null || e1rm > best.best1RM)) {
      best = ExercisePR(
        exerciseId: exerciseId,
        best1RM: e1rm,
        weight: load ?? 0,
        reps: s.reps ?? 1,
      );
    }
  }
  return best;
}

/// Checks whether a specific execution set represents a new PR for
/// the given exercise. Compares the set's estimated 1RM against the
/// existing PR (excluding the current execution).
@riverpod
Future<bool> isSetNewPR(
  Ref ref, {
  required int exerciseId,
  required double? weight,
  required int? reps,
  required bool isBodyweight,
}) async {
  final profileRepo = ref.watch(userProfileRepositoryProvider);
  final profileResult = await profileRepo.get();
  final profileWeight = profileResult.isSuccess
      ? profileResult.getOrThrow()?.weight?.toDouble()
      : null;

  final load = effectiveLoad(
    isBodyweight: isBodyweight,
    setWeight: weight,
    profileWeight: profileWeight,
  );
  final setE1rm = estimated1RM(weight: load, reps: reps);
  if (setE1rm == null) return false;

  final pr = await ref.watch(exercisePRProvider(exerciseId).future);
  if (pr == null) return true;
  return setE1rm > pr.best1RM;
}

/// Weekly volume per muscle group: total working (non-warmup) sets
/// per [MuscleGroup] in the last 7 days.
@riverpod
Future<Map<String, int>> weeklyVolumePerMuscleGroup(Ref ref) async {
  final execRepo = ref.watch(workoutExecutionRepositoryProvider);
  final exercises = await ref.watch(exerciseListProvider.future);
  final exerciseMap = {for (final e in exercises) e.id: e};

  final allExecsResult = await execRepo.getAll();
  if (!allExecsResult.isSuccess) return {};
  final allExecs = allExecsResult.getOrThrow();

  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final recentExecs = allExecs
      .where((e) => e.finishedAt != null && e.startedAt.isAfter(cutoff))
      .toList();

  final volume = <String, int>{};
  for (final exec in recentExecs) {
    final setsResult = await execRepo.getSets(exec.id);
    if (!setsResult.isSuccess) continue;
    final sets = setsResult.getOrThrow();
    for (final s in sets) {
      if (!s.isCompleted || s.isWarmup) continue;
      final exercise = exerciseMap[s.exerciseId];
      if (exercise == null) continue;
      final key = exercise.muscleGroup.name;
      volume[key] = (volume[key] ?? 0) + 1;
    }
  }
  return volume;
}

/// Volume recommendation ranges based on experience level.
/// Returns (min, max) sets per muscle group per week.
({int min, int max}) volumeTargetForLevel(String? experienceLevel) =>
    switch (experienceLevel) {
      'beginner' => (min: 10, max: 14),
      'intermediate' => (min: 14, max: 20),
      'advanced' || 'expert' => (min: 20, max: 30),
      _ => (min: 10, max: 20),
    };
