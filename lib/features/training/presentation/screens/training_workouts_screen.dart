import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../domain/entities/workout.dart';
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

/// Training module — Workouts tab.
///
/// Shows active workouts in a reorderable list with a FAB to start the next
/// workout in the cycle and a collapsible archived section.
class TrainingWorkoutsScreen extends ConsumerWidget {
  const TrainingWorkoutsScreen({super.key});

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

    final nextWorkout = nextWorkoutToStartAsync.value;
    final nextStepIndex = nextStepIndexAsync.value;
    final workoutCount = workoutsAsync.value?.length ?? 0;

    return Scaffold(
      body: () {
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
            ),
            loading: () => _CycleListBody(
              items: (workouts.isEmpty ? _placeholderWorkouts : workouts)
                  .map((w) => CycleListWorkoutItem(stepIndex: 0, workout: w))
                  .toList(),
              isFromCycle: false,
              nextStepIndex: null,
              nextWorkoutId: null,
              archivedAsync: archivedAsync,
            ),
            error: (_, stackTrace) => Center(child: Text(l10n.genericError)),
          ),
        );
      }(),
      floatingActionButton: _ExpandableWorkoutFab(
        chironLabel: workoutCount == 0
            ? l10n.chironCreateWorkoutShortcut
            : l10n.chironAnalyzeWorkoutsShortcut,
        createManualLabel: l10n.trainingWorkoutActionCreateManual,
        addRestLabel: l10n.trainingAddRestToCycleAction,
        onChiron: () => showChironSheet(
          context,
          initialMessage: workoutCount == 0
              ? l10n.chironAskToCreateWorkout
              : l10n.chironAnalyzeWorkoutsMessage,
        ),
        onCreateManual: () => context.push(RoutePaths.trainingWorkoutNew),
        onAddRest: () => _addRestToCycle(context, ref),
      ),
    );
  }

  Future<void> _addRestToCycle(BuildContext context, WidgetRef ref) async {
    try {
      final cycleRepo = ref.read(cycleRepositoryProvider);
      final result = await cycleRepo.appendRestToCycle();
      result.getOrThrow();
      ref.invalidate(cycleStepsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.trainingCycleAddRest),
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

}

/// Expandable FAB (speed dial): Quíron, Criar treino manual, Adicionar descanso.
class _ExpandableWorkoutFab extends StatefulWidget {
  final String chironLabel;
  final String createManualLabel;
  final String addRestLabel;
  final VoidCallback onChiron;
  final VoidCallback onCreateManual;
  final VoidCallback onAddRest;

  const _ExpandableWorkoutFab({
    required this.chironLabel,
    required this.createManualLabel,
    required this.addRestLabel,
    required this.onChiron,
    required this.onCreateManual,
    required this.onAddRest,
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
        // Expanded actions (top to bottom: Criar, Configurar ciclo, Iniciar próximo)
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
                      const SizedBox(height: AthlosSpacing.sm),
                      _ActionChip(
                        icon: Icons.hotel,
                        label: widget.addRestLabel,
                        onPressed: () => _onAction(widget.onAddRest),
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

class _CycleListBody extends ConsumerStatefulWidget {
  final List<CycleListItem> items;
  final bool isFromCycle;
  final int? nextStepIndex;
  final int? nextWorkoutId;
  final AsyncValue<List<Workout>> archivedAsync;

  const _CycleListBody({
    required this.items,
    required this.isFromCycle,
    required this.nextStepIndex,
    required this.nextWorkoutId,
    required this.archivedAsync,
  });

  @override
  ConsumerState<_CycleListBody> createState() => _CycleListBodyState();
}

class _CycleListBodyState extends ConsumerState<_CycleListBody> {
  late List<CycleListItem> _items;
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

    return CustomScrollView(
      slivers: [
        SliverReorderableList(
          itemCount: _items.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final item = _items[index];
            return switch (item) {
              CycleListRestItem() => _RestTile(
                  key: ValueKey('rest_$index'),
                  index: index,
                  isNext: index == widget.nextStepIndex,
                  canReorder: widget.isFromCycle,
                  label: l10n.trainingCycleRestLabel,
                ),
              CycleListWorkoutItem(:final workout) => _WorkoutCard(
                  key: ValueKey(workout.id),
                  index: index,
                  workout: workout,
                  isNext: workout.id == widget.nextWorkoutId,
                  onTap: () => context.push(
                    '${RoutePaths.trainingWorkouts}/${workout.id}',
                  ),
                  onStart: () => _startWorkout(context, workout.id),
                  onArchive: () => _archiveWorkout(context, workout.id),
                  onDuplicate: () => _duplicateWorkout(context, workout.id),
                  onDelete: () => _confirmDelete(context, workout),
                ),
            };
          },
        ),

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
              onExpansionChanged: (v) => setState(() => _isArchivedExpanded = v),
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
      final steps = <TrainingCycleStep>[];
      for (var i = 0; i < _items.length; i++) {
        final it = _items[i];
        switch (it) {
          case CycleListRestItem():
            steps.add(TrainingCycleStep(
              id: 0,
              orderIndex: i,
              type: CycleStepType.rest,
              workoutId: null,
            ));
          case CycleListWorkoutItem(:final workout):
            steps.add(TrainingCycleStep(
              id: 0,
              orderIndex: i,
              type: CycleStepType.workout,
              workoutId: workout.id,
            ));
        }
      }
      try {
        final result = await ref
            .read(cycleRepositoryProvider)
            .setSteps(steps);
        result.getOrThrow();
        ref.invalidate(cycleStepsProvider);
      } on Exception catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.genericError)),
          );
        }
      }
    } else {
      final orderedIds = <int>[
        for (final it in _items)
          if (it is CycleListWorkoutItem) it.workout.id,
      ];
      try {
        await ref.read(workoutListProvider.notifier).reorderWorkouts(orderedIds);
      } on Exception catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.genericError)),
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
                      content: Text(AppLocalizations.of(context)!.genericError),
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

class _RestTile extends StatelessWidget {
  final int index;
  final bool isNext;
  final bool canReorder;
  final String label;

  const _RestTile({
    super.key,
    required this.index,
    required this.isNext,
    required this.canReorder,
    required this.label,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AthlosSpacing.md,
          vertical: AthlosSpacing.sm,
        ),
        child: Row(
          children: [
            if (canReorder)
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (canReorder) const SizedBox(width: AthlosSpacing.sm),
            Icon(
              Icons.hotel,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AthlosSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
      ),
    );
  }
}

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
      leading: Icon(Icons.archive_outlined, color: colorScheme.onSurfaceVariant),
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
