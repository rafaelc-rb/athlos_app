import 'dart:io';

import 'package:flutter/services.dart';

/// iOS-only Live Activity bridge for rest timer countdown.
///
/// On unsupported platforms/versions this service is a no-op and callers
/// should keep regular notification fallbacks.
class RestTimerLiveActivityService {
  RestTimerLiveActivityService._();

  static final RestTimerLiveActivityService instance =
      RestTimerLiveActivityService._();

  static const MethodChannel _channel =
      MethodChannel('athlos/rest_timer_live_activity');

  bool _hasActiveActivity = false;

  bool get supportsPlatform => Platform.isIOS;

  Future<bool> upsertCountdown({
    required int remainingSeconds,
    required String title,
    required String subtitle,
  }) async {
    if (!supportsPlatform || remainingSeconds <= 0) return false;
    final endAtEpochMs =
        DateTime.now().toUtc().add(Duration(seconds: remainingSeconds)).millisecondsSinceEpoch;
    try {
      final updated = await _channel.invokeMethod<bool>(
            'upsert',
            <String, Object?>{
              'title': title,
              'subtitle': subtitle,
              'endAtEpochMs': endAtEpochMs,
            },
          ) ??
          false;
      _hasActiveActivity = updated;
      return updated;
    } on PlatformException {
      _hasActiveActivity = false;
      return false;
    }
  }

  Future<void> end({bool dismissImmediately = true}) async {
    if (!supportsPlatform || !_hasActiveActivity) return;
    try {
      await _channel.invokeMethod<void>(
        'end',
        <String, Object?>{'dismissImmediately': dismissImmediately},
      );
    } on PlatformException {
      // Keep silent fallback behavior.
    } finally {
      _hasActiveActivity = false;
    }
  }
}
