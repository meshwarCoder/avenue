import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../utils/observability.dart';

/// Local Notification Service for Android 7+ (supports Android 13+ runtime permissions)
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  static const String _channelId = 'avenue_default_channel';
  static const String _channelName = 'Avenue Notifications';
  static const String _channelDescription =
      'Default notification channel for Avenue app';

  /// Initializes the service, including timezones and notification channels
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      try {
        final dynamic location = await FlutterTimezone.getLocalTimezone();
        final String timeZoneName = location is String
            ? location
            : 'Africa/Cairo';
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        AvenueLogger.log(
          event: 'TIMEZONE_INIT_SUCCESS',
          layer: LoggerLayer.SYNC,
          payload: timeZoneName,
        );
      } catch (e) {
        // Fallback to a safe location if local lookup fails
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      }

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
          ),
        );
      }

      _isInitialized = true;
      await requestPermissionIfNeeded();

      AvenueLogger.log(
        event: 'NOTIFICATION_INIT_SUCCESS',
        layer: LoggerLayer.SYNC,
      );
    } catch (e, stack) {
      _isInitialized = false;
      AvenueLogger.log(
        event: 'NOTIFICATION_INIT_ERROR',
        layer: LoggerLayer.SYNC,
        level: LoggerLevel.ERROR,
        payload: '$e\n$stack',
      );
    }
  }

  /// Requests notification permissions for Android 13+
  Future<bool> requestPermissionIfNeeded() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation == null) return false;

      final granted = await androidImplementation
          .requestNotificationsPermission();
      final exactPermitted = await androidImplementation
          .canScheduleExactNotifications();

      if (exactPermitted == false) {
        await androidImplementation.requestExactAlarmsPermission();
      }

      return granted == true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the app can schedule exact alarms
  Future<bool> canScheduleExactAlarms() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidImplementation?.canScheduleExactNotifications() ??
        false;
  }

  /// Shows an instant notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      AvenueLogger.log(
        event: 'NOTIFICATION_SKIPPED',
        layer: LoggerLayer.SYNC,
        payload: 'Service not initialized',
      );
      return;
    }
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
      );

      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Schedules a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      AvenueLogger.log(
        event: 'NOTIFICATION_SKIPPED',
        layer: LoggerLayer.SYNC,
        payload: 'Service not initialized',
      );
      return;
    }
    try {
      if (scheduledTime.isBefore(DateTime.now())) return;

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final bool canExact =
          await androidImplementation?.canScheduleExactNotifications() ?? false;

      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      // Log error if needed
    }
  }

  /// Cancels a specific notification by ID
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    await _notifications.cancel(id: id);
  }

  /// Cancels all scheduled notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await _notifications.cancelAll();
  }

  /// Handles notification tap events
  void _onNotificationTapped(NotificationResponse response) {
    AvenueLogger.log(
      event: 'NOTIFICATION_TAPPED',
      layer: LoggerLayer.SYNC,
      payload: response.payload,
    );
  }

  /// Returns a list of all pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() {
    if (!_isInitialized) return Future.value([]);
    return _notifications.pendingNotificationRequests();
  }
}
