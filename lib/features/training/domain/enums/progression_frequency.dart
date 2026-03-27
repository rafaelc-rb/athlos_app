/// How often a progression rule is evaluated.
enum ProgressionFrequency {
  /// Evaluate after every session that includes the exercise.
  everySession,

  /// Evaluate after a full cycle rotation completes.
  everyRotation,
}
