/// Live Activity bridge for rest timer countdown.
///
/// Live Activities are intentionally disabled in this project version.
/// Keep this service as a no-op so the notification fallback remains active.
class RestTimerLiveActivityService {
  RestTimerLiveActivityService._();

  static final RestTimerLiveActivityService instance =
      RestTimerLiveActivityService._();

  bool get supportsPlatform => false;

  Future<bool> upsertCountdown({
    required int remainingSeconds,
    required String title,
    required String subtitle,
  }) async => false;

  Future<void> end({bool dismissImmediately = true}) async {}
}
