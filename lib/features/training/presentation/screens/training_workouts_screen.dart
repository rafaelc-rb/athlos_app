import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../chiron/presentation/widgets/chiron_bottom_sheet.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_radius.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/cycle_step.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/workout.dart';
import '../../domain/enums/program_focus.dart';
import '../providers/program_notifier.dart';
import '../providers/training_analytics_provider.dart';
import '../providers/workout_notifier.dart';

final _placeholderWorkouts = List.generate(
  6,
  (i) => Workout(
    id: -(i + 1),
    name: BoneMock.name,
    createdAt: DateTime(2024),
  ),
);

/// Training module — Treino tab.
///
/// Combines program management and workout cycle in a single view.
/// When a program is active, it shows as a hero card on top with the
/// workout cycle below. In free mode, shows just the cycle with a
/// non-intrusive CTA to create a program.
class TrainingWorkoutsScreen extends ConsumerWidget {
  const TrainingWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workoutsAsync = ref.watch(workoutListProvider);
    final workoutCount = workoutsAsync.value?.length ?? 0;

    return Scaffold(
      body: const _TrainingTabBody(),
      floatingActionButton: _ExpandableWorkoutFab(
        chironLabel: workoutCount == 0
            ? l10n.chironCreateWorkoutShortcut
            : l10n.chironAnalyzeWorkoutsShortcut,
        createManualLabel: l10n.trainingWorkoutActionCreateManual,
        onChiron: () => showChironSheet(
          context,
          initialMessage: workoutCount == 0
              ? l10n.chironAskToCreateWorkout
              : l10n.chironAnalyzeWorkoutsMessage,
        ),
        onCreateManual: () => context.push(RoutePaths.trainingWorkoutNew),
      ),
    );
  }
}

// ── Main body: hero program card + cycle list ────────────────────────

class _TrainingTabBody extends ConsumerWidget {
  const _TrainingTabBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.watch(ensureCycleSyncProvider);
    final workoutsAsync = ref.watch(workoutListProvider);
    final cycleListAsync = ref.watch(cycleListItemsProvider);
    final nextWorkoutToStartAsync = ref.watch(nextWorkoutToStartProvider);
    final nextStepIndexAsync = ref.watch(nextCycleStepIndexProvider);
    final archivedAsync = ref.watch(archivedWorkoutListProvider);
    final activeProgramAsync = ref.watch(activeProgramProvider);

    final nextWorkout = nextWorkoutToStartAsync.value;
    final nextStepIndex = nextStepIndexAsync.value;

    if (workoutsAsync.hasError) {
      return Center(child: Text(l10n.genericError));
    }

    final isLoading = workoutsAsync.isLoading;
    final workouts = workoutsAsync.value ?? [];
    if (!isLoading &&
        workouts.isEmpty &&
        (archivedAsync.value == null || archivedAsync.value!.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AthlosSpacing.md),
            Text(
              l10n.emptyWorkouts,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AthlosSpacing.sm),
            Text(
              l10n.emptyWorkoutsHint,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Skeletonizer(
      enabled: isLoading || cycleListAsync.isLoading,
      child: cycleListAsync.when(
        data: (data) => _CycleListBody(
          items: data.items,
          isFromCycle: data.isFromCycle,
          nextStepIndex: nextStepIndex,
          nextWorkoutId: nextWorkout?.id,
          archivedAsync: archivedAsync,
          activeProgramAsync: activeProgramAsync,
        ),
        loading: () => _CycleListBody(
          items: (workouts.isEmpty ? _placeholderWorkouts : workouts)
              .map((w) => CycleListWorkoutItem(stepIndex: 0, workout: w))
              .toList(),
          isFromCycle: false,
          nextStepIndex: null,
          nextWorkoutId: null,
          archivedAsync: archivedAsync,
          activeProgramAsync: activeProgramAsync,
        ),
        error: (_, _) => Center(child: Text(l10n.genericError)),
      ),
    );
  }
}

// ── Active Program Hero Card ─────────────────────────────────────────

class _ActiveProgramHeroCard extends ConsumerWidget {
  final TrainingProgram program;

  const _ActiveProgramHeroCard({required this.program});

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

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AthlosRadius.mdAll,
        side: BorderSide(color: colorScheme.primary, width: 1),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AthlosSpacing.md,
        vertical: AthlosSpacing.sm,
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
                  child: Text(
                    program.name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              const Gap(AthlosSpacing.xs),
              Row(
                children: [
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
                  const Gap(AthlosSpacing.sm),
                  TextButton(
                    onPressed: () =>
                        _confirmEndDeload(context, ref, program.id),
                    child: Text(l10n.deloadEndAction),
                  ),
                ],
              ),
            ],
            const Gap(AthlosSpacing.sm),
            _ProgramProgress(programId: program.id),
            const Gap(AthlosSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AthlosSpacing.sm,
              children: [
                TextButton.icon(
                  onPressed: () => context.go(
                    RoutePaths.trainingProgramEdit(program.id),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.trainingEditProgram),
                ),
                TextButton(
                  onPressed: () => context.go(RoutePaths.trainingPrograms),
                  child: Text(l10n.trainingViewArchivedPrograms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmEndDeload(BuildContext context, WidgetRef ref, int programId) {
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
                  .exitDeload(programId);
            },
            child: Text(l10n.deloadEndAction),
          ),
        ],
      ),
    );
  }
}

class _ProgramProgress extends ConsumerWidget {
  final int programId;

  const _ProgramProgress({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progressAsync = ref.watch(programProgressProvider(programId));

    return progressAsync.when(
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
    );
  }
}

// ── Free Mode Header ─────────────────────────────────────────────────

class _FreeModeHeader extends StatelessWidget {
  const _FreeModeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AthlosSpacing.md,
        vertical: AthlosSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AthlosSpacing.md),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined,
                color: colorScheme.onSurfaceVariant),
            const Gap(AthlosSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.trainingFreeModeTitle,
                      style: textTheme.titleSmall),
                  const Gap(AthlosSpacing.xxs),
                  Text(
                    l10n.trainingFreeModeHint,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go(RoutePaths.trainingProgramNew),
              child: Text(l10n.trainingCreateProgram),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cycle list body (reorderable workout cards + archived section) ───

class _CycleListBody extends ConsumerStatefulWidget {
  final List<CycleListWorkoutItem> items;
  final bool isFromCycle;
  final int? nextStepIndex;
  final int? nextWorkoutId;
  final AsyncValue<List<Workout>> archivedAsync;
  final AsyncValue<TrainingProgram?> activeProgramAsync;

  const _CycleListBody({
    required this.items,
    required this.isFromCycle,
    required this.nextStepIndex,
    required this.nextWorkoutId,
    required this.archivedAsync,
    required this.activeProgramAsync,
  });

  @override
  ConsumerState<_CycleListBody> createState() => _CycleListBodyState();
}

class _CycleListBodyState extends ConsumerState<_CycleListBody> {
  late List<CycleListWorkoutItem> _items;
  bool _isArchivedExpanded = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant _CycleListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _items = List.of(widget.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final activeProgram = widget.activeProgramAsync.value;

    return CustomScrollView(
      slivers: [
        // Program hero card or free mode header
        SliverToBoxAdapter(
          child: activeProgram != null
              ? _ActiveProgramHeroCard(program: activeProgram)
              : const _FreeModeHeader(),
        ),

        // Workout cycle list
        SliverReorderableList(
          itemCount: _items.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final item = _items[index];
            return _WorkoutCard(
              key: ValueKey(item.workout.id),
              index: index,
              workout: item.workout,
              isNext: item.workout.id == widget.nextWorkoutId,
              onTap: () => context.push(
                '${RoutePaths.trainingWorkouts}/${item.workout.id}',
              ),
              onStart: () => _startWorkout(context, item.workout.id),
              onArchive: () => _archiveWorkout(context, item.workout.id),
              onDuplicate: () => _duplicateWorkout(context, item.workout.id),
              onDelete: () => _confirmDelete(context, item.workout),
            );
          },
        ),

        // Archived workouts
        if (widget.archivedAsync.value != null &&
            widget.archivedAsync.value!.isNotEmpty)
          SliverToBoxAdapter(
            child: ExpansionTile(
              title: Text(
                l10n.archivedSection,
                style: textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              initiallyExpanded: _isArchivedExpanded,
              onExpansionChanged: (v) =>
                  setState(() => _isArchivedExpanded = v),
              children: widget.archivedAsync.value!
                  .map((w) => _ArchivedWorkoutTile(
                        workout: w,
                        onUnarchive: () => _unarchiveWorkout(context, w.id),
                        onDuplicate: () => _duplicateWorkout(context, w.id),
                        onTap: () => context.push(
                          '${RoutePaths.trainingWorkouts}/${w.id}',
                        ),
                      ))
                  .toList(),
            ),
          ),

        const SliverPadding(
            padding: EdgeInsets.only(bottom: AthlosSpacing.fabClearance)),
      ],
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    if (widget.isFromCycle) {
      final steps = <TrainingCycleStep>[
        for (var i = 0; i < _items.length; i++)
          TrainingCycleStep(
            id: 0,
            orderIndex: i,
            workoutId: _items[i].workout.id,
          ),
      ];
      try {
        final programId = ref.read(activeProgramProvider).value?.id;
        final result = await ref
            .read(cycleRepositoryProvider)
            .setSteps(steps, programId: programId);
        result.getOrThrow();
        ref.invalidate(cycleStepsProvider);
      } on Exception catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.genericError)),
          );
        }
      }
    } else {
      final orderedIds = [for (final it in _items) it.workout.id];
      try {
        await ref
            .read(workoutListProvider.notifier)
            .reorderWorkouts(orderedIds);
      } on Exception catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.genericError)),
          );
        }
      }
    }
  }

  void _startWorkout(BuildContext context, int workoutId) {
    context.push('${RoutePaths.trainingWorkouts}/$workoutId/execute');
  }

  void _archiveWorkout(BuildContext context, int id) async {
    try {
      await ref.read(workoutListProvider.notifier).archiveWorkout(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.workoutArchived),
          ),
        );
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericError),
          ),
        );
      }
    }
  }

  void _unarchiveWorkout(BuildContext context, int id) async {
    try {
      await ref.read(workoutListProvider.notifier).unarchiveWorkout(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.workoutUnarchived),
          ),
        );
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericError),
          ),
        );
      }
    }
  }

  void _duplicateWorkout(BuildContext context, int id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(workoutListProvider.notifier)
          .duplicateWorkout(id, nameSuffix: l10n.workoutCopySuffix);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.duplicatedWorkout),
          ),
        );
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericError),
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, Workout workout) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteWorkoutTitle),
        content: Text(l10n.deleteWorkoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(workoutListProvider.notifier)
                    .deleteWorkout(workout.id);
              } on Exception catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.genericError),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

// ── Workout Card (reorderable) ───────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final int index;
  final Workout workout;
  final bool isNext;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onArchive;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _WorkoutCard({
    super.key,
    required this.index,
    required this.workout,
    required this.isNext,
    required this.onTap,
    required this.onStart,
    required this.onArchive,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AthlosSpacing.sm,
        vertical: AthlosSpacing.xs,
      ),
      shape: isNext
          ? RoundedRectangleBorder(
              borderRadius: AthlosRadius.mdAll,
              side: BorderSide(color: colorScheme.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AthlosRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AthlosSpacing.md,
            vertical: AthlosSpacing.sm,
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AthlosSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workout.name,
                            style: textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNext)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AthlosSpacing.sm,
                              vertical: AthlosSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: AthlosRadius.mdAll,
                            ),
                            child: Text(
                              l10n.nextWorkoutBadge,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (workout.description != null &&
                        workout.description!.isNotEmpty)
                      Text(
                        workout.description!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (isNext)
                FilledButton.tonalIcon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(l10n.trainingStartNext),
                )
              else
                IconButton(
                  icon: Icon(Icons.play_circle_outline,
                      color: colorScheme.primary),
                  tooltip: l10n.startWorkout,
                  onPressed: onStart,
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'archive':
                      onArchive();
                    case 'duplicate':
                      onDuplicate();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(l10n.archiveWorkout),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: const Icon(Icons.copy_outlined),
                      title: Text(l10n.duplicateWorkout),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: colorScheme.error),
                      title: Text(l10n.delete,
                          style: TextStyle(color: colorScheme.error)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Archived Workout Tile ────────────────────────────────────────────

class _ArchivedWorkoutTile extends StatelessWidget {
  final Workout workout;
  final VoidCallback onUnarchive;
  final VoidCallback onDuplicate;
  final VoidCallback onTap;

  const _ArchivedWorkoutTile({
    required this.workout,
    required this.onUnarchive,
    required this.onDuplicate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading:
          Icon(Icons.archive_outlined, color: colorScheme.onSurfaceVariant),
      title: Text(workout.name),
      subtitle: workout.description != null && workout.description!.isNotEmpty
          ? Text(
              workout.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.unarchive_outlined),
            tooltip: l10n.unarchiveWorkout,
            onPressed: onUnarchive,
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: l10n.duplicateWorkout,
            onPressed: onDuplicate,
          ),
        ],
      ),
    );
  }
}

// ── Expandable FAB (speed dial) ──────────────────────────────────────

class _ExpandableWorkoutFab extends StatefulWidget {
  final String chironLabel;
  final String createManualLabel;
  final VoidCallback onChiron;
  final VoidCallback onCreateManual;

  const _ExpandableWorkoutFab({
    required this.chironLabel,
    required this.createManualLabel,
    required this.onChiron,
    required this.onCreateManual,
  });

  @override
  State<_ExpandableWorkoutFab> createState() => _ExpandableWorkoutFabState();
}

class _ExpandableWorkoutFabState extends State<_ExpandableWorkoutFab> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  void _onAction(VoidCallback action) {
    action();
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AthlosSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _ActionChip(
                        icon: Icons.auto_awesome,
                        label: widget.chironLabel,
                        onPressed: () => _onAction(widget.onChiron),
                      ),
                      const SizedBox(height: AthlosSpacing.sm),
                      _ActionChip(
                        icon: Icons.edit_note,
                        label: widget.createManualLabel,
                        onPressed: () => _onAction(widget.onCreateManual),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        FloatingActionButton(
          heroTag: 'workouts_fab',
          onPressed: _toggle,
          tooltip: _expanded ? '' : widget.createManualLabel,
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AthlosSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: AthlosRadius.mdAll,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AthlosSpacing.sm,
                vertical: AthlosSpacing.xs,
              ),
              child: Text(
                label,
                style: textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: AthlosSpacing.sm),
          FloatingActionButton.small(
            heroTag: null,
            onPressed: onPressed,
            tooltip: label,
            child: Icon(icon),
          ),
        ],
      ),
    );
  }
}
