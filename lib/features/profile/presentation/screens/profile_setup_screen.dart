import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/athlos_durations.dart';
import '../../../../core/theme/athlos_radius.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/body_aesthetic.dart';
import '../../domain/enums/experience_level.dart';
import '../../domain/enums/training_goal.dart';
import '../../domain/enums/training_style.dart';
import '../providers/profile_notifier.dart';
import '../widgets/aesthetic_selector.dart';
import '../widgets/experience_selector.dart';
import '../widgets/goal_selector.dart';
import '../widgets/style_selector.dart';

/// Profile setup screen shown on first launch.
///
/// Uses a PageView with a custom step indicator instead of Stepper
/// to avoid overflow issues and give a cleaner look.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _totalSteps = 6;
  int _currentStep = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _bioController = TextEditingController();

  TrainingGoal? _selectedGoal;
  BodyAesthetic? _selectedAesthetic;
  TrainingStyle? _selectedStyle;
  ExperienceLevel? _selectedExperience;
  int? _trainingFrequency;
  bool? _trainsAtGym;
  bool _isSaving = false;
  bool _shouldShowHelp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _injuriesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileSetupTitle),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: Text(l10n.skip),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AthlosSpacing.md),
              child: Text(
                l10n.profileSetupSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(AthlosSpacing.md),

            // Step indicator
            _StepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              labels: [
                l10n.stepPersonalData,
                l10n.stepGoal,
                l10n.stepAesthetic,
                l10n.stepStyle,
                l10n.stepExperience,
                l10n.stepHealth,
              ],
            ),
            const Gap(AthlosSpacing.lg),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AthlosSpacing.md),
                child: AnimatedSwitcher(
                  duration: AthlosDurations.normal,
                  child: switch (_currentStep) {
                    0 => _buildPersonalDataStep(l10n),
                    1 => _buildGoalStep(),
                    2 => _buildAestheticStep(),
                    3 => _buildStyleStep(),
                    4 => _buildExperienceStep(l10n, colorScheme, textTheme),
                    5 => _buildHealthStep(l10n),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(AthlosSpacing.md, AthlosSpacing.smd, AthlosSpacing.md, AthlosSpacing.md),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _onBack,
                      child: Text(l10n.back),
                    )
                  else
                    const SizedBox.shrink(),
                  // Help toggle — only on selection steps
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: () =>
                          setState(() => _shouldShowHelp = !_shouldShowHelp),
                      tooltip: l10n.helpModeTooltip,
                      icon: Icon(
                        _shouldShowHelp
                            ? Icons.help
                            : Icons.help_outline,
                        color: _shouldShowHelp
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isSaving ? null : _onNext,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == _totalSteps - 1
                                ? l10n.finish
                                : l10n.next,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataStep(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey(0),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              hintText: l10n.nameHint,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const Gap(AthlosSpacing.md),
          TextFormField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: l10n.weightLabel,
              hintText: l10n.weightHint,
              suffixText: l10n.weightUnit,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                return l10n.invalidNumber;
              }
              return null;
            },
          ),
          const Gap(AthlosSpacing.md),
          TextFormField(
            controller: _heightController,
            decoration: InputDecoration(
              labelText: l10n.heightLabel,
              hintText: l10n.heightHint,
              suffixText: l10n.heightUnit,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                return l10n.invalidNumber;
              }
              return null;
            },
          ),
          const Gap(AthlosSpacing.md),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: l10n.ageLabel,
              hintText: l10n.ageHint,
              suffixText: l10n.yearsUnit,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                return l10n.invalidNumber;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return GoalSelector(
      key: const ValueKey(1),
      selected: _selectedGoal,
      onSelected: (goal) => setState(() => _selectedGoal = goal),
      shouldShowHelp: _shouldShowHelp,
    );
  }

  Widget _buildAestheticStep() {
    return AestheticSelector(
      key: const ValueKey(2),
      selected: _selectedAesthetic,
      onSelected: (aesthetic) =>
          setState(() => _selectedAesthetic = aesthetic),
      shouldShowHelp: _shouldShowHelp,
    );
  }

  Widget _buildStyleStep() {
    return StyleSelector(
      key: const ValueKey(3),
      selected: _selectedStyle,
      onSelected: (style) => setState(() => _selectedStyle = style),
      shouldShowHelp: _shouldShowHelp,
    );
  }

  Widget _buildExperienceStep(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExperienceSelector(
          selected: _selectedExperience,
          onSelected: (level) =>
              setState(() => _selectedExperience = level),
          shouldShowHelp: _shouldShowHelp,
        ),
        const Gap(AthlosSpacing.lg),
        Text(l10n.trainingFrequencyLabel, style: textTheme.titleMedium),
        const Gap(AthlosSpacing.sm),
        Text(
          l10n.trainingFrequencyHint,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(AthlosSpacing.md),
        Slider(
          value: (_trainingFrequency ?? 3).toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: '${_trainingFrequency ?? 3}x',
          onChanged: (v) =>
              setState(() => _trainingFrequency = v.round()),
        ),
        Center(
          child: Text(
            '${_trainingFrequency ?? 3} ${l10n.daysPerWeek}',
            style: textTheme.titleSmall,
          ),
        ),
        const Gap(AthlosSpacing.lg),
        SwitchListTile(
          title: Text(l10n.trainsAtGymLabel),
          subtitle: Text(l10n.trainsAtGymHint),
          value: _trainsAtGym ?? false,
          onChanged: (v) => setState(() => _trainsAtGym = v),
        ),
      ],
    );
  }

  Widget _buildHealthStep(AppLocalizations l10n) {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _injuriesController,
          decoration: InputDecoration(
            labelText: l10n.injuriesLabel,
            hintText: l10n.injuriesHint,
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        const Gap(AthlosSpacing.lg),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: l10n.bioLabel,
            hintText: l10n.bioHint,
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  void _onNext() {
    switch (_currentStep) {
      case 0:
        if (_formKey.currentState?.validate() ?? false) {
          setState(() => _currentStep = 1);
        }
      case 1:
        setState(() => _currentStep = 2);
      case 2:
        setState(() => _currentStep = 3);
      case 3:
        setState(() => _currentStep = 4);
      case 4:
        setState(() => _currentStep = 5);
      case 5:
        _saveProfile();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _onSkip() async {
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final weight = double.tryParse(_weightController.text);
      final height = double.tryParse(_heightController.text);
      final age = int.tryParse(_ageController.text);

      final injuries = _injuriesController.text.trim();
      final bio = _bioController.text.trim();

      await ref.read(profileProvider.notifier).create(
            name: name.isEmpty ? null : name,
            weight: weight,
            height: height,
            age: age,
            goal: _selectedGoal,
            bodyAesthetic: _selectedAesthetic,
            trainingStyle: _selectedStyle,
            experienceLevel: _selectedExperience,
            trainingFrequency: _trainingFrequency,
            trainsAtGym: _trainsAtGym,
            injuries: injuries.isEmpty ? null : injuries,
            bio: bio.isEmpty ? null : bio,
          );

      ref.read(hasProfileProvider.notifier).markAsCreated();

      if (mounted) {
        context.go(RoutePaths.hub);
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final weight = double.tryParse(_weightController.text);
      final height = double.tryParse(_heightController.text);
      final age = int.tryParse(_ageController.text);
      final injuries = _injuriesController.text.trim();
      final bio = _bioController.text.trim();

      await ref.read(profileProvider.notifier).create(
            name: name.isEmpty ? null : name,
            weight: weight,
            height: height,
            age: age,
            goal: _selectedGoal,
            bodyAesthetic: _selectedAesthetic,
            trainingStyle: _selectedStyle,
            experienceLevel: _selectedExperience,
            trainingFrequency: _trainingFrequency,
            trainsAtGym: _trainsAtGym,
            injuries: injuries.isEmpty ? null : injuries,
            bio: bio.isEmpty ? null : bio,
          );

      ref.read(hasProfileProvider.notifier).markAsCreated();

      if (mounted) {
        context.go(RoutePaths.hub);
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Minimal segmented progress bar with current step label.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AthlosSpacing.md),
      child: Column(
        children: [
          // Segmented bars
          Row(
            children: List.generate(totalSteps, (index) {
              final isReached = index <= currentStep;

              return Expanded(
                child: AnimatedContainer(
                  duration: AthlosDurations.normal,
                  curve: Curves.easeInOut,
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? AthlosSpacing.sm : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AthlosRadius.xsAll,
                    color: isReached
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                  ),
                ),
              );
            }),
          ),
          const Gap(AthlosSpacing.smd),

          // Current step label
          AnimatedSwitcher(
            duration: AthlosDurations.fast,
            child: Text(
              labels[currentStep],
              key: ValueKey(currentStep),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
