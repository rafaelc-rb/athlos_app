import 'package:flutter/material.dart';

import '../../../../core/theme/athlos_custom_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Returns a color reflecting how far [actual] reps deviate from the
/// planned range [minPlanned]..[maxPlanned].
///
/// For AMRAP, anything at or above [minPlanned] is on-target.
Color? repsDeviationColor(
  ColorScheme cs,
  AthlosCustomColors custom,
  int actual,
  int minPlanned,
  int maxPlanned,
  bool isAmrap,
) {
  if (isAmrap) {
    final below = minPlanned - actual;
    if (below >= 4) return cs.error;
    if (below >= 2) return custom.warning;
    return null;
  }
  if (actual >= minPlanned && actual <= maxPlanned) return null;
  final diff = actual < minPlanned
      ? minPlanned - actual
      : actual - maxPlanned;
  if (diff >= 4) return cs.error;
  if (diff >= 2) return custom.warning;
  return null;
}

/// Feedback about load adjustment based on aggregate rep performance
/// across completed sets.
///
/// Returns null when performance is in the ideal zone.
({String message, Color color})? loadFeedback({
  required ColorScheme cs,
  required AthlosCustomColors custom,
  required AppLocalizations l10n,
  required List<int> completedReps,
  required int minReps,
  required int maxReps,
  required bool isAmrap,
}) {
  if (completedReps.isEmpty) return null;

  final avg = completedReps.reduce((a, b) => a + b) / completedReps.length;

  if (avg < minReps - 3) {
    return (message: l10n.executionFeedbackWeightTooHigh, color: cs.error);
  }
  if (avg < minReps - 1) {
    return (
      message: l10n.executionFeedbackWeightSlightlyHigh,
      color: custom.warning,
    );
  }

  if (isAmrap) return null;

  if (avg > maxReps + 3) {
    return (message: l10n.executionFeedbackWeightTooLight, color: cs.error);
  }
  if (avg > maxReps + 1) {
    return (
      message: l10n.executionFeedbackWeightTooLight,
      color: custom.warning,
    );
  }
  return null;
}
