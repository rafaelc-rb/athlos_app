import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_radius.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/execution_comparison.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/enums/program_focus.dart';
import '../helpers/duration_format.dart';
import '../providers/equipment_notifier.dart';
import '../providers/exercise_notifier.dart';
import '../providers/program_notifier.dart';
import '../../domain/enums/muscle_group.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/training_analytics_provider.dart';
import '../providers/training_metrics_provider.dart';
import '../providers/workout_notifier.dart';
import '../../../profile/presentation/providers/body_metric_notifier.dart';

/// Training module — Home / Dashboard tab.
class TrainingHomeScreen extends ConsumerWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final equipmentAsync = ref.watch(equipmentListProvider);
    final equipmentCount = equipmentAsync.value?.length ?? 0;

    final exercisesAsync = ref.watch(exerciseListProvider);
    final exerciseCount = exercisesAsync.value?.length ?? 0;

    final analyticsAsync = ref.watch(trainingHomeAnalyticsProvider);
    final workoutsAsync = ref.watch(workoutListProvider);
    final streakAsync = ref.watch(executionStreakProvider);

    final activeProgramAsync = ref.watch(activeProgramProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WeightPromptBanner(),

          // Active program card
          _ActiveProgramCard(activeProgramAsync: activeProgramAsync),
          const Gap(AthlosSpacing.md),

          const _WeeklyVolumeCard(),
          const Gap(AthlosSpacing.sm),
          const _RecentPRCard(),
          const Gap(AthlosSpacing.md),

          // Summary section (sessions analytics)
          Text(
            l10n.trainingSummarySection,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AthlosSpacing.sm),
          analyticsAsync.when(
            data: (analytics) {
              final workouts = workoutsAsync.value ?? [];
              final nameById = {for (final w in workouts) w.id: w.name};
              return _SummaryCard(
                analytics: analytics,
                nameById: nameById,
                streak: streakAsync.value,
                l10n: l10n,
                textTheme: textTheme,
                colorScheme: colorScheme,
              );
            },
            loading: () => Skeletonizer(
              enabled: true,
              child: _SummaryCard(
                analytics: const TrainingHomeAnalytics(
                  sessionsByActiveWorkoutId: {},
                  archivedSessionsTotal: 0,
                  totalSessions: 0,
                ),
                nameById: const {},
                streak: null,
                l10n: l10n,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ),
            error: (err, stackTrace) => const SizedBox.shrink(),
          ),
          const Gap(AthlosSpacing.lg),

          // Evolution card (last vs previous for last executed workout)
          _EvolutionCard(l10n: l10n),

          const Gap(AthlosSpacing.lg),

          // Catalogs section
          Text(
            l10n.catalogsSection,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AthlosSpacing.sm),

          _CatalogCard(
            icon: Icons.sports_gymnastics,
            title: l10n.exercisesCatalog,
            subtitle: exerciseCount > 0
                ? l10n.exercisesCount(exerciseCount)
                : l10n.exercisesCatalogDesc,
            onTap: () => context.go(RoutePaths.trainingExercises),
          ),
          const Gap(AthlosSpacing.sm),

          _CatalogCard(
            icon: Icons.handyman,
            title: l10n.equipmentCatalogTitle,
            subtitle: equipmentCount > 0
                ? l10n.equipmentCatalogCount(equipmentCount)
                : l10n.equipmentCatalogDesc,
            onTap: () => context.go(RoutePaths.trainingEquipment),
          ),
        ],
      ),
    );
  }
}

class _EvolutionCard extends ConsumerWidget {
  const _EvolutionCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(lastExecutedWorkoutComparisonProvider);
    return comparisonAsync.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final c = data.comparison;
        final lastDurationSec = c.last.duration?.inSeconds ?? 0;
        final prevDurationSec = c.previous.duration?.inSeconds ?? 0;
        final locale = Localizations.localeOf(context);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(
              '${RoutePaths.trainingHistory}?workoutId=${c.last.workoutId}',
            ),
            child: Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trainingEvolutionRecent,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const Gap(AthlosSpacing.xs),
                  Text(
                    data.workoutName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Gap(AthlosSpacing.sm),
                  _evolutionRow(
                    context,
                    l10n.trainingLastSession,
                    intl.DateFormat.MMMd(locale.toString())
                        .format(c.last.startedAt.toLocal()),
                    formatDuration(lastDurationSec),
                    c.volumeLast,
                  ),
                  const Gap(AthlosSpacing.xs),
                  _evolutionRow(
                    context,
                    l10n.trainingPreviousSession,
                    intl.DateFormat.MMMd(locale.toString())
                        .format(c.previous.startedAt.toLocal()),
                    formatDuration(prevDurationSec),
                    c.volumePrevious,
                  ),
                  if (c.volumeDelta != 0 || c.volumePercentChange != null) ...[
                    const Gap(AthlosSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          c.volumeDelta > 0
                              ? Icons.trending_up
                              : c.volumeDelta < 0
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 16,
                          color: c.volumeDelta > 0
                              ? Theme.of(context).colorScheme.primary
                              : c.volumeDelta < 0
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const Gap(AthlosSpacing.xs),
                        Text(
                          _deltaText(c),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: c.volumeDelta > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : c.volumeDelta < 0
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _evolutionRow(
    BuildContext context,
    String label,
    String date,
    String duration,
    double volume,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '$date · $duration · ${volume.toStringAsFixed(0)} kg',
            style: textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _deltaText(ExecutionComparison comparison) {
    final delta = comparison.volumeDelta;
    final sign = delta > 0
        ? '+'
        : delta < 0
            ? '-'
            : '';
    final percent = comparison.volumePercentChange;

    if (percent != null) {
      final formattedPercent = '$sign${percent.abs().toStringAsFixed(0)}';
      return l10n.trainingVolumePercent(formattedPercent);
    }

    final formattedDelta = '$sign${delta.abs().toStringAsFixed(1)}';
    return l10n.trainingVolumeDelta(formattedDelta);
  }
}

class _SummaryCard extends StatelessWidget {
  final TrainingHomeAnalytics analytics;
  final Map<int, String> nameById;
  final int? streak;
  final AppLocalizations l10n;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _SummaryCard({
    required this.analytics,
    required this.nameById,
    this.streak,
    required this.l10n,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final entries = analytics.sessionsByActiveWorkoutId.entries.toList()
      ..sort((a, b) => (nameById[a.key] ?? '').compareTo(nameById[b.key] ?? ''));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AthlosSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entries.isNotEmpty) ...[
              Text(
                l10n.trainingSessionsPerWorkout,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AthlosSpacing.xs),
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AthlosSpacing.xxs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nameById[e.key] ?? 'Treino #${e.key}',
                          style: textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        l10n.trainingSessionsCount(e.value),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(AthlosSpacing.sm),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.trainingOtherSessions,
                  style: textTheme.bodyMedium,
                ),
                Text(
                  l10n.trainingSessionsCount(analytics.archivedSessionsTotal),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(AthlosSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.trainingTotalSessions,
                  style: textTheme.titleSmall,
                ),
                Text(
                  l10n.trainingSessionsCount(analytics.totalSessions),
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (streak != null && streak! > 0) ...[
              const Gap(AthlosSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.trainingStreakLabel,
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    l10n.trainingStreakCount(streak!),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CatalogCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AthlosSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colorScheme.primary),
              const Gap(AthlosSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const Gap(AthlosSpacing.xs),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveProgramCard extends ConsumerWidget {
  final AsyncValue<TrainingProgram?> activeProgramAsync;

  const _ActiveProgramCard({required this.activeProgramAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return activeProgramAsync.when(
      data: (program) {
        if (program == null) {
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go(RoutePaths.trainingPrograms),
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
                          Text(l10n.programFreeCycleLabel,
                              style: textTheme.titleSmall),
                          const Gap(AthlosSpacing.xxs),
                          Text(
                            l10n.programFreeCycleHint,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        }

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
          child: InkWell(
            onTap: () => context.go(RoutePaths.trainingPrograms),
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
                          avatar: Icon(Icons.spa,
                              size: 16, color: colorScheme.tertiary),
                          label: Text(l10n.deloadActiveChip),
                          backgroundColor: colorScheme.tertiaryContainer,
                          labelStyle: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
                  _ProgramHomeProgress(programId: program.id),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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

class _ProgramHomeProgress extends ConsumerWidget {
  final int programId;

  const _ProgramHomeProgress({required this.programId});

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

class _WeeklyVolumeCard extends ConsumerWidget {
  const _WeeklyVolumeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final volumeAsync = ref.watch(weeklyVolumePerMuscleGroupProvider);

    return volumeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (volume) {
        if (volume.isEmpty) return const SizedBox.shrink();
        final sorted = volume.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                context.push(RoutePaths.trainingVolumeTrend),
            child: Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart,
                          size: 20, color: colorScheme.primary),
                      const Gap(AthlosSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.weeklyVolume,
                          style: textTheme.titleSmall,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 20,
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  const Gap(AthlosSpacing.sm),
                  Wrap(
                    spacing: AthlosSpacing.sm,
                    runSpacing: AthlosSpacing.xs,
                    children: sorted.map((e) {
                      final group = MuscleGroup.values
                          .where((g) => g.name == e.key)
                          .firstOrNull;
                      final label = group != null
                          ? localizedMuscleGroupName(group, l10n)
                          : e.key;
                      return Chip(
                        avatar: Text(
                          '${e.value}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        label: Text(label),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentPRCard extends ConsumerWidget {
  const _RecentPRCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final prsAsync = ref.watch(allExercisePRsProvider);

    return prsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (prs) {
        if (prs.isEmpty) return const SizedBox.shrink();
        final top = prs.first;
        final name = localizedExerciseName(top.exerciseName,
            isVerified: top.isVerified, l10n: l10n);
        final e1rmStr = top.best1RM % 1 == 0
            ? top.best1RM.toInt().toString()
            : top.best1RM.toStringAsFixed(1);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                context.push(RoutePaths.trainingPRHistory),
            child: Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.emoji_events,
                      color: colorScheme.tertiary, size: 24),
                  const Gap(AthlosSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.prBadge,
                            style: textTheme.titleSmall),
                        Text(
                          '$name — $e1rmStr kg',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeightPromptBanner extends ConsumerStatefulWidget {
  const _WeightPromptBanner();

  @override
  ConsumerState<_WeightPromptBanner> createState() =>
      _WeightPromptBannerState();
}

class _WeightPromptBannerState extends ConsumerState<_WeightPromptBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final shouldPrompt = ref.watch(shouldPromptBodyWeightProvider);
    return shouldPrompt.when(
      data: (show) {
        if (!show) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: AthlosSpacing.md),
          child: Card(
            color: colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AthlosSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.monitor_weight_outlined,
                      color: colorScheme.onTertiaryContainer),
                  const Gap(AthlosSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.bodyMetricsWeeklyPromptMessage,
                      style: TextStyle(
                          color: colorScheme.onTertiaryContainer),
                    ),
                  ),
                  const Gap(AthlosSpacing.xs),
                  TextButton(
                    onPressed: () =>
                        setState(() => _dismissed = true),
                    child: Text(l10n.bodyMetricsWeeklyPromptSkip),
                  ),
                  FilledButton(
                    onPressed: () => _showRecordDialog(context),
                    child: Text(l10n.bodyMetricsWeeklyPromptRecord),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showRecordDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weightCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bodyMetricsRecordWeight),
        content: TextField(
          controller: weightCtrl,
          decoration: InputDecoration(
            labelText: l10n.bodyMetricsWeightLabel,
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              final w = double.tryParse(weightCtrl.text.trim());
              if (w == null || w <= 0) return;
              ref
                  .read(bodyMetricListProvider.notifier)
                  .add(weight: w);
              Navigator.pop(ctx);
              setState(() => _dismissed = true);
            },
            child: Text(l10n.bodyMetricsWeeklyPromptRecord),
          ),
        ],
      ),
    );
  }
}
