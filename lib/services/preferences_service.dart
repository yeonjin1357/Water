import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static const String _dailyGoalKey = 'daily_goal';
  static const String _reminderIntervalKey = 'reminder_interval';
  static const String _reminderStartKey = 'reminder_start';
  static const String _reminderEndKey = 'reminder_end';
  static const String _defaultAmountKey = 'default_amount';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _languageKey = 'language';

  Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final startTimeString = prefs.getString(_reminderStartKey) ?? '8:0';
    final endTimeString = prefs.getString(_reminderEndKey) ?? '22:0';

    final startParts = startTimeString.split(':');
    final endParts = endTimeString.split(':');

    return UserSettings(
      dailyGoal: prefs.getInt(_dailyGoalKey) ?? 2000,
      reminderInterval: prefs.getInt(_reminderIntervalKey) ?? 60,
      reminderStartTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      reminderEndTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      defaultAmount: prefs.getInt(_defaultAmountKey) ?? 250,
      isDarkMode: prefs.getBool(_isDarkModeKey) ?? false,
      language: prefs.getString(_languageKey) ?? 'ko',
    );
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_dailyGoalKey, settings.dailyGoal);
    await prefs.setInt(_reminderIntervalKey, settings.reminderInterval);
    await prefs.setString(
      _reminderStartKey,
      '${settings.reminderStartTime.hour}:${settings.reminderStartTime.minute}',
    );
    await prefs.setString(
      _reminderEndKey,
      '${settings.reminderEndTime.hour}:${settings.reminderEndTime.minute}',
    );
    await prefs.setInt(_defaultAmountKey, settings.defaultAmount);
    await prefs.setBool(_isDarkModeKey, settings.isDarkMode);
    await prefs.setString(_languageKey, settings.language);
  }
}