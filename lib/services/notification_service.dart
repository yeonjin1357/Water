import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/user_settings.dart';

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
    // debugPrint('NotificationService: Initializing...');
    
    // Initialize timezone with device's local timezone
    tz.initializeTimeZones();
    
    // Get device's current timezone
    String timeZoneName;
    try {
      timeZoneName = await FlutterTimezone.getLocalTimezone();
      // debugPrint('NotificationService: Device timezone detected: $timeZoneName');
    } catch (e) {
      // debugPrint('NotificationService: Failed to get timezone: $e');
      // Try to determine timezone from DateTime offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      // debugPrint('NotificationService: Device timezone offset: $offset');
      
      // Common timezone mappings based on offset
      if (offset == const Duration(hours: 9)) {
        timeZoneName = 'Asia/Seoul';
      } else if (offset == const Duration(hours: 8)) {
        timeZoneName = 'Asia/Shanghai';
      } else if (offset == const Duration(hours: 7)) {
        timeZoneName = 'Asia/Bangkok';
      } else if (offset == const Duration(hours: -8)) {
        timeZoneName = 'America/Los_Angeles';
      } else if (offset == const Duration(hours: -5)) {
        timeZoneName = 'America/New_York';
      } else if (offset == Duration.zero) {
        timeZoneName = 'UTC';
      } else {
        // Default to Asia/Seoul for Korean market
        timeZoneName = 'Asia/Seoul';
        // debugPrint('NotificationService: Using default timezone for Korean market');
      }
      // debugPrint('NotificationService: Using timezone based on offset: $timeZoneName');
    }
    
    // Set the location
    try {
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      // debugPrint('NotificationService: Successfully set timezone to: $timeZoneName');
    } catch (e) {
      // debugPrint('NotificationService: Failed to set timezone $timeZoneName: $e');
      // Last resort - use Asia/Seoul for Korean market
      try {
        final location = tz.getLocation('Asia/Seoul');
        tz.setLocalLocation(location);
        // debugPrint('NotificationService: Fallback to Asia/Seoul timezone');
      } catch (e2) {
        // debugPrint('NotificationService: Critical error - using UTC: $e2');
        tz.setLocalLocation(tz.UTC);
      }
    }
    
    // Debug: Check current time and verify timezone is correct
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    // debugPrint('\n=== TIMEZONE VERIFICATION ===');
    // debugPrint('DateTime.now() = $now');
    // debugPrint('TZDateTime.now(tz.local) = $tzNow');
    // debugPrint('Timezone name = ${tz.local.name}');
    // debugPrint('Device timezone offset = ${now.timeZoneOffset}');
    // debugPrint('TZ library offset = ${tzNow.timeZoneOffset}');
    
    // Check if times are properly aligned
    final hourMatch = now.hour == tzNow.hour;
    final minuteMatch = now.minute == tzNow.minute;
    // debugPrint('Hour match: $hourMatch (Device: ${now.hour}, TZ: ${tzNow.hour})');
    // debugPrint('Minute match: $minuteMatch (Device: ${now.minute}, TZ: ${tzNow.minute})');
    
    if (!hourMatch || !minuteMatch) {
      // debugPrint('⚠️ WARNING: Timezone mismatch detected!');
      // debugPrint('   This may cause notifications to fire at wrong times');
    } else {
      // debugPrint('✅ Timezone properly configured');
    }
    // debugPrint('=============================\n');

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
    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
    // debugPrint('NotificationService: Plugin initialized: $initialized');
    
    // Create notification channel for Android FIRST (before requesting permissions)
    await _createNotificationChannel();
    
    // Request notification permissions for Android 13+
    await _requestNotificationPermissions();
    
    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
    
    // Request notification permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }
    
    // Check battery optimization status
    await isIgnoringBatteryOptimizations();
  }

  Future<void> _createNotificationChannel() async {
    // debugPrint('NotificationService: Creating notification channel...');
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,  // Changed to max for highest priority
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      // debugPrint('NotificationService: Channel created successfully');
    } else {
      // debugPrint('NotificationService: Failed to get Android plugin');
    }
  }
  
  Future<void> _createPersistentNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'persistent_water_channel',
      '수분 섭취 현황',
      description: '오늘의 수분 섭취량을 실시간으로 표시합니다',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      enableLights: false,
      showBadge: false,  // 배지 표시 안함
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }
  
  Future<void> _createMidnightResetChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'midnight_reset_channel',
      'Midnight Reset',
      description: 'Resets the water intake notification at midnight',
      importance: Importance.min,
      playSound: false,
      enableVibration: false,
      enableLights: false,
      showBadge: false,  // 배지 표시 안함
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
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
    // debugPrint('iOS notification received: $title - $body');
  }

  // Notification tap handler
  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      // debugPrint('Notification payload: $payload');
      
      // Handle midnight reset
      if (payload == 'midnight_reset') {
        // This is handled by the provider when the app is opened
        // The notification itself serves as a trigger
        // debugPrint('Midnight reset notification received');
      }
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
      // debugPrint('Failed to schedule notification: $e');
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
      // debugPrint('Failed to schedule exact reminders: $e');
      // If exact alarms fail (likely due to Android 12+ permissions),
      // fall back to periodic notifications
      if (e.toString().contains('exact_alarms_not_permitted') || 
          e.toString().contains('SCHEDULE_EXACT_ALARM')) {
        // debugPrint('Exact alarms not permitted, using periodic reminders instead');
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
          // debugPrint('Failed to schedule notification: $e');
        }
      }
      
      scheduledTime = scheduledTime.add(Duration(minutes: intervalMinutes));
    }
    
    // debugPrint('Scheduled ${notificationId - 1} exact water reminders');
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
    
    // debugPrint('Scheduled hourly water reminder (exact alarms not available)');
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
        // debugPrint('NotificationService: Notifications enabled: $areEnabled');
        
        // Also check notification channel status
        try {
          final List<AndroidNotificationChannel>? channels = 
              await androidImplementation.getNotificationChannels();
          if (channels != null) {
            // debugPrint('NotificationService: Active channels: ${channels.length}');
            for (final channel in channels) {
              // debugPrint('  - Channel: ${channel.id}, Importance: ${channel.importance?.name}');
            }
          }
        } catch (e) {
          // debugPrint('NotificationService: Error checking channels: $e');
        }
        
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
    // Create persistent notification channel without badge
    await _createPersistentNotificationChannel();
    
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
      ongoing: false, // 스와이프로 제거 가능
      autoCancel: false, // 탭해도 사라지지 않음
      showProgress: true,
      maxProgress: dailyGoal,
      progress: currentAmount,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF42A5F5),
      playSound: false, // 무음
      enableVibration: false, // 진동 없음
      channelShowBadge: false, // 앱 아이콘에 배지 표시 안함
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
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
  
  // Schedule midnight reset for persistent notification
  Future<void> scheduleMidnightReset() async {
    // Cancel any existing midnight reset notification
    await flutterLocalNotificationsPlugin.cancel(998); // Use ID 998 for midnight reset
    
    // Calculate next midnight
    final now = DateTime.now();
    var midnight = DateTime(
      now.year,
      now.month,
      now.day + 1, // Tomorrow
      0, // Hour: 00
      0, // Minute: 00
    );
    
    // Convert to TZDateTime
    final tzMidnight = tz.TZDateTime.from(midnight, tz.local);
    
    // Create midnight reset channel without badge
    await _createMidnightResetChannel();
    
    // Create a special notification that triggers at midnight
    // This notification will be invisible to the user but will trigger the reset
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'midnight_reset_channel',
      'Midnight Reset',
      channelDescription: 'Resets the water intake notification at midnight',
      importance: Importance.min, // Minimal importance
      priority: Priority.min,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      channelShowBadge: false, // 앱 아이콘에 배지 표시 안함
      ticker: '', // Empty ticker to minimize visibility
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    try {
      // Check if we can schedule exact alarms
      final bool canUseExact = await canScheduleExactAlarms();
      final AndroidScheduleMode mode = canUseExact 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle;
      
      // Schedule the midnight reset notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        998,
        '', // Empty title
        '', // Empty body
        tzMidnight,
        platformChannelSpecifics,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at midnight
        payload: 'midnight_reset', // Special payload to identify this notification
      );
      
      // debugPrint('Scheduled midnight reset notification for: $tzMidnight');
    } catch (e) {
      // debugPrint('Failed to schedule midnight reset: $e');
    }
  }
  
  // Reset persistent notification to 0%
  Future<void> resetPersistentNotificationToZero(int dailyGoal) async {
    // Update the persistent notification to show 0%
    await showPersistentNotification(
      currentAmount: 0,
      dailyGoal: dailyGoal,
    );
    
    // Re-schedule the next midnight reset
    await scheduleMidnightReset();
  }
  
  // Check if persistent notification is active
  Future<bool> isPersistentNotificationActive() async {
    final List<PendingNotificationRequest> pending = 
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    
    // Check if notification with ID 999 exists
    for (final notification in pending) {
      if (notification.id == 999) {
        return true;
      }
    }
    
    // On Android, also check active notifications
    if (Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        try {
          final activeNotifications = await androidImplementation.getActiveNotifications();
          for (final notification in activeNotifications) {
            if (notification.id == 999) {
              return true;
            }
          }
        } catch (e) {
          // If method not available, fall back to false
          return false;
        }
      }
    }
    
    return false;
  }
  
  // Ultra simple scheduled notification test - just 5 seconds
  Future<void> scheduleSimpleTest() async {
    // debugPrint('NotificationService: Ultra simple test - scheduling in 5 seconds');
    
    try {
      // Method 1: Using periodicallyShow for testing
      await flutterLocalNotificationsPlugin.periodicallyShow(
        7777,
        '주기적 테스트',
        '이 알림은 매분 반복됩니다',
        RepeatInterval.everyMinute,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF42A5F5),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      // debugPrint('NotificationService: Periodic notification started (every minute)');
      
      // Cancel after 2 minutes
      Future.delayed(const Duration(minutes: 2), () {
        flutterLocalNotificationsPlugin.cancel(7777);
        // debugPrint('NotificationService: Periodic notification cancelled');
      });
    } catch (e) {
      // debugPrint('NotificationService: Failed to start periodic notification: $e');
    }
  }
  
  // Clear all notifications and reset
  Future<void> clearAllAndReset() async {
    // debugPrint('\n=== CLEARING ALL NOTIFICATIONS ===');
    
    // Cancel ALL notifications
    await flutterLocalNotificationsPlugin.cancelAll();
    // debugPrint('All notifications cancelled');
    
    // Re-create notification channel
    await _createNotificationChannel();
    // debugPrint('Notification channel recreated');
    
    // Check pending list
    final pending = await getPendingNotifications();
    // debugPrint('Remaining pending notifications: ${pending.length}');
    // debugPrint('===================================\n');
  }
  
  // Test notification - for debugging
  Future<void> showTestNotification() async {
    // debugPrint('NotificationService: Sending test notification...');
    
    // First check if we have permissions
    final bool hasPermission = await areNotificationsEnabled();
    // debugPrint('NotificationService: Has permission for test: $hasPermission');
    
    if (!hasPermission) {
      // debugPrint('NotificationService: No permission, requesting...');
      await _requestNotificationPermissions();
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

    try {
      await flutterLocalNotificationsPlugin.show(
        9999,
        '테스트 알림',
        '알림이 정상적으로 작동합니다!',
        platformChannelSpecifics,
      );
      // debugPrint('NotificationService: Test notification sent successfully');
    } catch (e) {
      // debugPrint('NotificationService: Failed to send test notification: $e');
    }
  }
  
  // Schedule a test notification in 1 minute
  Future<void> scheduleTestNotificationIn1Minute() async {
    // debugPrint('\n=== SCHEDULING 1-MINUTE TEST ===');
    
    // Use DateTime.now() and convert to TZDateTime
    final DateTime deviceNow = DateTime.now();
    final DateTime deviceScheduled = deviceNow.add(const Duration(minutes: 1));
    
    // Convert to TZDateTime
    final tz.TZDateTime now = tz.TZDateTime.from(deviceNow, tz.local);
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(deviceScheduled, tz.local);
    
    // debugPrint('Device current time: $deviceNow');
    // debugPrint('Device scheduled time: $deviceScheduled');
    // debugPrint('TZ current time: $now');
    // debugPrint('TZ scheduled time: $scheduledDate');
    // debugPrint('Timezone: ${tz.local.name}');
    // debugPrint('Difference: ${scheduledDate.difference(now).inMinutes} minutes');
    
    // Check exact alarm permission
    final bool canUseExact = await canScheduleExactAlarms();
    // debugPrint('Can use exact alarms: $canUseExact');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
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

    try {
      // Choose mode based on permission
      final AndroidScheduleMode mode = canUseExact 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle;
      
      // Use a unique ID based on timestamp
      final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '🕐 1분 테스트 알림',
        '1분 후 알림이 정상적으로 발생했습니다!',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,  // Critical for Doze mode
      );
      // debugPrint('✅ 1-minute test notification scheduled with mode: $mode');
      
      // Verify it was scheduled
      final List<PendingNotificationRequest> pending = await getPendingNotifications();
      // debugPrint('Total pending notifications: ${pending.length}');
      
      bool found = false;
      for (final notif in pending) {
        if (notif.id == notificationId) {
          // debugPrint('✅ 1-minute test notification found in pending list!');
          found = true;
          break;
        }
      }
      if (!found) {
        // debugPrint('❌ 1-minute test notification NOT found in pending list!');
      }
    } catch (e) {
      // debugPrint('❌ Failed to schedule 1-minute test notification');
      // debugPrint('   Error: $e');
    }
    // debugPrint('=================================\n');
  }
  
  // Schedule a test notification in 10 seconds
  Future<void> scheduleTestNotificationIn10Seconds() async {
    // debugPrint('\n=== SCHEDULING 10-SECOND TEST ===');
    
    // First, check and clear if too many pending notifications
    final pending = await getPendingNotifications();
    // debugPrint('Current pending notifications: ${pending.length}');
    if (pending.length > 10) {
      // debugPrint('⚠️ Too many pending notifications! Clearing all...');
      await flutterLocalNotificationsPlugin.cancelAll();
      // debugPrint('All notifications cleared');
    }
    
    // Use DateTime.now() and convert to TZDateTime to ensure proper timezone
    final DateTime deviceNow = DateTime.now();
    final DateTime deviceScheduled = deviceNow.add(const Duration(seconds: 10));
    
    // Convert to TZDateTime using the device's local time
    final tz.TZDateTime now = tz.TZDateTime.from(deviceNow, tz.local);
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(deviceScheduled, tz.local);
    
    // debugPrint('Device current time: $deviceNow');
    // debugPrint('Device scheduled time: $deviceScheduled');
    // debugPrint('TZ current time: $now');
    // debugPrint('TZ scheduled time: $scheduledDate');
    // debugPrint('Timezone: ${tz.local.name}');
    // debugPrint('Difference: ${scheduledDate.difference(now).inSeconds} seconds');
    
    // Check exact alarm permission
    final bool canUseExact = await canScheduleExactAlarms();
    // debugPrint('Can use exact alarms: $canUseExact');
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
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

    try {
      // Use alarmClock mode for testing - highest priority
      AndroidScheduleMode mode;
      if (Platform.isAndroid && canUseExact) {
        mode = AndroidScheduleMode.alarmClock;  // Shows icon in status bar, bypasses Doze
        // debugPrint('Using alarmClock mode (highest priority)');
      } else if (canUseExact) {
        mode = AndroidScheduleMode.exactAllowWhileIdle;
        // debugPrint('Using exactAllowWhileIdle mode');
      } else {
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
        // debugPrint('Using inexactAllowWhileIdle mode (fallback)');
      }
      
      // Check if notifications are actually enabled in system settings
      final bool notificationsEnabled = await areNotificationsEnabled();
      if (!notificationsEnabled) {
        // debugPrint('❌ CRITICAL: Notifications are disabled in system settings!');
        // debugPrint('   Please enable notifications for this app in system settings');
        // debugPrint('   Go to: Settings > Apps > Water > Notifications');
        return;
      }
      
      // Use a unique ID based on timestamp to avoid conflicts
      final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '예약 테스트 알림',
        '10초 후 알림이 정상적으로 발생했습니다!',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,  // Critical for Doze mode
      );
      // debugPrint('✅ Test notification scheduled with mode: $mode');
      // debugPrint('   Notification ID: $notificationId');
      // debugPrint('   Will fire at: $scheduledDate');
      
      // Verify it was scheduled
      final List<PendingNotificationRequest> pendingAfter = await getPendingNotifications();
      // debugPrint('Total pending notifications after scheduling: ${pendingAfter.length}');
      
      bool found = false;
      for (final notif in pending) {
        if (notif.id == notificationId) {
          // debugPrint('✅ Test notification found in pending list!');
          // debugPrint('   - Title: ${notif.title}');
          // debugPrint('   - Body: ${notif.body}');
          // debugPrint('   - Payload: ${notif.payload}');
          found = true;
          break;
        }
      }
      if (!found) {
        // debugPrint('❌ Test notification NOT found in pending list!');
      }
    } catch (e) {
      // debugPrint('❌ Failed to schedule test notification');
      // debugPrint('   Error: $e');
      // debugPrint('   Error type: ${e.runtimeType}');
      
      // Check if it's a permission issue
      if (e.toString().contains('exact_alarms_not_permitted') || 
          e.toString().contains('SCHEDULE_EXACT_ALARM')) {
        // debugPrint('⚠️ This is a permission issue - exact alarms not allowed');
      }
    }
    // debugPrint('=================================\n');
  }

  // Schedule water reminder notifications based on WaterReminder list
  Future<void> scheduleWaterReminderNotifications(List<WaterReminder> reminders) async {
    // debugPrint('\n========================================');
    // debugPrint('STARTING NOTIFICATION SCHEDULING');
    // debugPrint('========================================');
    // debugPrint('Total reminders to schedule: ${reminders.length}');
    // debugPrint('Current timezone: ${tz.local.name}');
    // debugPrint('Current time: ${tz.TZDateTime.now(tz.local)}');
    
    // Cancel all existing reminders (except persistent notification)
    await cancelWaterReminders();
    
    // Check if we have notification permissions first
    final bool hasPermission = await areNotificationsEnabled();
    // debugPrint('Has notification permission: $hasPermission');
    
    if (!hasPermission) {
      // debugPrint('No notification permission, requesting...');
      await _requestNotificationPermissions();
    }
    
    // Check if we can schedule exact alarms (Android 12+)
    final bool canScheduleExact = await canScheduleExactAlarms();
    // debugPrint('Can schedule exact alarms: $canScheduleExact');
    
    if (!canScheduleExact && Platform.isAndroid) {
      // debugPrint('⚠️ WARNING - Cannot schedule exact alarms!');
      // debugPrint('   Notifications may be delayed by up to 15 minutes');
    }
    
    // Schedule new reminders
    int notificationId = 1000; // Start from 1000 to avoid conflicts
    int scheduledCount = 0;
    
    for (final reminder in reminders) {
      if (!reminder.isEnabled) {
        // debugPrint('NotificationService: Skipping disabled reminder: ${reminder.label}');
        continue;
      }
      
      // debugPrint('NotificationService: Scheduling reminder: ${reminder.label} at ${reminder.time.hour}:${reminder.time.minute} on weekdays: ${reminder.weekdays}');
      
      for (final weekday in reminder.weekdays) {
        final success = await _scheduleWeeklyReminder(
          id: notificationId++,
          weekday: weekday,
          time: reminder.time,
          label: reminder.label,
        );
        if (success) scheduledCount++;
      }
    }
    
    // debugPrint('\n========================================');
    // debugPrint('SCHEDULING COMPLETE');
    // debugPrint('========================================');
    // debugPrint('Successfully scheduled: $scheduledCount notifications');
    
    // List all scheduled notifications for debugging
    final List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    // debugPrint('\nVERIFYING SCHEDULED NOTIFICATIONS:');
    // debugPrint('Total pending: ${pendingNotifications.length}');
    for (final notification in pendingNotifications) {
      // debugPrint('  ✓ ID: ${notification.id} | Title: ${notification.title}');
    }
    // debugPrint('========================================\n');
  }
  
  // Schedule a weekly recurring notification for a specific weekday
  Future<bool> _scheduleWeeklyReminder({
    required int id,
    required int weekday, // 1 = Monday, 7 = Sunday
    required TimeOfDay time,
    String? label,
  }) async {
    final tzNow = tz.TZDateTime.now(tz.local);
    final scheduledDate = _nextInstanceOfWeekdayTime(weekday, time);
    
    // debugPrint('\n=== SCHEDULING NOTIFICATION ===');
    // debugPrint('ID: $id');
    // debugPrint('Label: ${label ?? "No label"}');
    // debugPrint('Target: Weekday $weekday at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    // debugPrint('Current time: ${tzNow.toString()}');
    // debugPrint('Scheduled for: ${scheduledDate.toString()}');
    // debugPrint('Time until notification: ${scheduledDate.difference(tzNow).inMinutes} minutes');
    // debugPrint('Is in future? ${scheduledDate.isAfter(tzNow)}');
    
    // Check if we can use exact alarms
    final bool canUseExact = await canScheduleExactAlarms();
    // debugPrint('Can use exact alarms: $canUseExact');
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF42A5F5),
      enableLights: true,
      enableVibration: true,
      playSound: true,
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
    
    final title = label?.isNotEmpty == true ? label! : '물 마실 시간입니다! 💧';
    const body = '충분한 수분 섭취는 건강한 하루의 시작입니다.';
    
    try {
      // Choose appropriate scheduling mode based on permissions
      AndroidScheduleMode scheduleMode;
      if (canUseExact) {
        // Use exact alarm if permitted
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        // debugPrint('NotificationService: Using EXACT alarm mode');
      } else {
        // Fallback to inexact if exact alarms not permitted
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        // debugPrint('NotificationService: Using INEXACT alarm mode (fallback)');
      }
      
      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,  // Critical for Doze mode
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,  // For weekly repeat
      );
      // debugPrint('✅ Successfully scheduled notification id=$id');
      // debugPrint('   - Time: $scheduledDate');
      // debugPrint('   - Mode: $scheduleMode');
      // debugPrint('   - Will fire in: ${scheduledDate.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes');
      return true;
    } catch (e) {
      // debugPrint('❌ Failed to schedule weekly notification id=$id');
      // debugPrint('   Error: $e');
      // debugPrint('   Error type: ${e.runtimeType}');
      
      // Fallback: Schedule multiple one-time notifications for the next 4 weeks
      try {
        // debugPrint('NotificationService: Trying fallback approach with multiple one-time notifications...');
        bool anyScheduled = false;
        
        // Use inexact mode for fallback to avoid permission issues
        final fallbackMode = canUseExact 
            ? AndroidScheduleMode.exactAllowWhileIdle 
            : AndroidScheduleMode.inexactAllowWhileIdle;
        
        for (int week = 0; week < 4; week++) {
          final futureDate = scheduledDate.add(Duration(days: week * 7));
          final futureId = id + (week * 10000); // Ensure unique IDs
          
          try {
            await flutterLocalNotificationsPlugin.zonedSchedule(
              futureId,
              title,
              body,
              futureDate,
              platformChannelSpecifics,
              androidScheduleMode: fallbackMode,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidAllowWhileIdle: true,
            );
            // debugPrint('NotificationService: Scheduled one-time notification id=$futureId for ${futureDate.toString()} with mode=$fallbackMode');
            anyScheduled = true;
          } catch (e2) {
            // debugPrint('NotificationService: Failed to schedule one-time notification for week $week: $e2');
          }
        }
        
        return anyScheduled;
      } catch (e3) {
        // debugPrint('NotificationService: Fallback approach also failed: $e3');
        return false;
      }
    }
  }
  
  // Calculate next instance of a specific weekday and time
  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, TimeOfDay time) {
    // Start with device's DateTime to ensure correct local time
    final DateTime deviceNow = DateTime.now();
    
    // Create scheduled DateTime
    DateTime scheduledDateTime = DateTime(
      deviceNow.year,
      deviceNow.month,
      deviceNow.day,
      time.hour,
      time.minute,
    );
    
    // Adjust to the correct weekday
    while (scheduledDateTime.weekday != weekday) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }
    
    // If the time has passed this week, schedule for next week
    if (scheduledDateTime.isBefore(deviceNow) || scheduledDateTime.isAtSameMomentAs(deviceNow)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 7));
    }
    
    // Convert to TZDateTime
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledDateTime, tz.local);
    
    // debugPrint('_nextInstanceOfWeekdayTime: ');
    // debugPrint('  - Device current: $deviceNow');
    // debugPrint('  - Device scheduled: $scheduledDateTime');
    // debugPrint('  - TZ scheduled: $scheduledDate');
    // debugPrint('  - Difference: ${scheduledDateTime.difference(deviceNow).inMinutes} minutes');
    // debugPrint('  - Weekday match: ${scheduledDateTime.weekday == weekday}');
    
    return scheduledDate;
  }
  
  // Cancel all water reminder notifications (preserve persistent notification)
  Future<void> cancelWaterReminders() async {
    // Get all pending notifications
    final List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    
    // Cancel all notifications except persistent (id: 999)
    for (final notification in pendingNotifications) {
      if (notification.id != 999 && notification.id >= 1000) {
        await flutterLocalNotificationsPlugin.cancel(notification.id);
      }
    }
  }
  
  // Check if exact alarms are permitted
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      // For flutter_local_notifications 17.x, we'll try to schedule a test notification
      // and see if it works with exact alarm mode
      try {
        final tz.TZDateTime testTime = tz.TZDateTime.now(tz.local).add(const Duration(days: 365));
        
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          importance: Importance.min,
          priority: Priority.min,
          playSound: false,
          enableVibration: false,
        );
        
        const NotificationDetails details = NotificationDetails(android: androidDetails);
        
        // Try to schedule with exact alarm
        await flutterLocalNotificationsPlugin.zonedSchedule(
          -999999, // Use negative ID for test
          'Test',
          'Test',
          testTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        
        // Cancel the test notification immediately
        await flutterLocalNotificationsPlugin.cancel(-999999);
        
        // debugPrint('NotificationService: Can schedule exact alarms: true');
        return true;
      } catch (e) {
        if (e.toString().contains('exact_alarms_not_permitted') || 
            e.toString().contains('SCHEDULE_EXACT_ALARM')) {
          // debugPrint('NotificationService: Cannot schedule exact alarms: false');
          return false;
        }
        // debugPrint('NotificationService: Assuming exact alarms are allowed');
        return true;
      }
    }
    return true; // iOS doesn't have this restriction
  }
  
  // Check battery optimization status
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (Platform.isAndroid) {
      try {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // This would require adding permission_handler package
          // For now, just log a warning
          // debugPrint('\n⚠️ IMPORTANT: Check battery optimization settings!');
          // debugPrint('   Go to Settings > Apps > Water > Battery');
          // debugPrint('   Select "Unrestricted" for best notification reliability');
          // debugPrint('   Or disable battery optimization for this app\n');
        }
      } catch (e) {
        // debugPrint('Error checking battery optimization: $e');
      }
    }
    return true;  // Assume true for now
  }
  
  // Open system settings for alarm permissions
  Future<void> openAlarmPermissionSettings() async {
    if (Platform.isAndroid) {
      try {
        // Android 12+ : 정확한 알람 설정 페이지로 직접 이동
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // Try to open exact alarm settings directly
          final bool? result = await androidImplementation.requestExactAlarmsPermission();
          // debugPrint('NotificationService: Exact alarm permission request result: $result');
          
          if (result == false) {
            // If still denied, open app settings
            await AppSettings.openAppSettings(type: AppSettingsType.notification);
            // debugPrint('NotificationService: Opened app notification settings');
          }
        } else {
          // Fallback to general notification settings
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
          // debugPrint('NotificationService: Opened notification settings (fallback)');
        }
      } catch (e) {
        // debugPrint('NotificationService: Error opening settings: $e');
      }
    }
  }
  
  // Request notification permissions for Android 13+
  Future<void> _requestNotificationPermissions() async {
    // debugPrint('NotificationService: Requesting notification permissions...');
    
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Request notification permission
        final bool? notificationGranted = await androidImplementation.requestNotificationsPermission();
        // debugPrint('NotificationService: Notification permission granted: $notificationGranted');
        
        // Check and request exact alarm permission for Android 12+
        try {
          // First check if we can schedule exact alarms
          final bool canSchedule = await canScheduleExactAlarms();
          if (!canSchedule) {
            // debugPrint('NotificationService: Cannot schedule exact alarms, requesting permission...');
            final bool? exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
            // debugPrint('NotificationService: Exact alarm permission request result: $exactAlarmGranted');
            
            // Check again after requesting
            final bool canScheduleAfter = await canScheduleExactAlarms();
            // debugPrint('NotificationService: Can schedule exact alarms after request: $canScheduleAfter');
          } else {
            // debugPrint('NotificationService: Exact alarm permission already granted');
          }
        } catch (e) {
          // debugPrint('NotificationService: Error with exact alarm permission: $e');
          // Continue even if exact alarm permission fails
        }
      } else {
        // debugPrint('NotificationService: Android implementation is null');
      }
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iosImplementation != null) {
        final bool? granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        // debugPrint('NotificationService: iOS notification permission granted: $granted');
      }
    }
  }
}