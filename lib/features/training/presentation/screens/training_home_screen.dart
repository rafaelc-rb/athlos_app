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

// ── Stat pills (frequency + cycle) ───────────────────────────────────

class _StatPillsRow extends ConsumerWidget {
  final AppLocalizations l10n;

  const _StatPillsRow({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _FrequencyPill(l10n: l10n)),
          const Gap(AthlosSpacing.sm),
          Expanded(child: _CycleStreakPill(l10n: l10n)),
        ],
      ),
    );
  }
}

class _FrequencyPill extends ConsumerWidget {
  final AppLocalizations l10n;

  const _FrequencyPill({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final thisWeek = ref.watch(thisWeekSessionCountProvider).value ?? 0;
    final profileAsync = ref.watch(profileProvider);
    final target =
        profileAsync.value?.trainingFrequency ?? kDefaultTrainingFrequency;
    final consistencyStreak =
        ref.watch(consistencyStreakProvider).value ?? 0;

    final dotCount = thisWeek > target ? thisWeek : target;

    return Tooltip(
      message: l10n.dashboardConsistencyTooltip(target),
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AthlosSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: colorScheme.primary),
                  const Gap(AthlosSpacing.xs),
                  Text(
                    l10n.dashboardFrequencyTitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Gap(AthlosSpacing.sm),
              Row(
                children: [
                  ...List.generate(dotCount, (i) {
                    final isFilled = i < thisWeek;
                    return Padding(
                      padding:
                          const EdgeInsets.only(right: AthlosSpacing.xxs),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    );
                  }),
                  const Gap(AthlosSpacing.xs),
                  Text(
                    l10n.dashboardFrequencyProgress(thisWeek, target),
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
              const Gap(AthlosSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 14,
                    color: consistencyStreak > 0
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                  const Gap(AthlosSpacing.xxs),
                  Text(
                    l10n.dashboardConsistencyStreak(consistencyStreak),
                    style: textTheme.bodySmall?.copyWith(
                      color: consistencyStreak > 0
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CycleStreakPill extends ConsumerWidget {
  final AppLocalizations l10n;

  const _CycleStreakPill({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final cycleStreak = ref.watch(executionStreakProvider).value ?? 0;
    final isActive = cycleStreak > 0;

    return Tooltip(
      message: l10n.dashboardCycleTooltip,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AthlosSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: colorScheme.primary),
                  const Gap(AthlosSpacing.xs),
                  Text(
                    l10n.dashboardCycleTitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 20,
                    color: isActive
                        ? const Color(0xFFD4AF37)
                        : colorScheme.onSurfaceVariant,
                  ),
                  const Gap(AthlosSpacing.xs),
                  Text(
                    l10n.dashboardCycleStreakCount(cycleStreak),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  static const _volumeGood = Color(0xFF4CAF50);
  static const _volumeOver = Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    final fraction = (sets / targetMax).clamp(0.0, 1.0);
    final statusColor = sets < targetMin
        ? colorScheme.error
        : sets > targetMax
            ? _volumeOver
            : _volumeGood;

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
