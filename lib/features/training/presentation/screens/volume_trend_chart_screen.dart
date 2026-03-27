import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/muscle_group.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/training_metrics_provider.dart';

/// Bar chart showing weekly volume (working sets) per muscle group over time.
class VolumeTrendChartScreen extends ConsumerStatefulWidget {
  const VolumeTrendChartScreen({super.key});

  @override
  ConsumerState<VolumeTrendChartScreen> createState() =>
      _VolumeTrendChartScreenState();
}

class _VolumeTrendChartScreenState
    extends ConsumerState<VolumeTrendChartScreen> {
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final trendAsync = ref.watch(weeklyVolumeTrendProvider());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.volumeTrendTitle)),
      body: trendAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            Center(child: Text(l10n.genericError)),
        data: (trend) {
          if (trend.isEmpty) {
            return Center(
              child: Text(
                l10n.bodyMetricsNoData,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final groups = trend.keys.toList()..sort();
          final selected = _selectedGroup ?? groups.first;
          final points = trend[selected] ?? [];

          return Padding(
            padding: const EdgeInsets.all(AthlosSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: groups
                        .map((g) => Padding(
                              padding: const EdgeInsets.only(
                                  right: AthlosSpacing.xs),
                              child: ChoiceChip(
                                label: Text(
                                    _muscleGroupLabel(g, l10n)),
                                selected: g == selected,
                                onSelected: (_) =>
                                    setState(() => _selectedGroup = g),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const Gap(AthlosSpacing.lg),
                Expanded(
                  child: points.length < 2
                      ? Center(
                          child: Text(l10n.bodyMetricsNoData,
                              style: textTheme.bodyMedium),
                        )
                      : _buildBarChart(
                          points, selected, colorScheme, textTheme),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChart(
    List<({DateTime weekStart, int sets})> points,
    String muscleGroup,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final dateFormat = intl.DateFormat.MMMd();
    final maxSets = points.map((p) => p.sets).reduce((a, b) => a > b ? a : b);
    final target = volumeTargetForLevel(null);

    return BarChart(
      BarChartData(
        barGroups: points.asMap().entries.map((e) {
          final sets = e.value.sets;
          Color barColor;
          if (sets < target.min) {
            barColor = colorScheme.error.withValues(alpha: 0.7);
          } else if (sets > target.max) {
            barColor = colorScheme.tertiary.withValues(alpha: 0.7);
          } else {
            barColor = colorScheme.primary;
          }
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: sets.toDouble(),
                color: barColor,
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    dateFormat.format(points[idx].weekStart),
                    style: textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        maxY: (maxSets + 2).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: target.min.toDouble(),
              color: colorScheme.primary.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
            HorizontalLine(
              y: target.max.toDouble(),
              color: colorScheme.tertiary.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
          ],
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final p = points[group.x];
              return BarTooltipItem(
                '${dateFormat.format(p.weekStart)}\n${p.sets} sets',
                TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _muscleGroupLabel(String name, AppLocalizations l10n) {
  final group =
      MuscleGroup.values.where((g) => g.name == name).firstOrNull;
  if (group != null) return localizedMuscleGroupName(group, l10n);
  return name;
}
