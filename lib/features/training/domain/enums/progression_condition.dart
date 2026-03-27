/// Optional condition that must be met before a progression rule triggers.
/// Null condition means "always progress".
enum ProgressionCondition {
  /// All working sets hit the max reps target.
  hitsMaxReps,

  /// All planned sets were completed.
  completesAllSets,

  /// Average RPE of working sets is below a threshold.
  rpeBelow,
}
