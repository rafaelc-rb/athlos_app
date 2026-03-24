import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../core/widgets/app_bar_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/enums/body_aesthetic.dart';
import '../../domain/enums/experience_level.dart';
import '../../domain/enums/gender.dart';
import '../../domain/enums/training_goal.dart';
import '../../domain/enums/training_style.dart';
import '../providers/profile_notifier.dart';
import '../widgets/aesthetic_selector.dart';
import '../widgets/experience_selector.dart';
import '../widgets/goal_selector.dart';
import '../widgets/style_selector.dart';
import '../../../training/presentation/widgets/equipment_management_body.dart';

/// Profile view/edit screen (P-04).
///
/// Displays the current profile data. Tapping "Edit" switches
/// to edit mode with the same fields as the setup screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _bioController = TextEditingController();
  Gender? _selectedGender;
  TrainingGoal? _selectedGoal;
  BodyAesthetic? _selectedAesthetic;
  TrainingStyle? _selectedStyle;
  ExperienceLevel? _selectedExperience;
  int? _trainingFrequency;
  int? _availableWorkoutMinutes;
  bool? _trainsAtGym;

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

  void _startEditing(UserProfile profile) {
    _nameController.text = profile.name ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _injuriesController.text = profile.injuries ?? '';
    _bioController.text = profile.bio ?? '';
    _selectedGender = profile.gender;
    _selectedGoal = profile.goal;
    _selectedAesthetic = profile.bodyAesthetic;
    _selectedStyle = profile.trainingStyle;
    _selectedExperience = profile.experienceLevel;
    _trainingFrequency = profile.trainingFrequency;
    _availableWorkoutMinutes = profile.availableWorkoutMinutes;
    _trainsAtGym = profile.trainsAtGym;
    setState(() => _isEditing = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);
    final resolved = profileAsync.value ?? const UserProfile(id: 0);

    return DefaultTabController(
      length: _isEditing ? 1 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.profile),
          actions: [const AppBarMenu()],
          bottom: _isEditing
              ? null
              : TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: l10n.profileOverviewTab),
                    Tab(text: l10n.profileTrainingPreferencesTab),
                    Tab(text: l10n.profileEquipmentTab),
                  ],
                ),
        ),
        body: profileAsync.hasError
            ? Center(child: Text(l10n.genericError))
            : _isEditing
                ? _buildEditView(resolved, l10n)
                : TabBarView(
                    children: [
                      Skeletonizer(
                        enabled: profileAsync.isLoading,
                        child: _buildOverviewCategory(resolved, l10n),
                      ),
                      Skeletonizer(
                        enabled: profileAsync.isLoading,
                        child: _buildTrainingPreferencesCategory(resolved, l10n),
                      ),
                      EquipmentManagementBody(
                        onEquipmentTap: (equipment) {
                          context.push(
                            RoutePaths.trainingEquipmentDetail(equipment.id),
                          );
                        },
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildOverviewCategory(UserProfile profile, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar placeholder
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 48,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const Gap(AthlosSpacing.lg),

          // Dados pessoais
          _SectionHeader(title: l10n.profileSectionPersonal),
          const Gap(AthlosSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AthlosSpacing.sm,
                horizontal: AthlosSpacing.md,
              ),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline,
                    label: l10n.profileName,
                    value: profile.name ?? l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.monitor_weight_outlined,
                    label: l10n.profileWeight,
                    value: profile.weight != null
                        ? '${profile.weight} ${l10n.weightUnit}'
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.height,
                    label: l10n.profileHeight,
                    value: profile.height != null
                        ? '${profile.height} ${l10n.heightUnit}'
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.cake_outlined,
                    label: l10n.profileAge,
                    value: profile.age != null
                        ? '${profile.age} ${l10n.yearsUnit}'
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.wc,
                    label: l10n.profileGender,
                    value: profile.gender != null
                        ? _genderLabel(profile.gender!, l10n)
                        : l10n.profileNotSet,
                  ),
                ],
              ),
            ),
          ),
          const Gap(AthlosSpacing.md),

          // Saúde e histórico
          _SectionHeader(title: l10n.profileSectionHealth),
          const Gap(AthlosSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AthlosSpacing.sm,
                horizontal: AthlosSpacing.md,
              ),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.healing,
                    label: l10n.profileInjuries,
                    value: profile.injuries ?? l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.auto_stories,
                    label: l10n.profileBio,
                    value: profile.bio ?? l10n.profileNotSet,
                  ),
                ],
              ),
            ),
          ),
          const Gap(AthlosSpacing.lg),

          FilledButton.icon(
            onPressed: () => _startEditing(profile),
            icon: const Icon(Icons.edit),
            label: Text(l10n.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingPreferencesCategory(
      UserProfile profile, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: l10n.profileSectionTraining),
          const Gap(AthlosSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AthlosSpacing.sm,
                horizontal: AthlosSpacing.md,
              ),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.flag_outlined,
                    label: l10n.profileGoal,
                    value: profile.goal != null
                        ? _goalLabel(profile.goal!, l10n)
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.sports_gymnastics,
                    label: l10n.profileAesthetic,
                    value: profile.bodyAesthetic != null
                        ? _aestheticLabel(profile.bodyAesthetic!, l10n)
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.sync_alt,
                    label: l10n.profileStyle,
                    value: profile.trainingStyle != null
                        ? _styleLabel(profile.trainingStyle!, l10n)
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.trending_up,
                    label: l10n.profileExperience,
                    value: profile.experienceLevel != null
                        ? _experienceLabel(profile.experienceLevel!, l10n)
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.calendar_today,
                    label: l10n.profileFrequency,
                    value: profile.trainingFrequency != null
                        ? '${profile.trainingFrequency}x ${l10n.perWeek}'
                        : l10n.profileNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.timer_outlined,
                    label: l10n.profileAvailableWorkoutMinutes,
                    value: profile.availableWorkoutMinutes != null
                        ? l10n.profileAvailableWorkoutMinutesValue(
                            profile.availableWorkoutMinutes!)
                        : l10n.profileAvailableWorkoutMinutesNotSet,
                  ),
                  _ProfileTile(
                    icon: Icons.store,
                    label: l10n.profileGym,
                    value: profile.trainsAtGym != null
                        ? (profile.trainsAtGym! ? l10n.yes : l10n.no)
                        : l10n.profileNotSet,
                  ),
                ],
              ),
            ),
          ),
          const Gap(AthlosSpacing.lg),
          FilledButton.icon(
            onPressed: () => _startEditing(profile),
            icon: const Icon(Icons.edit),
            label: Text(l10n.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildEditView(UserProfile profile, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: l10n.profileSectionPersonal),
            const Gap(AthlosSpacing.sm),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.nameLabel,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(AthlosSpacing.md),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: l10n.weightLabel,
                suffixText: l10n.weightUnit,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                if (double.tryParse(value) == null) return l10n.invalidNumber;
                return null;
              },
            ),
            const Gap(AthlosSpacing.md),
            TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: l10n.heightLabel,
                suffixText: l10n.heightUnit,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                if (double.tryParse(value) == null) return l10n.invalidNumber;
                return null;
              },
            ),
            const Gap(AthlosSpacing.md),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: l10n.ageLabel,
                suffixText: l10n.yearsUnit,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                if (int.tryParse(value) == null) return l10n.invalidNumber;
                return null;
              },
            ),
            const Gap(AthlosSpacing.md),
            Text(l10n.profileGender,
                style: textTheme.titleMedium),
            Wrap(
              spacing: AthlosSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(l10n.genderMale),
                  selected: _selectedGender == Gender.male,
                  onSelected: (_) => setState(() => _selectedGender = Gender.male),
                ),
                ChoiceChip(
                  label: Text(l10n.genderFemale),
                  selected: _selectedGender == Gender.female,
                  onSelected: (_) =>
                      setState(() => _selectedGender = Gender.female),
                ),
                ChoiceChip(
                  label: Text(l10n.setupChatPreferNotToSay),
                  selected: _selectedGender == null,
                  onSelected: (_) => setState(() => _selectedGender = null),
                ),
              ],
            ),
            const Gap(AthlosSpacing.lg),
            _SectionHeader(title: l10n.profileSectionTraining),
            const Gap(AthlosSpacing.sm),
            GoalSelector(
              selected: _selectedGoal,
              onSelected: (goal) => setState(() => _selectedGoal = goal),
            ),
            const Gap(AthlosSpacing.md),
            AestheticSelector(
              selected: _selectedAesthetic,
              onSelected: (aesthetic) =>
                  setState(() => _selectedAesthetic = aesthetic),
            ),
            const Gap(AthlosSpacing.md),
            StyleSelector(
              selected: _selectedStyle,
              onSelected: (style) =>
                  setState(() => _selectedStyle = style),
            ),
            const Gap(AthlosSpacing.md),
            ExperienceSelector(
              selected: _selectedExperience,
              onSelected: (level) =>
                  setState(() => _selectedExperience = level),
            ),
            const Gap(AthlosSpacing.lg),
            Text(l10n.trainingFrequencyLabel,
                style: Theme.of(context).textTheme.titleMedium),
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
              child: Text('${_trainingFrequency ?? 3} ${l10n.daysPerWeek}'),
            ),
            const Gap(AthlosSpacing.md),
            SwitchListTile(
              title: Text(l10n.profileAvailableWorkoutMinutesLabel),
              subtitle: Text(
                l10n.profileAvailableWorkoutMinutesHint,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              value: _availableWorkoutMinutes != null,
              onChanged: (v) => setState(() =>
                  _availableWorkoutMinutes = v ? 60 : null),
            ),
            if (_availableWorkoutMinutes != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (_availableWorkoutMinutes!.toDouble())
                          .clamp(30, 120),
                      min: 30,
                      max: 120,
                      divisions: 6,
                      label: '$_availableWorkoutMinutes min',
                      onChanged: (v) =>
                          setState(() => _availableWorkoutMinutes = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_availableWorkoutMinutes min',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            const Gap(AthlosSpacing.md),
            SwitchListTile(
              title: Text(l10n.trainsAtGymLabel),
              value: _trainsAtGym ?? false,
              onChanged: (v) => setState(() => _trainsAtGym = v),
            ),
            const Gap(AthlosSpacing.lg),
            _SectionHeader(title: l10n.profileSectionHealth),
            const Gap(AthlosSpacing.sm),
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
            const Gap(AthlosSpacing.md),
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
            const Gap(AthlosSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const Gap(AthlosSpacing.smd),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _saveChanges(profile),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(UserProfile profile) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final injuries = _injuriesController.text.trim();
    final bio = _bioController.text.trim();
    final updated = UserProfile(
      id: profile.id,
      name: name.isEmpty ? null : name,
      weight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      goal: _selectedGoal,
      bodyAesthetic: _selectedAesthetic,
      trainingStyle: _selectedStyle,
      experienceLevel: _selectedExperience,
      trainingFrequency: _trainingFrequency,
      availableWorkoutMinutes: _availableWorkoutMinutes,
      trainsAtGym: _trainsAtGym,
      injuries: injuries.isEmpty ? null : injuries,
      bio: bio.isEmpty ? null : bio,
      lastActiveModule: profile.lastActiveModule,
    );

    try {
      await ref.read(profileProvider.notifier).updateProfile(updated);
      if (mounted) {
        setState(() => _isEditing = false);
      }
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericError),
          ),
        );
      }
    }
  }

  String _goalLabel(TrainingGoal goal, AppLocalizations l10n) => switch (goal) {
        TrainingGoal.hypertrophy => l10n.goalHypertrophy,
        TrainingGoal.weightLoss => l10n.goalWeightLoss,
        TrainingGoal.endurance => l10n.goalEndurance,
        TrainingGoal.strength => l10n.goalStrength,
        TrainingGoal.generalFitness => l10n.goalGeneralFitness,
      };

  String _aestheticLabel(BodyAesthetic aesthetic, AppLocalizations l10n) =>
      switch (aesthetic) {
        BodyAesthetic.athletic => l10n.aestheticAthletic,
        BodyAesthetic.bulky => l10n.aestheticBulky,
        BodyAesthetic.robust => l10n.aestheticRobust,
      };

  String _styleLabel(TrainingStyle style, AppLocalizations l10n) =>
      switch (style) {
        TrainingStyle.traditional => l10n.styleTraditional,
        TrainingStyle.calisthenics => l10n.styleCalisthenics,
        TrainingStyle.functional => l10n.styleFunctional,
        TrainingStyle.hybrid => l10n.styleHybrid,
      };

  String _experienceLabel(ExperienceLevel level, AppLocalizations l10n) =>
      switch (level) {
        ExperienceLevel.beginner => l10n.experienceBeginner,
        ExperienceLevel.intermediate => l10n.experienceIntermediate,
        ExperienceLevel.advanced => l10n.experienceAdvanced,
      };

  String _genderLabel(Gender gender, AppLocalizations l10n) => switch (gender) {
        Gender.male => l10n.genderMale,
        Gender.female => l10n.genderFemale,
      };
}

/// Section title in profile (read and edit views).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A single profile data row.
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AthlosSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const Gap(AthlosSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
