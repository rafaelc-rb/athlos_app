/// How volume/intensity is reduced during a deload period.
enum DeloadStrategy {
  /// Same weight, fewer sets.
  reduceVolume,

  /// Same sets/reps, lighter weight.
  reduceIntensity,

  /// Fewer sets + lighter weight.
  reduceBoth,
}
