import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'water_reminder_channel';
  static const String channelName = 'Water Reminder';
  static const String channelDescription = 
      'Reminds you to drink water throughout the day';

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    // Initialize settings for both platforms
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
    
    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
    
    // Request notification permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _requestAndroidPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // iOS foreground notification handler
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    debugPrint('iOS notification received: $title - $body');
  }

  // Notification tap handler
  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF42A5F5),
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Schedule periodic notifications
  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required Duration interval,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF42A5F5),
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.hourly, // Can be changed based on interval
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // Schedule daily notification at specific time
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF42A5F5),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      // If exact alarms are not permitted, throw the error to be handled by caller
      debugPrint('Failed to schedule notification: $e');
      rethrow;
    }
  }

  // Schedule multiple notifications throughout the day
  Future<void> scheduleWaterReminders({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int intervalMinutes,
  }) async {
    // Cancel all existing notifications first
    await cancelAllNotifications();
    
    // Try to schedule exact reminders first
    bool exactRemindersScheduled = false;
    
    try {
      await _scheduleExactReminders(startTime, endTime, intervalMinutes);
      exactRemindersScheduled = true;
    } catch (e) {
      debugPrint('Failed to schedule exact reminders: $e');
      // If exact alarms fail (likely due to Android 12+ permissions),
      // fall back to periodic notifications
      if (e.toString().contains('exact_alarms_not_permitted') || 
          e.toString().contains('SCHEDULE_EXACT_ALARM')) {
        debugPrint('Exact alarms not permitted, using periodic reminders instead');
      }
    }
    
    // If exact reminders failed, use periodic reminder as fallback
    if (!exactRemindersScheduled) {
      await _schedulePeriodicReminder(intervalMinutes);
    }
  }
  
  // Schedule exact reminders (when permission is granted)
  Future<void> _scheduleExactReminders(
    TimeOfDay startTime,
    TimeOfDay endTime,
    int intervalMinutes,
  ) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endTime.hour,
      endTime.minute,
    );

    int notificationId = 1;
    
    while (scheduledTime.isBefore(endDateTime)) {
      // Skip if the time has already passed today
      if (scheduledTime.isAfter(now)) {
        try {
          await scheduleDailyNotification(
            id: notificationId,
            title: '💧 물 마실 시간이에요!',
            body: '건강을 위해 물 한 잔 마셔보는 건 어떨까요?',
            time: TimeOfDay(
              hour: scheduledTime.hour,
              minute: scheduledTime.minute,
            ),
          );
          notificationId++;
        } catch (e) {
          debugPrint('Failed to schedule notification: $e');
        }
      }
      
      scheduledTime = scheduledTime.add(Duration(minutes: intervalMinutes));
    }
    
    debugPrint('Scheduled ${notificationId - 1} exact water reminders');
  }
  
  // Schedule periodic reminder (fallback when exact alarms not allowed)
  Future<void> _schedulePeriodicReminder(int intervalMinutes) async {
    // Use hourly notifications as fallback
    // Note: RepeatInterval only supports everyMinute, hourly, daily, weekly
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF42A5F5),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Use hourly interval as a reasonable fallback
    await flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      '💧 물 마실 시간이에요!',
      '건강을 위해 물 한 잔 마셔보는 건 어떨까요?',
      RepeatInterval.hourly,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'water_reminder',
    );
    
    debugPrint('Scheduled hourly water reminder (exact alarms not available)');
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? areEnabled = await androidImplementation
            .areNotificationsEnabled();
        return areEnabled ?? false;
      }
    }
    
    // For iOS, we can check permissions
    if (Platform.isIOS) {
      final iOSImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iOSImplementation != null) {
        // Request permissions returns null if already granted
        final result = await iOSImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return result ?? true;
      }
    }
    
    return false;
  }

  // Show persistent notification with water intake progress
  Future<void> showPersistentNotification({
    required int currentAmount,
    required int dailyGoal,
  }) async {
    final percentage = ((currentAmount / dailyGoal) * 100).round();
    final remainingAmount = dailyGoal - currentAmount;
    
    String title = '💧 오늘의 수분 섭취';
    String body;
    
    if (currentAmount >= dailyGoal) {
      body = '목표 달성! ${currentAmount}ml / ${dailyGoal}ml (${percentage}%)';
    } else {
      body = '${currentAmount}ml / ${dailyGoal}ml (${percentage}%)\n${remainingAmount}ml 더 마시면 목표 달성!';
    }
    
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'persistent_water_channel',
      '수분 섭취 현황',
      channelDescription: '오늘의 수분 섭취량을 실시간으로 표시합니다',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // 스와이프로 제거 불가능
      autoCancel: false, // 탭해도 사라지지 않음
      showProgress: true,
      maxProgress: dailyGoal,
      progress: currentAmount,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF42A5F5),
      playSound: false, // 무음
      enableVibration: false, // 진동 없음
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      999, // 고정 ID 사용 (업데이트를 위해)
      title,
      body,
      platformChannelSpecifics,
    );
  }
  
  // Hide persistent notification
  Future<void> hidePersistentNotification() async {
    await flutterLocalNotificationsPlugin.cancel(999);
  }
}