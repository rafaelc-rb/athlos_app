import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/data/repositories/local_backup_providers.dart';
import '../../../../core/domain/entities/local_backup_models.dart';
import '../../../../core/errors/result.dart';
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
import '../helpers/profile_l10n.dart';
import '../providers/profile_notifier.dart';
import '../widgets/aesthetic_selector.dart';
import '../widgets/experience_selector.dart';
import '../widgets/goal_selector.dart';
import '../widgets/style_selector.dart';
import '../../../training/presentation/providers/equipment_notifier.dart';
import '../../../training/presentation/providers/exercise_notifier.dart';
import '../../../training/presentation/providers/training_analytics_provider.dart';
import '../../../training/presentation/providers/workout_execution_notifier.dart';
import '../../../training/presentation/providers/workout_notifier.dart';
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
  bool _isExporting = false;
  bool _isImporting = false;

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
      length: _isEditing ? 1 : 4,
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
                    Tab(text: l10n.profileDataTab),
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
                  _buildDataCategory(l10n),
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
    UserProfile profile,
    AppLocalizations l10n,
  ) {
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
                            profile.availableWorkoutMinutes!,
                          )
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

  Widget _buildDataCategory(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: l10n.profileDataSectionTitle),
          const Gap(AthlosSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileDataSectionDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Gap(AthlosSpacing.md),
                  FilledButton.icon(
                    onPressed: _isExporting || _isImporting
                        ? null
                        : () => _exportData(l10n),
                    icon: _isExporting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(l10n.profileDataExportAction),
                  ),
                  const Gap(AthlosSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _isExporting || _isImporting
                        ? null
                        : () => _importData(l10n),
                    icon: _isImporting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(l10n.profileDataImportAction),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(AppLocalizations l10n) async {
    setState(() => _isExporting = true);
    try {
      final useCase = ref.read(exportLocalBackupUseCaseProvider);
      final result = await useCase();
      final exportData = result.getOrThrow();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${exportData.fileName}');
      await file.writeAsString(exportData.jsonContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: l10n.profileDataExportShareText,
        ),
      );
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileDataExportError)));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData(AppLocalizations l10n) async {
    setState(() => _isImporting = true);
    try {
      if (kDebugMode) {
        dev.log('[backup-ui] start file picker', name: 'ProfileScreen');
      }
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (fileResult == null || fileResult.files.isEmpty) return;

      final file = fileResult.files.single;
      if (kDebugMode) {
        dev.log(
          '[backup-ui] selected file: name=${file.name} size=${file.size}',
          name: 'ProfileScreen',
        );
      }
      String? jsonContent;
      if (file.bytes != null) {
        jsonContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        jsonContent = await File(file.path!).readAsString();
      }
      if (jsonContent == null) {
        throw const FormatException('Selected file is empty.');
      }

      final previewUseCase = ref.read(previewLocalBackupImportUseCaseProvider);
      if (kDebugMode) {
        dev.log('[backup-ui] preview import', name: 'ProfileScreen');
      }
      final previewResult = await previewUseCase(jsonContent);
      final preview = previewResult.getOrThrow();
      if (kDebugMode) {
        dev.log(
          '[backup-ui] preview done: conflicts=${preview.conflicts.length} '
          'pending=${preview.pendingReviews.length} total=${preview.totalRecords}',
          name: 'ProfileScreen',
        );
      }

      final resolutions = <String, BackupConflictResolution>{};
      for (final conflict in preview.conflicts) {
        if (!mounted) return;
        final selected = await _showConflictDialog(conflict, l10n);
        if (selected == null) return;
        resolutions[conflict.conflictId] = selected;
      }

      final pendingResolutions = <String, BackupPendingReviewResolution>{};
      for (final review in preview.pendingReviews) {
        if (!mounted) return;
        final selected = await _showPendingReviewDialog(review, l10n);
        if (selected == null) return;
        pendingResolutions[review.reviewId] = selected;
      }

      if (!mounted) return;
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.profileDataImportConfirmTitle),
              content: Text(
                l10n.profileDataImportConfirmMessage(preview.totalRecords),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.profileDataImportAction),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      final importUseCase = ref.read(importLocalBackupUseCaseProvider);
      if (kDebugMode) {
        dev.log('[backup-ui] execute import', name: 'ProfileScreen');
      }
      final importResult = await importUseCase(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: resolutions,
          pendingReviewResolutions: pendingResolutions,
        ),
      );
      final report = importResult.getOrThrow();
      if (kDebugMode) {
        dev.log(
          '[backup-ui] import done: created=${report.createdCount} '
          'updated=${report.updatedCount} skipped=${report.skippedCount} '
          'failed=${report.failedCount}',
          name: 'ProfileScreen',
        );
      }

      // Refresh all affected read models so the app reflects imported data
      // immediately without requiring a full restart.
      ref.invalidate(profileProvider);
      ref.invalidate(workoutListProvider);
      ref.invalidate(archivedWorkoutListProvider);
      ref.invalidate(lastFinishedWorkoutIdProvider);
      ref.invalidate(workoutExecutionListProvider);
      ref.invalidate(exerciseListProvider);
      ref.invalidate(exerciseEquipmentMapProvider);
      ref.invalidate(equipmentListProvider);
      ref.invalidate(userEquipmentIdsProvider);
      ref.invalidate(cycleStepsProvider);
      ref.invalidate(effectiveCycleStepsProvider);
      ref.invalidate(cycleListItemsProvider);
      ref.invalidate(nextCycleStepProvider);
      ref.invalidate(nextWorkoutToStartProvider);
      ref.invalidate(nextCycleStepIndexProvider);
      ref.invalidate(executionStreakProvider);
      ref.invalidate(trainingHomeAnalyticsProvider);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.profileDataImportResultTitle),
          content: Text(
            l10n.profileDataImportResultMessage(
              report.createdCount,
              report.updatedCount,
              report.skippedCount,
              report.failedCount,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.okButton),
            ),
          ],
        ),
      );
    } on Exception catch (e, stackTrace) {
      final debugMessage = '[backup-ui] import flow exception: ${e.toString()}';
      debugPrint(debugMessage);
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[backup-ui] import flow stacktrace',
      );
      if (kDebugMode) {
        dev.log(
          debugMessage,
          name: 'ProfileScreen',
          error: e,
          stackTrace: stackTrace,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode
                ? '${l10n.profileDataImportError}\n${e.toString()}'
                : l10n.profileDataImportError,
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<BackupConflictResolution?> _showConflictDialog(
    BackupImportConflict conflict,
    AppLocalizations l10n,
  ) {
    return showDialog<BackupConflictResolution>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profileDataConflictTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileDataConflictType(
                  _conflictTypeLabel(conflict, l10n),
                ),
              ),
              const Gap(AthlosSpacing.sm),
              Text(l10n.profileDataConflictExisting(conflict.existingLabel)),
              Text(l10n.profileDataConflictImported(conflict.importedLabel)),
            ],
          ),
          actions: [
            for (final resolution in conflict.allowedResolutions)
              TextButton(
                onPressed: () => Navigator.of(context).pop(resolution),
                child: Text(_resolutionLabel(resolution, l10n)),
              ),
          ],
        );
      },
    );
  }

  Future<BackupPendingReviewResolution?> _showPendingReviewDialog(
    BackupPendingReview review,
    AppLocalizations l10n,
  ) {
    final suggestionText = review.suggestedLabel != null
        ? l10n.profileDataPendingSuggested(
            review.suggestedLabel!,
            review.similarityScore?.toStringAsFixed(2) ?? '-',
          )
        : l10n.profileDataPendingNoSuggestion;

    return showDialog<BackupPendingReviewResolution>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profileDataPendingTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileDataPendingType(_pendingTypeLabel(review, l10n)),
              ),
              const Gap(AthlosSpacing.sm),
              Text(l10n.profileDataPendingImported(review.importedLabel)),
              if (review.existingLabel != null)
                Text(l10n.profileDataPendingExisting(review.existingLabel!)),
              Text(suggestionText),
            ],
          ),
          actions: [
            if (review.type != BackupPendingReviewType.governanceConflict &&
                review.suggestedLabel != null)
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(BackupPendingReviewResolution.linkSuggested),
                child: Text(l10n.profileDataPendingLinkSuggested),
              ),
            if (review.type != BackupPendingReviewType.governanceConflict)
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(BackupPendingReviewResolution.createCustom),
                child: Text(l10n.profileDataPendingCreateCustom),
              ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(BackupPendingReviewResolution.skip),
              child: Text(l10n.profileDataPendingSkip),
            ),
          ],
        );
      },
    );
  }

  String _pendingTypeLabel(BackupPendingReview review, AppLocalizations l10n) {
    final entityLabel = _conflictTypeFromEnum(review.entityType, l10n);

    return switch (review.type) {
      BackupPendingReviewType.missingCanonicalReference =>
        l10n.profileDataPendingMissingCanonical(entityLabel),
      BackupPendingReviewType.fuzzyMatchCandidate =>
        l10n.profileDataPendingFuzzy(entityLabel),
      BackupPendingReviewType.verifiedVsCustomConfirmation =>
        l10n.profileDataPendingVerifiedVsCustom(entityLabel),
      BackupPendingReviewType.governanceConflict =>
        l10n.profileDataPendingGovernance(entityLabel),
    };
  }

  String _conflictTypeLabel(
    BackupImportConflict conflict,
    AppLocalizations l10n,
  ) {
    return _conflictTypeFromEnum(conflict.type, l10n);
  }

  String _conflictTypeFromEnum(BackupConflictType type, AppLocalizations l10n) {
    return switch (type) {
      BackupConflictType.profile => l10n.profile,
      BackupConflictType.equipment => l10n.profileEquipmentTab,
      BackupConflictType.exercise => l10n.tabExercises,
      BackupConflictType.workout => l10n.tabWorkouts,
    };
  }

  String _resolutionLabel(
    BackupConflictResolution resolution,
    AppLocalizations l10n,
  ) {
    return switch (resolution) {
      BackupConflictResolution.keepExisting =>
        l10n.profileDataConflictKeepExisting,
      BackupConflictResolution.overwriteExisting =>
        l10n.profileDataConflictOverwrite,
      BackupConflictResolution.keepBoth => l10n.profileDataConflictKeepBoth,
    };
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
              decoration: InputDecoration(labelText: l10n.nameLabel),
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(AthlosSpacing.md),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: l10n.weightLabel,
                suffixText: l10n.weightUnit,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            Text(l10n.profileGender, style: textTheme.titleMedium),
            Wrap(
              spacing: AthlosSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(l10n.genderMale),
                  selected: _selectedGender == Gender.male,
                  onSelected: (_) =>
                      setState(() => _selectedGender = Gender.male),
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
              onSelected: (style) => setState(() => _selectedStyle = style),
            ),
            const Gap(AthlosSpacing.md),
            ExperienceSelector(
              selected: _selectedExperience,
              onSelected: (level) =>
                  setState(() => _selectedExperience = level),
            ),
            const Gap(AthlosSpacing.lg),
            Text(
              l10n.trainingFrequencyLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: (_trainingFrequency ?? 3).toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '${_trainingFrequency ?? 3}x',
              onChanged: (v) => setState(() => _trainingFrequency = v.round()),
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
              onChanged: (v) =>
                  setState(() => _availableWorkoutMinutes = v ? 60 : null),
            ),
            if (_availableWorkoutMinutes != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (_availableWorkoutMinutes!.toDouble()).clamp(
                        30,
                        120,
                      ),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.genericError)),
        );
      }
    }
  }

  String _goalLabel(TrainingGoal goal, AppLocalizations l10n) =>
      localizedTrainingGoalName(goal, l10n);

  String _aestheticLabel(BodyAesthetic aesthetic, AppLocalizations l10n) =>
      localizedBodyAestheticName(aesthetic, l10n);

  String _styleLabel(TrainingStyle style, AppLocalizations l10n) =>
      localizedTrainingStyleName(style, l10n);

  String _experienceLabel(ExperienceLevel level, AppLocalizations l10n) =>
      localizedExperienceLevelName(level, l10n);

  String _genderLabel(Gender gender, AppLocalizations l10n) =>
      localizedGenderName(gender, l10n);
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
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
