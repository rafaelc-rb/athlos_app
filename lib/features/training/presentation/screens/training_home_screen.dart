import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../helpers/duration_format.dart';
import '../providers/equipment_notifier.dart';
import '../providers/exercise_notifier.dart';
import '../providers/training_analytics_provider.dart';
import '../providers/workout_notifier.dart';

/// Training module — Home / Dashboard tab.
class TrainingHomeScreen extends ConsumerWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final userIdsAsync = ref.watch(userEquipmentIdsProvider);
    final selectedEquipmentCount = userIdsAsync.value?.length ?? 0;

    final exercisesAsync = ref.watch(exerciseListProvider);
    final exerciseCount = exercisesAsync.value?.length ?? 0;

    final analyticsAsync = ref.watch(trainingHomeAnalyticsProvider);
    final workoutsAsync = ref.watch(workoutListProvider);
    final streakAsync = ref.watch(executionStreakProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            icon: Icons.fitness_center,
            title: l10n.myEquipment,
            subtitle: selectedEquipmentCount > 0
                ? l10n.equipmentSelected(selectedEquipmentCount)
                : l10n.myEquipmentDesc,
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
            onTap: () => context.push(
              '${RoutePaths.trainingWorkouts}/${c.last.workoutId}',
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
                    Text(
                      c.volumeDelta >= 0
                          ? (c.volumePercentChange != null
                              ? l10n.trainingVolumePercent(
                                  c.volumePercentChange!.toStringAsFixed(0))
                              : l10n.trainingVolumeDelta(
                                  c.volumeDelta.toStringAsFixed(1)))
                          : l10n.trainingVolumeDelta(
                              c.volumeDelta.toStringAsFixed(1)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
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
