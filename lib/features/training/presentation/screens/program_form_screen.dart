import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/deload_config.dart';
import '../../domain/entities/progression_rule.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/workout.dart';
import '../../domain/enums/deload_strategy.dart';
import '../../domain/enums/duration_mode.dart';
import '../../domain/enums/program_focus.dart';
import '../../domain/enums/progression_condition.dart';
import '../../domain/enums/progression_frequency.dart';
import '../../domain/enums/progression_type.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/exercise_notifier.dart';
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
  final _deloadFreqController = TextEditingController();
  final _deloadVolController = TextEditingController(text: '0.6');
  final _deloadIntController = TextEditingController(text: '0.5');
  ProgramFocus _focus = ProgramFocus.hypertrophy;
  DurationMode _durationMode = DurationMode.sessions;
  List<int> _cycleWorkoutIds = [];
  bool _activate = true;
  bool _loaded = false;
  bool _saving = false;
  bool _deloadEnabled = false;
  DeloadStrategy _deloadStrategy = DeloadStrategy.reduceVolume;
  List<_ProgressionRuleEntry> _progressionRules = [];
  bool _progressionLoaded = false;

  bool get _isEditing => widget.programId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _restController.dispose();
    _deloadFreqController.dispose();
    _deloadVolController.dispose();
    _deloadIntController.dispose();
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
    if (p.deloadConfig != null) {
      _deloadEnabled = true;
      _deloadStrategy = p.deloadConfig!.strategy;
      if (p.deloadConfig!.frequency != null) {
        _deloadFreqController.text = p.deloadConfig!.frequency.toString();
      }
      _deloadVolController.text =
          p.deloadConfig!.volumeMultiplier.toString();
      _deloadIntController.text =
          p.deloadConfig!.intensityMultiplier.toString();
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final durationValue = int.tryParse(_durationController.text.trim());
    if (durationValue == null || durationValue <= 0) return;
    final rest = int.tryParse(_restController.text.trim());

    DeloadConfig? deloadConfig;
    if (_deloadEnabled) {
      final freq = int.tryParse(_deloadFreqController.text.trim());
      final vol = double.tryParse(_deloadVolController.text.trim()) ?? 0.6;
      final intensity =
          double.tryParse(_deloadIntController.text.trim()) ?? 0.5;
      deloadConfig = DeloadConfig(
        frequency: freq,
        strategy: _deloadStrategy,
        volumeMultiplier: vol,
        intensityMultiplier: intensity,
      );
    }

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
          deloadConfig: deloadConfig,
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
        await _saveProgressionRules(widget.programId!);
      } else {
        final program = TrainingProgram(
          id: 0,
          name: name,
          focus: _focus,
          durationMode: _durationMode,
          durationValue: durationValue,
          defaultRestSeconds: rest,
          isActive: _activate,
          deloadConfig: deloadConfig,
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
        await _saveProgressionRules(id);
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

  Future<void> _saveProgressionRules(int programId) async {
    final repo = ref.read(progressionRuleRepositoryProvider);
    final rules = _progressionRules
        .map((r) => ProgressionRule(
              id: 0,
              programId: programId,
              exerciseId: r.exerciseId,
              type: r.type,
              value: r.value,
              frequency: r.frequency,
              condition: r.condition,
              conditionValue: r.conditionValue,
            ))
        .toList();
    final result = await repo.replaceAllForProgram(programId, rules);
    result.getOrThrow();
  }

  void _addProgressionRule(_ProgressionRuleEntry entry) {
    setState(() => _progressionRules = [..._progressionRules, entry]);
  }

  void _removeProgressionRuleAt(int index) {
    setState(
        () => _progressionRules = [..._progressionRules]..removeAt(index));
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
      if (!_progressionLoaded) {
        final rulesRepo = ref.read(progressionRuleRepositoryProvider);
        rulesRepo.getByProgram(widget.programId!).then((result) {
          if (!mounted || _progressionLoaded) return;
          final rules = result.getOrThrow();
          setState(() {
            _progressionLoaded = true;
            _progressionRules = rules
                .map((r) => _ProgressionRuleEntry(
                      exerciseId: r.exerciseId,
                      type: r.type,
                      value: r.value,
                      frequency: r.frequency,
                      condition: r.condition,
                      conditionValue: r.conditionValue,
                    ))
                .toList();
          });
        });
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

          const SizedBox(height: AthlosSpacing.lg),
          Text(
            l10n.deloadSectionTitle,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.deloadEnableLabel),
            value: _deloadEnabled,
            onChanged: (v) => setState(() => _deloadEnabled = v),
          ),
          if (_deloadEnabled) ...[
            const SizedBox(height: AthlosSpacing.sm),
            Text(
              l10n.deloadStrategyLabel,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AthlosSpacing.xs),
            Wrap(
              spacing: AthlosSpacing.sm,
              children: DeloadStrategy.values.map((s) {
                final label = switch (s) {
                  DeloadStrategy.reduceVolume =>
                    l10n.deloadStrategyReduceVolume,
                  DeloadStrategy.reduceIntensity =>
                    l10n.deloadStrategyReduceIntensity,
                  DeloadStrategy.reduceBoth =>
                    l10n.deloadStrategyReduceBoth,
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _deloadStrategy == s,
                  onSelected: (_) =>
                      setState(() => _deloadStrategy = s),
                );
              }).toList(),
            ),
            const SizedBox(height: AthlosSpacing.md),
            TextField(
              controller: _deloadFreqController,
              decoration: InputDecoration(
                labelText: l10n.deloadFrequencyLabel,
                hintText: l10n.deloadFrequencyManualHint,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AthlosSpacing.md),
            if (_deloadStrategy != DeloadStrategy.reduceIntensity)
              TextField(
                controller: _deloadVolController,
                decoration: InputDecoration(
                  labelText: l10n.deloadVolumeMultiplierLabel,
                  hintText: l10n.deloadVolumeMultiplierHint,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            if (_deloadStrategy != DeloadStrategy.reduceIntensity)
              const SizedBox(height: AthlosSpacing.md),
            if (_deloadStrategy != DeloadStrategy.reduceVolume)
              TextField(
                controller: _deloadIntController,
                decoration: InputDecoration(
                  labelText: l10n.deloadIntensityMultiplierLabel,
                  hintText: l10n.deloadIntensityMultiplierHint,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
          ],

          const SizedBox(height: AthlosSpacing.lg),
          Text(
            l10n.progressionSectionTitle,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AthlosSpacing.xs),
          if (_progressionRules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AthlosSpacing.sm),
              child: Text(
                l10n.progressionEmptyHint,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ..._progressionRules.asMap().entries.map((entry) {
            final idx = entry.key;
            final rule = entry.value;
            final exercises = ref.watch(exerciseListProvider).value ?? [];
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
                  onPressed: () => _removeProgressionRuleAt(idx),
                ),
              ),
            );
          }),
          const SizedBox(height: AthlosSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _showAddProgressionRuleDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.progressionAddRule),
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

  void _showAddProgressionRuleDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercises = ref.read(exerciseListProvider).value ?? [];
    if (exercises.isEmpty) return;

    int? selectedExerciseId;
    var selectedType = ProgressionType.incrementWeight;
    var selectedFrequency = ProgressionFrequency.everySession;
    ProgressionCondition? selectedCondition;
    final valueController = TextEditingController(text: '2.5');
    final conditionValueController = TextEditingController(text: '8');

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final valueHint = switch (selectedType) {
            ProgressionType.incrementWeight =>
              l10n.progressionValueHintWeight,
            ProgressionType.incrementReps => l10n.progressionValueHintReps,
            ProgressionType.incrementSets => l10n.progressionValueHintSets,
          };

          return AlertDialog(
            title: Text(l10n.progressionAddRule),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: l10n.progressionExerciseLabel,
                    ),
                    initialValue: selectedExerciseId,
                    items: exercises.map((e) {
                      final name = localizedExerciseName(
                        e.name,
                        isVerified: e.isVerified,
                        l10n: l10n,
                      );
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedExerciseId = v),
                    isExpanded: true,
                  ),
                  const SizedBox(height: AthlosSpacing.md),
                  DropdownButtonFormField<ProgressionType>(
                    decoration: InputDecoration(
                      labelText: l10n.progressionTypeLabel,
                    ),
                    initialValue: selectedType,
                    items: ProgressionType.values.map((t) {
                      final label = switch (t) {
                        ProgressionType.incrementWeight =>
                          l10n.progressionTypeIncrementWeight,
                        ProgressionType.incrementReps =>
                          l10n.progressionTypeIncrementReps,
                        ProgressionType.incrementSets =>
                          l10n.progressionTypeIncrementSets,
                      };
                      return DropdownMenuItem(value: t, child: Text(label));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        selectedType = v;
                        valueController.text = switch (v) {
                          ProgressionType.incrementWeight => '2.5',
                          ProgressionType.incrementReps => '1',
                          ProgressionType.incrementSets => '1',
                        };
                      });
                    },
                  ),
                  const SizedBox(height: AthlosSpacing.md),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      labelText: l10n.progressionValueLabel,
                      hintText: valueHint,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                  const SizedBox(height: AthlosSpacing.md),
                  DropdownButtonFormField<ProgressionFrequency>(
                    decoration: InputDecoration(
                      labelText: l10n.progressionFrequencyLabel,
                    ),
                    initialValue: selectedFrequency,
                    items: ProgressionFrequency.values.map((f) {
                      final label = switch (f) {
                        ProgressionFrequency.everySession =>
                          l10n.progressionFrequencyEverySession,
                        ProgressionFrequency.everyRotation =>
                          l10n.progressionFrequencyEveryRotation,
                      };
                      return DropdownMenuItem(value: f, child: Text(label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedFrequency = v);
                      }
                    },
                  ),
                  const SizedBox(height: AthlosSpacing.md),
                  DropdownButtonFormField<ProgressionCondition?>(
                    decoration: InputDecoration(
                      labelText: l10n.progressionConditionLabel,
                    ),
                    initialValue: selectedCondition,
                    items: [
                      DropdownMenuItem<ProgressionCondition?>(
                        value: null,
                        child: Text(l10n.progressionConditionNone),
                      ),
                      ...ProgressionCondition.values.map((c) {
                        final label = switch (c) {
                          ProgressionCondition.hitsMaxReps =>
                            l10n.progressionConditionHitsMaxReps,
                          ProgressionCondition.completesAllSets =>
                            l10n.progressionConditionCompletesAllSets,
                          ProgressionCondition.rpeBelow =>
                            l10n.progressionConditionRpeBelow,
                        };
                        return DropdownMenuItem<ProgressionCondition?>(
                          value: c,
                          child: Text(label),
                        );
                      }),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedCondition = v),
                  ),
                  if (selectedCondition == ProgressionCondition.rpeBelow) ...[
                    const SizedBox(height: AthlosSpacing.md),
                    TextField(
                      controller: conditionValueController,
                      decoration: InputDecoration(
                        labelText: l10n.progressionConditionValueHint,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: selectedExerciseId == null
                    ? null
                    : () {
                        final val = double.tryParse(
                            valueController.text.trim());
                        if (val == null || val <= 0) return;
                        double? condVal;
                        if (selectedCondition ==
                            ProgressionCondition.rpeBelow) {
                          condVal = double.tryParse(
                              conditionValueController.text.trim());
                        }
                        _addProgressionRule(_ProgressionRuleEntry(
                          exerciseId: selectedExerciseId!,
                          type: selectedType,
                          value: val,
                          frequency: selectedFrequency,
                          condition: selectedCondition,
                          conditionValue: condVal,
                        ));
                        Navigator.pop(ctx);
                      },
                child: Text(l10n.programSaveAction),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressionRuleEntry {
  final int exerciseId;
  final ProgressionType type;
  final double value;
  final ProgressionFrequency frequency;
  final ProgressionCondition? condition;
  final double? conditionValue;

  const _ProgressionRuleEntry({
    required this.exerciseId,
    required this.type,
    required this.value,
    required this.frequency,
    this.condition,
    this.conditionValue,
  });
}
