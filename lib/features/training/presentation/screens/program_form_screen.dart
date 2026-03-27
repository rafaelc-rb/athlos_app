import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/workout.dart';
import '../../domain/enums/duration_mode.dart';
import '../../domain/enums/program_focus.dart';
import '../providers/program_notifier.dart';
import '../providers/training_analytics_provider.dart';
import '../providers/workout_notifier.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/cycle_step.dart';

/// Screen to create or edit a training program (mesocycle).
class ProgramFormScreen extends ConsumerStatefulWidget {
  final int? programId;

  const ProgramFormScreen({super.key, this.programId});

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _restController = TextEditingController();
  ProgramFocus _focus = ProgramFocus.hypertrophy;
  DurationMode _durationMode = DurationMode.sessions;
  List<int> _cycleWorkoutIds = [];
  bool _activate = true;
  bool _loaded = false;
  bool _saving = false;

  bool get _isEditing => widget.programId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _loadExisting(TrainingProgram p, List<TrainingCycleStep> steps) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = p.name;
    _focus = p.focus;
    _durationMode = p.durationMode;
    _durationController.text = p.durationValue.toString();
    if (p.defaultRestSeconds != null) {
      _restController.text = p.defaultRestSeconds.toString();
    }
    _cycleWorkoutIds = steps.map((s) => s.workoutId).toList();
    _activate = p.isActive;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final durationValue = int.tryParse(_durationController.text.trim());
    if (durationValue == null || durationValue <= 0) return;
    final rest = int.tryParse(_restController.text.trim());

    setState(() => _saving = true);
    try {
      final actions = ref.read(programActionsProvider.notifier);
      final cycleRepo = ref.read(cycleRepositoryProvider);

      if (_isEditing) {
        final program = TrainingProgram(
          id: widget.programId!,
          name: name,
          focus: _focus,
          durationMode: _durationMode,
          durationValue: durationValue,
          defaultRestSeconds: rest,
          createdAt: DateTime.now(),
        );
        await actions.updateProgram(program);
        final steps = [
          for (var i = 0; i < _cycleWorkoutIds.length; i++)
            TrainingCycleStep(
              id: 0,
              orderIndex: i,
              workoutId: _cycleWorkoutIds[i],
            ),
        ];
        await cycleRepo.setSteps(steps, programId: widget.programId);
      } else {
        final program = TrainingProgram(
          id: 0,
          name: name,
          focus: _focus,
          durationMode: _durationMode,
          durationValue: durationValue,
          defaultRestSeconds: rest,
          isActive: _activate,
          createdAt: DateTime.now(),
        );
        final id = await actions.createProgram(program);
        if (_activate) {
          await actions.activateProgram(id);
        }
        final steps = [
          for (var i = 0; i < _cycleWorkoutIds.length; i++)
            TrainingCycleStep(
              id: 0,
              orderIndex: i,
              workoutId: _cycleWorkoutIds[i],
            ),
        ];
        await cycleRepo.setSteps(steps, programId: id);
      }

      ref.invalidate(cycleStepsProvider);
      ref.invalidate(programListProvider);
      ref.invalidate(activeProgramProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? l10n.programUpdated : l10n.programCreated,
            ),
          ),
        );
        context.pop();
      }
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addWorkout(int workoutId) {
    setState(() => _cycleWorkoutIds = [..._cycleWorkoutIds, workoutId]);
  }

  void _removeWorkoutAt(int index) {
    setState(() => _cycleWorkoutIds = [..._cycleWorkoutIds]..removeAt(index));
  }

  void _reorderWorkouts(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _cycleWorkoutIds.removeAt(oldIndex);
      _cycleWorkoutIds.insert(newIndex, item);
    });
  }

  void _updateFocusRest(ProgramFocus focus) {
    _focus = focus;
    if (_restController.text.isEmpty) {
      final suggested = focus.suggestedRestSeconds;
      if (suggested != null) {
        _restController.text = suggested.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final workoutsAsync = ref.watch(workoutListProvider);
    final workouts = workoutsAsync.value ?? [];

    if (_isEditing) {
      final programsAsync = ref.watch(programListProvider);
      final stepsAsync =
          ref.watch(cycleStepsForProgramProvider(widget.programId!));
      final program =
          programsAsync.value?.where((p) => p.id == widget.programId).firstOrNull;
      final steps = stepsAsync.value;
      if (program != null && steps != null) {
        _loadExisting(program, steps);
      }
    }

    final canSave = _nameController.text.trim().isNotEmpty &&
        (_durationController.text.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.programEditTitle : l10n.programCreateTitle),
        actions: [
          TextButton(
            onPressed: canSave && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.programSaveAction),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AthlosSpacing.md),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.programNameLabel,
              hintText: l10n.programNameHint,
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AthlosSpacing.lg),

          Text(
            l10n.programFocusLabel,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AthlosSpacing.sm),
          Wrap(
            spacing: AthlosSpacing.sm,
            children: ProgramFocus.values.map((f) {
              final label = switch (f) {
                ProgramFocus.hypertrophy => l10n.programFocusHypertrophy,
                ProgramFocus.strength => l10n.programFocusStrength,
                ProgramFocus.endurance => l10n.programFocusEndurance,
                ProgramFocus.custom => l10n.programFocusCustom,
              };
              return ChoiceChip(
                label: Text(label),
                selected: _focus == f,
                onSelected: (_) => setState(() => _updateFocusRest(f)),
              );
            }).toList(),
          ),
          const SizedBox(height: AthlosSpacing.lg),

          Text(
            l10n.programDurationModeLabel,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AthlosSpacing.sm),
          SegmentedButton<DurationMode>(
            segments: [
              ButtonSegment(
                value: DurationMode.sessions,
                label: Text(l10n.programDurationModeSessions),
              ),
              ButtonSegment(
                value: DurationMode.rotations,
                label: Text(l10n.programDurationModeRotations),
              ),
            ],
            selected: {_durationMode},
            onSelectionChanged: (s) =>
                setState(() => _durationMode = s.first),
          ),
          const SizedBox(height: AthlosSpacing.md),

          TextField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: l10n.programDurationValueLabel,
              hintText: _durationMode == DurationMode.sessions
                  ? l10n.programDurationValueHintSessions
                  : l10n.programDurationValueHintRotations,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AthlosSpacing.md),

          TextField(
            controller: _restController,
            decoration: InputDecoration(
              labelText: l10n.programDefaultRestLabel,
              hintText: l10n.programDefaultRestHint,
              suffixText: 's',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AthlosSpacing.lg),

          Text(
            l10n.programCycleSection,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AthlosSpacing.xs),
          if (_cycleWorkoutIds.isEmpty)
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
            itemCount: _cycleWorkoutIds.length,
            onReorder: _reorderWorkouts,
            itemBuilder: (context, index) {
              final workoutId = _cycleWorkoutIds[index];
              final label = workouts
                      .where((w) => w.id == workoutId)
                      .map((w) => w.name)
                      .firstOrNull ??
                  'Treino #$workoutId';
              return Card(
                key: ValueKey('$index-$workoutId'),
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
                    onPressed: () => _removeWorkoutAt(index),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AthlosSpacing.sm),
          OutlinedButton.icon(
            onPressed: workouts.isEmpty
                ? null
                : () => _showAddWorkoutPicker(context, workouts),
            icon: const Icon(Icons.add),
            label: Text(l10n.trainingCycleAddWorkout),
          ),

          if (!_isEditing) ...[
            const SizedBox(height: AthlosSpacing.lg),
            SwitchListTile(
              title: Text(l10n.programActivateAndSave),
              value: _activate,
              onChanged: (v) => setState(() => _activate = v),
            ),
          ],
          const SizedBox(height: AthlosSpacing.fabClearance),
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
