import '../enums/deload_strategy.dart';

/// Configuration for periodic deload within a training program.
/// Nullable at the program level — programs without it never auto-trigger deload.
class DeloadConfig {
  /// Trigger deload every N rotations. Null means manual-only.
  final int? frequency;

  final DeloadStrategy strategy;

  /// Fraction of sets to keep (e.g. 0.6 = keep 60%).
  final double volumeMultiplier;

  /// Fraction of working weight to use (e.g. 0.5 = 50%).
  final double intensityMultiplier;

  const DeloadConfig({
    this.frequency,
    required this.strategy,
    this.volumeMultiplier = 0.6,
    this.intensityMultiplier = 0.5,
  });
}
