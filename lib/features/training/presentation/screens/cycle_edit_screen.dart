import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/errors/result.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/cycle_step.dart';
import '../../domain/entities/workout.dart';
import '../providers/training_analytics_provider.dart';
import '../providers/workout_notifier.dart';

/// Screen to edit the training cycle: ordered workout queue.
class CycleEditScreen extends ConsumerStatefulWidget {
  const CycleEditScreen({super.key});

  @override
  ConsumerState<CycleEditScreen> createState() => _CycleEditScreenState();
}

class _CycleEditScreenState extends ConsumerState<CycleEditScreen> {
  List<int> _workoutIds = [];
  bool _syncedFromProvider = false;

  void _syncFromProvider(List<TrainingCycleStep> steps) {
    if (!_syncedFromProvider && mounted) {
      _syncedFromProvider = true;
      setState(() {
        _workoutIds = steps.map((s) => s.workoutId).toList();
      });
    }
  }

  Future<void> _save() async {
    final repo = ref.read(cycleRepositoryProvider);
    final steps = [
      for (var i = 0; i < _workoutIds.length; i++)
        TrainingCycleStep(
          id: 0,
          orderIndex: i,
          workoutId: _workoutIds[i],
        ),
    ];
    final result = await repo.setSteps(steps);
    switch (result) {
      case Success():
        ref.invalidate(cycleStepsProvider);
        if (mounted) context.pop();
      case Failure(:final exception):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(exception.message)),
          );
        }
    }
  }

  void _addWorkout(int? workoutId) {
    if (workoutId == null) return;
    setState(() {
      _workoutIds = [..._workoutIds, workoutId];
    });
  }

  void _removeAt(int index) {
    setState(() {
      _workoutIds = [..._workoutIds]..removeAt(index);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _workoutIds.removeAt(oldIndex);
      _workoutIds.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stepsAsync = ref.watch(cycleStepsProvider);
    final workoutsAsync = ref.watch(workoutListProvider);
    final workouts = workoutsAsync.value ?? [];

    stepsAsync.whenData(_syncFromProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.trainingCycleTitle),
        actions: [
          TextButton(
            onPressed: _workoutIds.isEmpty ? null : _save,
            child: Text(l10n.trainingCycleSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AthlosSpacing.md),
        children: [
          if (_workoutIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AthlosSpacing.md),
              child: Text(
                l10n.trainingCycleEmptyHint,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _workoutIds.length,
            onReorder: _reorder,
            itemBuilder: (context, index) {
              final workoutId = _workoutIds[index];
              final label = workouts
                      .where((w) => w.id == workoutId)
                      .map((w) => w.name)
                      .firstOrNull ??
                  'Treino #$workoutId';
              return Card(
                key: ValueKey('$index-$workoutId'),
                margin: const EdgeInsets.only(bottom: AthlosSpacing.sm),
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
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeAt(index),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AthlosSpacing.md),
          Text(
            l10n.trainingCycleAddStep,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AthlosSpacing.xs),
          OutlinedButton.icon(
            onPressed: workouts.isEmpty
                ? null
                : () => _showAddWorkoutPicker(context, workouts),
            icon: const Icon(Icons.fitness_center),
            label: Text(l10n.trainingCycleAddWorkout),
          ),
        ],
      ),
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
