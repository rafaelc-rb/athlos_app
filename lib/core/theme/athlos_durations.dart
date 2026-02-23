/// Animation duration tokens for consistent motion across the app.
///
/// Usage: `AnimatedContainer(duration: AthlosDurations.normal)`
abstract class AthlosDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
