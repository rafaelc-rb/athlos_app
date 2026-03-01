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

/// Screen to edit the training cycle: ordered steps (workout or rest).
class CycleEditScreen extends ConsumerStatefulWidget {
  const CycleEditScreen({super.key});

  @override
  ConsumerState<CycleEditScreen> createState() => _CycleEditScreenState();
}

class _CycleEditScreenState extends ConsumerState<CycleEditScreen> {
  List<({CycleStepType type, int? workoutId})> _steps = [];
  bool _syncedFromProvider = false;

  void _syncFromProvider(List<TrainingCycleStep> steps) {
    if (!_syncedFromProvider && mounted) {
      _syncedFromProvider = true;
      setState(() {
        _steps = steps
            .map((s) => (
                  type: s.type,
                  workoutId: s.workoutId,
                ))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final repo = ref.read(cycleRepositoryProvider);
    final steps = [
      for (var i = 0; i < _steps.length; i++)
        TrainingCycleStep(
          id: 0,
          orderIndex: i,
          type: _steps[i].type,
          workoutId: _steps[i].workoutId,
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
      _steps = [..._steps, (type: CycleStepType.workout, workoutId: workoutId)];
    });
  }

  void _addRest() {
    setState(() {
      _steps = [..._steps, (type: CycleStepType.rest, workoutId: null)];
    });
  }

  void _removeAt(int index) {
    setState(() {
      _steps = [..._steps]..removeAt(index);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
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
            onPressed: _steps.isEmpty ? null : _save,
            child: Text(l10n.trainingCycleSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AthlosSpacing.md),
        children: [
          if (_steps.isEmpty)
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
            itemCount: _steps.length,
            onReorder: _reorder,
            itemBuilder: (context, index) {
              final step = _steps[index];
              final label = step.type == CycleStepType.rest
                  ? l10n.trainingRest
                  : workouts
                      .where((w) => w.id == step.workoutId)
                      .map((w) => w.name)
                      .firstOrNull ??
                      'Treino #${step.workoutId}';
              return Card(
                key: ValueKey('$index-${step.type}-${step.workoutId}'),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: workouts.isEmpty
                      ? null
                      : () => _showAddWorkoutPicker(context, workouts),
                  icon: const Icon(Icons.fitness_center),
                  label: Text(l10n.trainingCycleAddWorkout),
                ),
              ),
              const SizedBox(width: AthlosSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addRest,
                  icon: const Icon(Icons.hotel),
                  label: Text(l10n.trainingCycleAddRest),
                ),
              ),
            ],
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
