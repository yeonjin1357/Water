import 'package:flutter/material.dart';

class UserSettings {
  final int dailyGoal;
  final int reminderInterval;
  final TimeOfDay reminderStartTime;
  final TimeOfDay reminderEndTime;
  final int defaultAmount;
  final bool isDarkMode;
  final String language;

  UserSettings({
    this.dailyGoal = 2000,
    this.reminderInterval = 60,
    this.reminderStartTime = const TimeOfDay(hour: 8, minute: 0),
    this.reminderEndTime = const TimeOfDay(hour: 22, minute: 0),
    this.defaultAmount = 250,
    this.isDarkMode = false,
    this.language = 'ko',
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
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final startParts = map['reminderStartTime'].split(':');
    final endParts = map['reminderEndTime'].split(':');
    
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
    );
  }
}