import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_radius.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/cycle_step.dart';
import '../../domain/entities/progression_rule.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/workout.dart';
import '../../domain/enums/deload_strategy.dart';
import '../../domain/enums/program_focus.dart';
import '../../domain/enums/progression_type.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/exercise_notifier.dart';
import '../providers/program_notifier.dart';
import '../providers/training_analytics_provider.dart';
import '../providers/workout_notifier.dart';

/// Unified view of a training program: header, cycle, progression, deload.
class ProgramDetailScreen extends ConsumerWidget {
  final int programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final programsAsync = ref.watch(programListProvider);
    final program = programsAsync.value
        ?.where((p) => p.id == programId)
        .firstOrNull;

    if (program == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.trainingModule)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.trainingEditProgram,
            onPressed: () =>
                context.push(RoutePaths.trainingProgramEdit(programId)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AthlosSpacing.md),
        children: [
          _ProgramHeader(program: program),
          const Gap(AthlosSpacing.lg),
          _CycleSection(programId: programId),
          const Gap(AthlosSpacing.lg),
          _ProgressionSection(programId: programId),
          const Gap(AthlosSpacing.lg),
          _DeloadSection(program: program),
          const Gap(AthlosSpacing.lg),
          _ActionsSection(program: program),
          const Gap(AthlosSpacing.fabClearance),
        ],
      ),
    );
  }
}

// ── Program Header ───────────────────────────────────────────────────

class _ProgramHeader extends ConsumerWidget {
  final TrainingProgram program;

  const _ProgramHeader({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final focusLabel = switch (program.focus) {
      ProgramFocus.hypertrophy => l10n.programFocusHypertrophy,
      ProgramFocus.strength => l10n.programFocusStrength,
      ProgramFocus.endurance => l10n.programFocusEndurance,
      ProgramFocus.custom => l10n.programFocusCustom,
    };

    final progressAsync = ref.watch(programProgressProvider(program.id));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AthlosRadius.mdAll,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AthlosSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: colorScheme.primary, size: 20),
                const Gap(AthlosSpacing.sm),
                Expanded(
                  child: Text(program.name, style: textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AthlosSpacing.sm,
                    vertical: AthlosSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: AthlosRadius.smAll,
                  ),
                  child: Text(
                    focusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (program.isInDeload) ...[
              const Gap(AthlosSpacing.sm),
              Chip(
                avatar:
                    Icon(Icons.spa, size: 16, color: colorScheme.tertiary),
                label: Text(l10n.deloadActiveChip),
                backgroundColor: colorScheme.tertiaryContainer,
                labelStyle: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
            const Gap(AthlosSpacing.md),
            progressAsync.when(
              data: (progress) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.programProgressLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        l10n.programSessionsProgress(
                          progress.completedSessions,
                          progress.totalSessions,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Gap(AthlosSpacing.xs),
                  ClipRRect(
                    borderRadius: AthlosRadius.smAll,
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cycle Section ────────────────────────────────────────────────────

class _CycleSection extends ConsumerStatefulWidget {
  final int programId;

  const _CycleSection({required this.programId});

  @override
  ConsumerState<_CycleSection> createState() => _CycleSectionState();
}

class _CycleSectionState extends ConsumerState<_CycleSection> {
  List<int>? _workoutIds;

  void _syncFromSteps(List<TrainingCycleStep> steps) {
    if (_workoutIds == null) {
      _workoutIds = steps.map((s) => s.workoutId).toList();
    }
  }

  Future<void> _saveOrder() async {
    if (_workoutIds == null) return;
    final repo = ref.read(cycleRepositoryProvider);
    final steps = [
      for (var i = 0; i < _workoutIds!.length; i++)
        TrainingCycleStep(id: 0, orderIndex: i, workoutId: _workoutIds![i]),
    ];
    final result = await repo.setSteps(steps, widget.programId);
    result.getOrThrow();
    ref.invalidate(cycleStepsProvider);
    ref.invalidate(cycleStepsForProgramProvider(widget.programId));
  }

  void _addWorkout(int workoutId) {
    setState(() {
      _workoutIds = [...?_workoutIds, workoutId];
    });
    _saveOrder();
  }

  void _removeAt(int index) {
    setState(() {
      _workoutIds = [...?_workoutIds]..removeAt(index);
    });
    _saveOrder();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final ids = [...?_workoutIds];
      final item = ids.removeAt(oldIndex);
      ids.insert(newIndex, item);
      _workoutIds = ids;
    });
    _saveOrder();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final stepsAsync =
        ref.watch(cycleStepsForProgramProvider(widget.programId));
    final workoutsAsync = ref.watch(workoutListProvider);
    final workouts = workoutsAsync.value ?? [];

    stepsAsync.whenData(_syncFromSteps);

    final ids = _workoutIds ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.programCycleSection,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(AthlosSpacing.xs),
        if (ids.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AthlosSpacing.sm),
            child: Text(
              l10n.programCycleHint,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ids.length,
          onReorder: _reorder,
          itemBuilder: (context, index) {
            final workoutId = ids[index];
            final label = workouts
                    .where((w) => w.id == workoutId)
                    .map((w) => w.name)
                    .firstOrNull ??
                'Treino #$workoutId';
            return Card(
              key: ValueKey('cycle-$index-$workoutId'),
              margin: const EdgeInsets.only(bottom: AthlosSpacing.xs),
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(label),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeAt(index),
                ),
              ),
            );
          },
        ),
        const Gap(AthlosSpacing.sm),
        OutlinedButton.icon(
          onPressed: workouts.isEmpty
              ? null
              : () => _showAddWorkoutPicker(context, workouts),
          icon: const Icon(Icons.add),
          label: Text(l10n.trainingCycleAddWorkout),
        ),
      ],
    );
  }

  void _showAddWorkoutPicker(BuildContext context, List<Workout> workouts) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Text(
                l10n.trainingCycleAddWorkout,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...workouts.map((w) => ListTile(
                  title: Text(w.name),
                  onTap: () {
                    _addWorkout(w.id);
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ── Progression Section ──────────────────────────────────────────────

class _ProgressionSection extends ConsumerStatefulWidget {
  final int programId;

  const _ProgressionSection({required this.programId});

  @override
  ConsumerState<_ProgressionSection> createState() =>
      _ProgressionSectionState();
}

class _ProgressionSectionState extends ConsumerState<_ProgressionSection> {
  List<ProgressionRule>? _rules;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final repo = ref.read(progressionRuleRepositoryProvider);
    final result = await repo.getByProgram(widget.programId);
    if (mounted && result.isSuccess) {
      setState(() => _rules = result.getOrThrow());
    }
  }

  Future<void> _removeRuleAt(int index) async {
    final rules = [...?_rules];
    rules.removeAt(index);
    setState(() => _rules = rules);
    final repo = ref.read(progressionRuleRepositoryProvider);
    await repo.replaceAllForProgram(widget.programId, rules);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final exercises = ref.watch(exerciseListProvider).value ?? [];

    final rules = _rules ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.progressionSectionTitle,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(AthlosSpacing.xs),
        if (rules.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AthlosSpacing.sm),
            child: Text(
              l10n.progressionEmptyHint,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ...rules.asMap().entries.map((entry) {
          final idx = entry.key;
          final rule = entry.value;
          final exerciseName = exercises
                  .where((e) => e.id == rule.exerciseId)
                  .map((e) => localizedExerciseName(
                        e.name,
                        isVerified: e.isVerified,
                        l10n: l10n,
                      ))
                  .firstOrNull ??
              '#${rule.exerciseId}';
          final typeLabel = switch (rule.type) {
            ProgressionType.incrementWeight =>
              l10n.progressionTypeIncrementWeight,
            ProgressionType.incrementReps =>
              l10n.progressionTypeIncrementReps,
            ProgressionType.incrementSets =>
              l10n.progressionTypeIncrementSets,
          };
          final unit = switch (rule.type) {
            ProgressionType.incrementWeight => 'kg',
            ProgressionType.incrementReps => 'reps',
            ProgressionType.incrementSets => 'sets',
          };
          return Card(
            key: ValueKey('prog-$idx-${rule.exerciseId}'),
            margin: const EdgeInsets.only(bottom: AthlosSpacing.xs),
            child: ListTile(
              title: Text(exerciseName),
              subtitle: Text(
                '$typeLabel: +${rule.value % 1 == 0 ? rule.value.toInt() : rule.value} $unit',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeRuleAt(idx),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Deload Section ───────────────────────────────────────────────────

class _DeloadSection extends StatelessWidget {
  final TrainingProgram program;

  const _DeloadSection({required this.program});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final config = program.deloadConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.deloadSectionTitle,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(AthlosSpacing.xs),
        if (config == null)
          Text(
            l10n.deloadEnableLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (config.strategy) {
                      DeloadStrategy.reduceVolume =>
                        l10n.deloadStrategyReduceVolume,
                      DeloadStrategy.reduceIntensity =>
                        l10n.deloadStrategyReduceIntensity,
                      DeloadStrategy.reduceBoth =>
                        l10n.deloadStrategyReduceBoth,
                    },
                    style: textTheme.bodyMedium,
                  ),
                  if (config.frequency != null)
                    Text(
                      '${l10n.deloadFrequencyLabel}: ${config.frequency}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Actions Section ──────────────────────────────────────────────────

class _ActionsSection extends ConsumerWidget {
  final TrainingProgram program;

  const _ActionsSection({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (program.isInDeload)
          OutlinedButton.icon(
            onPressed: () => _confirmEndDeload(context, ref),
            icon: const Icon(Icons.spa_outlined),
            label: Text(l10n.deloadEndAction),
          ),
        if (!program.isInDeload && program.deloadConfig != null)
          OutlinedButton.icon(
            onPressed: () => ref
                .read(programActionsProvider.notifier)
                .enterDeload(program.id),
            icon: const Icon(Icons.spa),
            label: Text(l10n.deloadAccept),
          ),
        const Gap(AthlosSpacing.sm),
        if (program.isActive && !program.isInDeload)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            onPressed: () => _confirmArchive(context, ref),
            icon: const Icon(Icons.archive_outlined),
            label: Text(l10n.archiveProgramAction),
          ),
        const Gap(AthlosSpacing.sm),
        TextButton(
          onPressed: () => context.go(RoutePaths.trainingPrograms),
          child: Text(l10n.trainingViewArchivedPrograms),
        ),
      ],
    );
  }

  void _confirmEndDeload(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deloadEndConfirmTitle),
        content: Text(l10n.deloadEndConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(programActionsProvider.notifier)
                  .exitDeload(program.id);
            },
            child: Text(l10n.deloadEndAction),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.programCompletedTitle),
        content: Text(l10n.programCompletedMessage(program.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(programActionsProvider.notifier)
                  .archiveProgram(program.id);
              context.go(RoutePaths.trainingHome);
            },
            child: Text(l10n.programCompletedArchive),
          ),
        ],
      ),
    );
  }
}
