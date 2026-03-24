import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Handles local notifications for the workout rest timer lifecycle.
class RestTimerNotificationService {
  RestTimerNotificationService._();

  static final RestTimerNotificationService instance =
      RestTimerNotificationService._();

  static const int _restTimerNotificationId = 42001;
  static const String _silentChannelId = 'rest_timer_silent';
  static const String _silentChannelName = 'Rest timer (silent)';
  static const String _silentChannelDescription =
      'Silent countdown while app is in background';
  static const String _alertChannelId = 'rest_timer_alert';
  static const String _alertChannelName = 'Rest timer alerts';
  static const String _alertChannelDescription =
      'Alerts when rest timer finishes';
  static const _athlosPrimaryColor = Color(0xFF6917B5);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isUnavailable = false;

  Future<bool> init() async {
    if (_isUnavailable) return false;
    if (_isInitialized) return true;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_athlos'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    try {
      await _plugin.initialize(settings: initializationSettings);

      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _silentChannelId,
          _silentChannelName,
          description: _silentChannelDescription,
          importance: Importance.low,
          playSound: false,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _alertChannelId,
          _alertChannelName,
          description: _alertChannelDescription,
          importance: Importance.high,
        ),
      );
    } on PlatformException {
      _isUnavailable = true;
      return false;
    }

    _isInitialized = true;
    return true;
  }

  Future<void> showOngoingRest({
    required String title,
    required String body,
  }) async {
    if (!await init()) return;
    await _plugin.show(
      id: _restTimerNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _silentChannelId,
          _silentChannelName,
          channelDescription: _silentChannelDescription,
          icon: 'ic_stat_athlos',
          color: _athlosPrimaryColor,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          silent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentSound: false,
          presentBadge: false,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: false,
          presentSound: false,
          presentBadge: false,
        ),
      ),
    );
  }

  Future<void> showRestFinished({
    required String title,
    required String body,
  }) async {
    if (!await init()) return;
    await _plugin.show(
      id: _restTimerNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          channelDescription: _alertChannelDescription,
          icon: 'ic_stat_athlos',
          color: _athlosPrimaryColor,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ongoing: false,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
    );
  }

  Future<void> cancelAllForRestTimer() async {
    await _plugin.cancel(id: _restTimerNotificationId);
  }
}
