import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/athlos_radius.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workout_exercise.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/active_execution_notifier.dart';
import '../providers/exercise_notifier.dart';
import '../providers/rest_timer_notifier.dart';
import '../providers/workout_notifier.dart';

enum _ViewMode { overview, focused, timer }

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  final int workoutId;

  const WorkoutExecutionScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState
    extends ConsumerState<WorkoutExecutionScreen> {
  bool _initialized = false;
  _ViewMode _viewMode = _ViewMode.overview;

  int _focusedExerciseIndex = 0;
  int _focusedSetNumber = 1;
  double _currentWeight = 0;
  int _currentReps = 0;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync =
        ref.watch(workoutExercisesProvider(widget.workoutId));
    final execState = ref.watch(activeExecutionProvider);
    final timerState = ref.watch(restTimerProvider);
    ref.watch(exerciseListProvider);

    if (!_initialized &&
        exercisesAsync is AsyncData<List<WorkoutExercise>> &&
        execState == null) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(activeExecutionProvider.notifier)
            .startExecution(widget.workoutId, exercisesAsync.value);
      });
    }

    // No auto-transition — the timer view shows a "rest complete" state
    // with explicit buttons for the user to proceed.

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_viewMode == _ViewMode.focused) {
          setState(() => _viewMode = _ViewMode.overview);
        } else {
          _showCancelDialog(context);
        }
      },
      child: execState == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : switch (_viewMode) {
              _ViewMode.overview => _buildOverview(context, execState),
              _ViewMode.focused => _buildFocused(context, execState),
              _ViewMode.timer =>
                _buildTimer(context, execState, timerState),
            },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _exerciseName(int exerciseId) {
    final l10n = AppLocalizations.of(context)!;
    final allExercises = ref.read(exerciseListProvider).value;
    final entity = allExercises?.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => throw StateError('Exercise $exerciseId not found'),
    );
    if (entity == null) return '#$exerciseId';
    return localizedExerciseName(
      entity.name,
      isVerified: entity.isVerified,
      l10n: l10n,
    );
  }

  String _muscleGroupName(int exerciseId) {
    final l10n = AppLocalizations.of(context)!;
    final allExercises = ref.read(exerciseListProvider).value;
    final entity = allExercises?.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => throw StateError('Exercise $exerciseId not found'),
    );
    if (entity == null) return '';
    return localizedMuscleGroupName(entity.muscleGroup, l10n);
  }

  int get _totalSetCount {
    final exec = ref.read(activeExecutionProvider);
    if (exec == null) return 0;
    return exec.exerciseSets.values.expand((s) => s).length;
  }

  /// Returns the next incomplete (exerciseIndex, setNumber), or null if all done.
  (int exerciseIndex, int setNumber)? _findNextPendingSet(
      ActiveExecutionState exec) {
    for (var i = 0; i < exec.exercises.length; i++) {
      final exId = exec.exercises[i].exerciseId;
      final sets = exec.exerciseSets[exId] ?? [];
      for (final s in sets) {
        if (!s.isCompleted) return (i, s.setNumber);
      }
    }
    return null;
  }

  void _goToFocused(ActiveExecutionState exec, int exerciseIndex,
      [int? setNumber]) {
    final exId = exec.exercises[exerciseIndex].exerciseId;
    final sets = exec.exerciseSets[exId] ?? [];

    final targetSet = setNumber ??
        sets
            .where((s) => !s.isCompleted)
            .map((s) => s.setNumber)
            .firstOrNull ??
        1;

    final entry = sets.firstWhere(
      (s) => s.setNumber == targetSet,
      orElse: () => sets.first,
    );

    // Pre-fill with previous completed set's weight if available
    final prevCompleted = sets
        .where((s) => s.isCompleted && s.setNumber < targetSet)
        .toList();

    setState(() {
      _viewMode = _ViewMode.focused;
      _focusedExerciseIndex = exerciseIndex;
      _focusedSetNumber = targetSet;
      _currentWeight = entry.weight ??
          (prevCompleted.isNotEmpty ? prevCompleted.last.weight ?? 0 : 0);
      _currentReps = entry.reps;
    });
  }

  void _goToNextSetFromTimer(ActiveExecutionState exec) {
    ref.read(restTimerProvider.notifier).reset();
    final exId = exec.exercises[_focusedExerciseIndex].exerciseId;
    final sets = exec.exerciseSets[exId] ?? [];
    final nextInExercise = sets
        .where((s) => !s.isCompleted && s.setNumber > _focusedSetNumber)
        .toList();

    if (nextInExercise.isNotEmpty) {
      _goToFocused(
          exec, _focusedExerciseIndex, nextInExercise.first.setNumber);
    } else {
      final globalNext = _findNextPendingSet(exec);
      if (globalNext != null) {
        _goToFocused(exec, globalNext.$1, globalNext.$2);
      } else {
        setState(() => _viewMode = _ViewMode.overview);
      }
    }
  }

  void _returnToOverviewFromTimer() {
    ref.read(restTimerProvider.notifier).reset();
    setState(() => _viewMode = _ViewMode.overview);
  }

  // ---------------------------------------------------------------------------
  // View 1: Overview
  // ---------------------------------------------------------------------------

  Widget _buildOverview(BuildContext context, ActiveExecutionState exec) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final workoutAsync = ref.watch(workoutByIdProvider(widget.workoutId));
    final workoutName = workoutAsync.value?.name ?? '';
    final completed = exec.completedSetCount;
    final total = _totalSetCount;
    final next = _findNextPendingSet(exec);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.executionTitle(workoutName)),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _showCancelDialog(context),
            child: Text(
              l10n.cancelExecution,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AthlosSpacing.md,
              vertical: AthlosSpacing.sm,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.overallProgress(completed, total),
                      style: textTheme.labelLarge,
                    ),
                    if (completed == total && total > 0)
                      Icon(Icons.check_circle,
                          color: colorScheme.primary, size: 20),
                  ],
                ),
                const SizedBox(height: AthlosSpacing.xs),
                LinearProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  borderRadius: AthlosRadius.fullAll,
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AthlosSpacing.sm,
              ),
              itemCount: exec.exercises.length,
              itemBuilder: (context, index) {
                final exercise = exec.exercises[index];
                final sets =
                    exec.exerciseSets[exercise.exerciseId] ?? [];
                final completedSets =
                    sets.where((s) => s.isCompleted).length;
                final totalSets = sets.length;
                final isAllDone = completedSets == totalSets;
                final isActive = next != null && next.$1 == index;

                return _OverviewExerciseCard(
                  exerciseName: _exerciseName(exercise.exerciseId),
                  muscleGroup: _muscleGroupName(exercise.exerciseId),
                  completedSets: completedSets,
                  totalSets: totalSets,
                  isAllDone: isAllDone,
                  isActive: isActive,
                  onTap: () => _goToFocused(exec, index),
                );
              },
            ),
          ),

          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (next != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            _goToFocused(exec, next.$1, next.$2),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.nextSetButton(
                          _exerciseName(
                              exec.exercises[next.$1].exerciseId),
                          next.$2,
                        )),
                      ),
                    ),
                    const SizedBox(height: AthlosSpacing.sm),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: exec.hasCompletedSets &&
                              !exec.isFinishing
                          ? () => _onFinish(context)
                          : null,
                      icon: exec.isFinishing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(l10n.finishWorkout),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 2: Focused
  // ---------------------------------------------------------------------------

  Widget _buildFocused(BuildContext context, ActiveExecutionState exec) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final exercise = exec.exercises[_focusedExerciseIndex];
    final sets = exec.exerciseSets[exercise.exerciseId] ?? [];
    final totalSets = sets.length;
    final name = _exerciseName(exercise.exerciseId);
    final group = _muscleGroupName(exercise.exerciseId);

    // Find previous completed set for reference
    final prevCompleted = sets
        .where(
            (s) => s.isCompleted && s.setNumber < _focusedSetNumber)
        .toList();
    final prevSet = prevCompleted.isNotEmpty ? prevCompleted.last : null;

    final currentSetEntry = sets.firstWhere(
      (s) => s.setNumber == _focusedSetNumber,
      orElse: () => sets.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _viewMode = _ViewMode.overview),
        ),
        title: Text(name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AthlosSpacing.sm),
            child: Text(
              l10n.setOf(_focusedSetNumber, totalSets),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AthlosSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AthlosSpacing.lg),
            if (group.isNotEmpty)
              Text(
                group,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const Spacer(),

            // Weight input
            _NumberInput(
              value: _currentWeight,
              suffix: l10n.weightKgSuffix,
              step: 2.5,
              onChanged: (v) => setState(() => _currentWeight = v),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: AthlosSpacing.xl),

            // Reps input
            _NumberInput(
              value: _currentReps.toDouble(),
              suffix: l10n.repsShort,
              step: 1,
              onChanged: (v) => setState(() => _currentReps = v.toInt()),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),

            const Spacer(),

            // Previous set reference
            if (prevSet != null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AthlosSpacing.md),
                child: Text(
                  l10n.previousSetRef(
                    prevSet.weight?.toStringAsFixed(
                            prevSet.weight! % 1 == 0 ? 0 : 1) ??
                        '0',
                    prevSet.reps,
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Complete button
            if (!currentSetEntry.isCompleted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _onCompleteSet(exec),
                  icon: const Icon(Icons.check),
                  label: Text(
                    l10n.completeSetButton,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    // Move to next set or back to overview
                    final nextInExercise = sets
                        .where((s) =>
                            !s.isCompleted &&
                            s.setNumber > _focusedSetNumber)
                        .toList();
                    if (nextInExercise.isNotEmpty) {
                      _goToFocused(exec, _focusedExerciseIndex,
                          nextInExercise.first.setNumber);
                    } else {
                      setState(() => _viewMode = _ViewMode.overview);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l10n.next),
                ),
              ),

            const SizedBox(height: AthlosSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 3: Timer
  // ---------------------------------------------------------------------------

  Widget _buildTimer(
    BuildContext context,
    ActiveExecutionState exec,
    RestTimerState timerState,
  ) {
    final isFinished =
        timerState.totalSeconds > 0 && timerState.remainingSeconds == 0;

    if (isFinished) {
      return _buildTimerDone(context, exec);
    }
    return _buildTimerCounting(context, exec, timerState);
  }

  Widget _buildTimerCounting(
    BuildContext context,
    ActiveExecutionState exec,
    RestTimerState timerState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final next = _findNextPendingSet(exec);
    final nextLabel = next != null
        ? l10n.nextUpLabel(
            _exerciseName(exec.exercises[next.$1].exerciseId),
            next.$2,
          )
        : l10n.allSetsComplete;

    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            Text(
              timeText,
              style: textTheme.displayLarge?.copyWith(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: AthlosSpacing.lg),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AthlosSpacing.xxl),
              child: LinearProgressIndicator(
                value: timerState.progress,
                borderRadius: AthlosRadius.fullAll,
                minHeight: 6,
              ),
            ),

            const SizedBox(height: AthlosSpacing.xl),

            Icon(
              Icons.timer_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 28,
            ),

            const SizedBox(height: AthlosSpacing.sm),

            Text(
              nextLabel,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(flex: 3),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AthlosSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      ref.read(restTimerProvider.notifier).addTime(15);
                    },
                    child: Text(l10n.addTimeButton),
                  ),
                  const SizedBox(width: AthlosSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      ref.read(restTimerProvider.notifier).skip();
                    },
                    child: Text(l10n.skipTimer),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AthlosSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDone(BuildContext context, ActiveExecutionState exec) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final exId = exec.exercises[_focusedExerciseIndex].exerciseId;
    final sets = exec.exerciseSets[exId] ?? [];
    final hasMoreSetsInExercise =
        sets.any((s) => !s.isCompleted && s.setNumber > _focusedSetNumber);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: colorScheme.primary,
            ),

            const SizedBox(height: AthlosSpacing.lg),

            Text(
              l10n.restComplete,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (!hasMoreSetsInExercise) ...[
              const SizedBox(height: AthlosSpacing.md),
              Text(
                l10n.exerciseCompleteMessage,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const Spacer(flex: 3),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AthlosSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: hasMoreSetsInExercise
                    ? FilledButton.icon(
                        onPressed: () => _goToNextSetFromTimer(exec),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(l10n.nextSetLabel),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _returnToOverviewFromTimer(),
                        icon: const Icon(Icons.list_alt),
                        label: Text(l10n.backToOverview),
                      ),
              ),
            ),

            const SizedBox(height: AthlosSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _onCompleteSet(ActiveExecutionState exec) async {
    final exercise = exec.exercises[_focusedExerciseIndex];

    if (_currentReps <= 0) return;

    final restSeconds = await ref
        .read(activeExecutionProvider.notifier)
        .completeSet(
          exercise.exerciseId,
          _focusedSetNumber,
          reps: _currentReps,
          weight: _currentWeight > 0 ? _currentWeight : null,
        );

    if (!mounted) return;

    if (restSeconds > 0) {
      ref.read(restTimerProvider.notifier).start(restSeconds);
      setState(() => _viewMode = _ViewMode.timer);
    } else {
      // No rest configured — go to next set directly
      final updatedExec = ref.read(activeExecutionProvider);
      if (updatedExec == null) return;
      final next = _findNextPendingSet(updatedExec);
      if (next != null) {
        _goToFocused(updatedExec, next.$1, next.$2);
      } else {
        setState(() => _viewMode = _ViewMode.overview);
      }
    }
  }

  Future<void> _onFinish(BuildContext context) async {
    await ref.read(activeExecutionProvider.notifier).finishExecution();
    ref.read(restTimerProvider.notifier).reset();
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workoutFinished)),
      );
      context.pop();
    }
  }

  void _showCancelDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelExecution),
        content: Text(l10n.cancelExecutionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.back),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(activeExecutionProvider.notifier)
                  .cancelExecution();
              ref.read(restTimerProvider.notifier).reset();
              if (context.mounted) context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.cancelExecution),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Overview Exercise Card
// =============================================================================

class _OverviewExerciseCard extends StatelessWidget {
  final String exerciseName;
  final String muscleGroup;
  final int completedSets;
  final int totalSets;
  final bool isAllDone;
  final bool isActive;
  final VoidCallback onTap;

  const _OverviewExerciseCard({
    required this.exerciseName,
    required this.muscleGroup,
    required this.completedSets,
    required this.totalSets,
    required this.isAllDone,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final IconData statusIcon;
    final Color statusColor;
    if (isAllDone) {
      statusIcon = Icons.check_circle;
      statusColor = colorScheme.primary;
    } else if (isActive) {
      statusIcon = Icons.play_circle_filled;
      statusColor = colorScheme.tertiary;
    } else {
      statusIcon = Icons.radio_button_unchecked;
      statusColor = colorScheme.onSurfaceVariant;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AthlosSpacing.xs),
      shape: isActive
          ? RoundedRectangleBorder(
              borderRadius: AthlosRadius.mdAll,
              side: BorderSide(color: colorScheme.tertiary, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AthlosRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AthlosSpacing.md,
            vertical: AthlosSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: AthlosSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: textTheme.titleSmall?.copyWith(
                        decoration: isAllDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: isAllDone
                            ? colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    if (muscleGroup.isNotEmpty)
                      Text(
                        muscleGroup,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AthlosSpacing.sm,
                  vertical: AthlosSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: AthlosRadius.fullAll,
                ),
                child: Text(
                  l10n.exerciseProgress(completedSets, totalSets),
                  style: textTheme.labelSmall?.copyWith(
                    color: isAllDone
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AthlosSpacing.xs),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Number Input with +/- buttons
// =============================================================================

class _NumberInput extends StatelessWidget {
  final double value;
  final String suffix;
  final double step;
  final ValueChanged<double> onChanged;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _NumberInput({
    required this.value,
    required this.suffix,
    required this.step,
    required this.onChanged,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
        value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.remove,
          onPressed: value > 0
              ? () => onChanged((value - step).clamp(0, 9999))
              : null,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: AthlosSpacing.lg),
        GestureDetector(
          onTap: () => _showEditDialog(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayValue,
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                suffix,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AthlosSpacing.lg),
        _CircleButton(
          icon: Icons.add,
          onPressed: () => onChanged(value + step),
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(1),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(suffix),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: suffix,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            final parsed = double.tryParse(v);
            Navigator.pop(ctx, parsed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              Navigator.pop(ctx, parsed);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result != null) onChanged(result.clamp(0, 9999));
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _CircleButton({
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: onPressed != null
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainerHighest.withAlpha(100),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AthlosSpacing.md),
          child: Icon(
            icon,
            color: onPressed != null
                ? colorScheme.onSurface
                : colorScheme.onSurface.withAlpha(80),
            size: 28,
          ),
        ),
      ),
    );
  }
}
