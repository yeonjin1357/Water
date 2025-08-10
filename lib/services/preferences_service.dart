import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class PreferencesService {
  static const String _dailyGoalKey = 'daily_goal';
  static const String _reminderIntervalKey = 'reminder_interval';
  static const String _reminderStartKey = 'reminder_start';
  static const String _reminderEndKey = 'reminder_end';
  static const String _defaultAmountKey = 'default_amount';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _languageKey = 'language';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _persistentNotificationKey = 'persistent_notification';
  static const String _customDrinksKey = 'custom_drinks';
  static const String _waterRemindersKey = 'water_reminders';

  Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final startTimeString = prefs.getString(_reminderStartKey) ?? '8:0';
    final endTimeString = prefs.getString(_reminderEndKey) ?? '22:0';

    final startParts = startTimeString.split(':');
    final endParts = endTimeString.split(':');

    // Load custom drinks
    List<CustomDrink> customDrinks = [];
    final customDrinksJson = prefs.getString(_customDrinksKey);
    if (customDrinksJson != null) {
      try {
        final List<dynamic> drinksList = jsonDecode(customDrinksJson);
        customDrinks = drinksList
            .map((drinkMap) => CustomDrink.fromMap(drinkMap))
            .toList();
      } catch (e) {
        print('Error loading custom drinks: $e');
      }
    }

    // Load water reminders
    List<WaterReminder> waterReminders = [];
    final waterRemindersJson = prefs.getString(_waterRemindersKey);
    if (waterRemindersJson != null) {
      try {
        final List<dynamic> remindersList = jsonDecode(waterRemindersJson);
        waterReminders = remindersList
            .map((reminderMap) => WaterReminder.fromMap(reminderMap))
            .toList();
      } catch (e) {
        print('Error loading water reminders: $e');
      }
    }

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
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? false,
      persistentNotificationEnabled: prefs.getBool(_persistentNotificationKey) ?? false,
      customDrinks: customDrinks,
      waterReminders: waterReminders,
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
    await prefs.setBool(_notificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setBool(_persistentNotificationKey, settings.persistentNotificationEnabled);
    
    // Save custom drinks
    final customDrinksList = settings.customDrinks.map((drink) => drink.toMap()).toList();
    await prefs.setString(_customDrinksKey, jsonEncode(customDrinksList));
    
    // Save water reminders
    final waterRemindersList = settings.waterReminders.map((reminder) => reminder.toMap()).toList();
    await prefs.setString(_waterRemindersKey, jsonEncode(waterRemindersList));
  }
}