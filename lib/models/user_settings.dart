import 'package:flutter/material.dart';

class WaterReminder {
  final String id;
  final TimeOfDay time;
  final List<int> weekdays; // 1: 월, 2: 화, 3: 수, 4: 목, 5: 금, 6: 토, 7: 일
  final bool isEnabled;
  final String label;

  WaterReminder({
    required this.id,
    required this.time,
    required this.weekdays,
    this.isEnabled = true,
    this.label = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'weekdays': weekdays,
      'isEnabled': isEnabled,
      'label': label,
    };
  }

  factory WaterReminder.fromMap(Map<String, dynamic> map) {
    return WaterReminder(
      id: map['id'],
      time: TimeOfDay(
        hour: map['hour'],
        minute: map['minute'],
      ),
      weekdays: List<int>.from(map['weekdays'] ?? []),
      isEnabled: map['isEnabled'] ?? true,
      label: map['label'] ?? '',
    );
  }

  String getWeekdaysText() {
    if (weekdays.isEmpty) return '없음';
    if (weekdays.length == 7) return '매일';
    if (weekdays.length == 5 && !weekdays.contains(6) && !weekdays.contains(7)) {
      return '주중';
    }
    if (weekdays.length == 2 && weekdays.contains(6) && weekdays.contains(7)) {
      return '주말';
    }
    
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays.map((day) => weekdayNames[day - 1]).join(', ');
  }
}

class CustomDrink {
  final String id;
  final String name;
  final Color color;

  CustomDrink({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  factory CustomDrink.fromMap(Map<String, dynamic> map) {
    return CustomDrink(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
    );
  }
}

class UserSettings {
  final int dailyGoal;
  final int reminderInterval; // 기존 호환성을 위해 유지
  final TimeOfDay reminderStartTime; // 기존 호환성을 위해 유지
  final TimeOfDay reminderEndTime; // 기존 호환성을 위해 유지
  final int defaultAmount;
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool persistentNotificationEnabled;
  final List<CustomDrink> customDrinks;
  final List<WaterReminder> waterReminders; // 새로운 알림 시스템

  UserSettings({
    this.dailyGoal = 2000,
    this.reminderInterval = 60,
    this.reminderStartTime = const TimeOfDay(hour: 8, minute: 0),
    this.reminderEndTime = const TimeOfDay(hour: 22, minute: 0),
    this.defaultAmount = 250,
    this.isDarkMode = false,
    this.language = 'ko',
    this.notificationsEnabled = false,
    this.persistentNotificationEnabled = false,
    this.customDrinks = const [],
    this.waterReminders = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyGoal': dailyGoal,
      'reminderInterval': reminderInterval,
      'reminderStartTime': '${reminderStartTime.hour}:${reminderStartTime.minute}',
      'reminderEndTime': '${reminderEndTime.hour}:${reminderEndTime.minute}',
      'defaultAmount': defaultAmount,
      'isDarkMode': isDarkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'persistentNotificationEnabled': persistentNotificationEnabled,
      'customDrinks': customDrinks.map((drink) => drink.toMap()).toList(),
      'waterReminders': waterReminders.map((reminder) => reminder.toMap()).toList(),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final startParts = map['reminderStartTime'].split(':');
    final endParts = map['reminderEndTime'].split(':');
    
    List<CustomDrink> drinks = [];
    if (map['customDrinks'] != null) {
      drinks = (map['customDrinks'] as List)
          .map((drinkMap) => CustomDrink.fromMap(drinkMap))
          .toList();
    }
    
    List<WaterReminder> reminders = [];
    if (map['waterReminders'] != null) {
      reminders = (map['waterReminders'] as List)
          .map((reminderMap) => WaterReminder.fromMap(reminderMap))
          .toList();
    }
    
    return UserSettings(
      dailyGoal: map['dailyGoal'] ?? 2000,
      reminderInterval: map['reminderInterval'] ?? 60,
      reminderStartTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      reminderEndTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      defaultAmount: map['defaultAmount'] ?? 250,
      isDarkMode: map['isDarkMode'] ?? false,
      language: map['language'] ?? 'ko',
      notificationsEnabled: map['notificationsEnabled'] ?? false,
      persistentNotificationEnabled: map['persistentNotificationEnabled'] ?? false,
      customDrinks: drinks,
      waterReminders: reminders,
    );
  }
}