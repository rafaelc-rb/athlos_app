import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'body_metric_notifier.dart';

part 'body_metrics_dashboard_provider.g.dart';

const _staleThresholdDays = 7;

enum BodyMetricsDashboardStatus { empty, stale, upToDate }

class BodyMetricsDashboardState {
  final BodyMetricsDashboardStatus status;
  final double? latestWeight;
  final double? latestBodyFat;
  final double? weightDelta;
  final double? bodyFatDelta;
  final int daysSinceLastEntry;

  const BodyMetricsDashboardState({
    required this.status,
    this.latestWeight,
    this.latestBodyFat,
    this.weightDelta,
    this.bodyFatDelta,
    this.daysSinceLastEntry = 0,
  });
}

@riverpod
Future<BodyMetricsDashboardState> bodyMetricsDashboard(Ref ref) async {
  final metrics = await ref.watch(bodyMetricListProvider.future);

  if (metrics.isEmpty) {
    return const BodyMetricsDashboardState(
      status: BodyMetricsDashboardStatus.empty,
    );
  }

  final latest = metrics.first;
  final daysSince = DateTime.now().difference(latest.recordedAt).inDays;

  double? weightDelta;
  double? bodyFatDelta;

  if (metrics.length >= 2) {
    final previous = metrics[1];
    weightDelta = latest.weight - previous.weight;
    if (latest.bodyFatPercent != null && previous.bodyFatPercent != null) {
      bodyFatDelta = latest.bodyFatPercent! - previous.bodyFatPercent!;
    }
  }

  return BodyMetricsDashboardState(
    status: daysSince >= _staleThresholdDays
        ? BodyMetricsDashboardStatus.stale
        : BodyMetricsDashboardStatus.upToDate,
    latestWeight: latest.weight,
    latestBodyFat: latest.bodyFatPercent,
    weightDelta: weightDelta,
    bodyFatDelta: bodyFatDelta,
    daysSinceLastEntry: daysSince,
  );
}
