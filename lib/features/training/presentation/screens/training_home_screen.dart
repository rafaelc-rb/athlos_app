import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/execution_comparison.dart';
import '../../domain/enums/muscle_group.dart';
import '../helpers/duration_format.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/equipment_notifier.dart';
import '../providers/exercise_notifier.dart';
import '../providers/training_analytics_provider.dart';
import '../providers/training_metrics_provider.dart';
import '../../../profile/presentation/providers/body_metric_notifier.dart';
import '../../../profile/presentation/providers/profile_notifier.dart'
    show profileProvider;

/// Training module — Dashboard tab with two inner sub-tabs:
/// "Visão Geral" (overview metrics) and "Catálogos" (exercises + equipment).
class TrainingHomeScreen extends StatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  State<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: [
            Tab(text: l10n.dashboardOverviewTab),
            Tab(text: l10n.dashboardCatalogsTab),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _OverviewSubTab(),
              _CatalogsSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-tab: Visão Geral ─────────────────────────────────────────────

class _OverviewSubTab extends ConsumerWidget {
  const _OverviewSubTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WeightPromptBanner(),
          _StatPillsRow(l10n: l10n),
          const Gap(AthlosSpacing.md),
          const _WeeklyVolumeCard(),
          const Gap(AthlosSpacing.sm),
          const _RecentPRCard(),
          const Gap(AthlosSpacing.lg),
          _EvolutionCard(l10n: l10n),
        ],
      ),
    );
  }
}

// ── Stat pills (streak + this week) ──────────────────────────────────

class _StatPillsRow extends ConsumerWidget {
  final AppLocalizations l10n;

  const _StatPillsRow({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final streakAsync = ref.watch(executionStreakProvider);
    final thisWeekAsync = ref.watch(thisWeekSessionCountProvider);
    final profileAsync = ref.watch(profileProvider);
    final trainingFrequency = profileAsync.value?.trainingFrequency;

    final streak = streakAsync.value ?? 0;
    final thisWeek = thisWeekAsync.value ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.local_fire_department,
            iconColor: streak > 0 ? colorScheme.error : colorScheme.onSurfaceVariant,
            label: l10n.dashboardStreakLabel,
            value: l10n.dashboardStreakDays(streak),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ),
        const Gap(AthlosSpacing.sm),
        Expanded(
          child: _StatPill(
            icon: Icons.calendar_today,
            iconColor: colorScheme.primary,
            label: l10n.dashboardThisWeekLabel,
            value: trainingFrequency != null
                ? l10n.dashboardThisWeekProgress(thisWeek, trainingFrequency)
                : l10n.dashboardThisWeekCount(thisWeek),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AthlosSpacing.md,
          vertical: AthlosSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const Gap(AthlosSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(value, style: textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-tab: Catálogos ───────────────────────────────────────────────

class _CatalogsSubTab extends ConsumerWidget {
  const _CatalogsSubTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final equipmentAsync = ref.watch(equipmentListProvider);
    final equipmentCount = equipmentAsync.value?.length ?? 0;

    final exercisesAsync = ref.watch(exerciseListProvider);
    final exerciseCount = exercisesAsync.value?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        children: [
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

// ── Weekly Volume with targets ───────────────────────────────────────

class _WeeklyVolumeCard extends ConsumerWidget {
  const _WeeklyVolumeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final volumeAsync = ref.watch(weeklyVolumePerMuscleGroupProvider);
    final profileAsync = ref.watch(profileProvider);
    final experienceLevel = profileAsync.value?.experienceLevel?.name;
    final target = volumeTargetForLevel(experienceLevel);

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
            onTap: () => context.push(RoutePaths.trainingVolumeTrend),
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
                      Text(
                        l10n.dashboardVolumeTargetRange(target.min, target.max),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AthlosSpacing.xs),
                      Icon(Icons.chevron_right,
                          size: 20, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  const Gap(AthlosSpacing.sm),
                  ...sorted.map((e) {
                    final group = MuscleGroup.values
                        .where((g) => g.name == e.key)
                        .firstOrNull;
                    final label = group != null
                        ? localizedMuscleGroupName(group, l10n)
                        : e.key;
                    return _VolumeRow(
                      label: label,
                      sets: e.value,
                      targetMin: target.min,
                      targetMax: target.max,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final String label;
  final int sets;
  final int targetMin;
  final int targetMax;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _VolumeRow({
    required this.label,
    required this.sets,
    required this.targetMin,
    required this.targetMax,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (sets / targetMax).clamp(0.0, 1.0);
    final statusColor = sets < targetMin
        ? colorScheme.error
        : sets > targetMax
            ? colorScheme.tertiary
            : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AthlosSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(AthlosSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: statusColor,
              ),
            ),
          ),
          const Gap(AthlosSpacing.sm),
          SizedBox(
            width: 28,
            child: Text(
              '$sets',
              style: textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent PR Card ───────────────────────────────────────────────────

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
            onTap: () => context.push(RoutePaths.trainingPRHistory),
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
                        Text(l10n.prBadge, style: textTheme.titleSmall),
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

// ── Evolution Card ───────────────────────────────────────────────────

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
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                        ),
                        const Gap(AthlosSpacing.xs),
                        Text(
                          _deltaText(c),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: c.volumeDelta > 0
                                        ? Theme.of(context).colorScheme.primary
                                        : c.volumeDelta < 0
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
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
      error: (_, _) => const SizedBox.shrink(),
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

// ── Catalog Card ─────────────────────────────────────────────────────

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

// ── Weight Prompt Banner ─────────────────────────────────────────────

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
                      style:
                          TextStyle(color: colorScheme.onTertiaryContainer),
                    ),
                  ),
                  const Gap(AthlosSpacing.xs),
                  TextButton(
                    onPressed: () => setState(() => _dismissed = true),
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
