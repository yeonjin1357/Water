import 'dart:async';
import 'package:flutter/material.dart';
import '../models/water_intake.dart';
import '../models/user_settings.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import '../localization/app_localizations.dart';

class WaterIntakeProvider extends ChangeNotifier {
  List<WaterIntake> _todayIntakes = [];
  UserSettings _userSettings = UserSettings();
  int _todayTotal = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PreferencesService _prefsService = PreferencesService();
  final NotificationService _notificationService = NotificationService();
  Timer? _midnightTimer;
  DateTime? _lastLoadedDate;

  List<WaterIntake> get todayIntakes => _todayIntakes;
  UserSettings get userSettings => _userSettings;
  int get todayTotal => _todayTotal;
  double get progress => _todayTotal / _userSettings.dailyGoal;

  Future<void> addWaterIntake(int amount, {String? note, String drinkType = 'Water'}) async {
    final intake = WaterIntake(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
      drinkType: drinkType,
    );

    await _dbHelper.insertIntake(intake);
    // 새로운 리스트를 생성하여 변경 감지가 제대로 되도록 함
    _todayIntakes = [..._todayIntakes, intake];
    _todayTotal += amount;
    
    // Update persistent notification if enabled
    if (_userSettings.persistentNotificationEnabled) {
      await _notificationService.showPersistentNotification(
        currentAmount: _todayTotal,
        dailyGoal: _userSettings.dailyGoal,
      );
    }
    
    notifyListeners();
  }

  Future<void> removeIntake(String id) async {
    // Try to find the intake in today's list first
    final todayIntakeIndex = _todayIntakes.indexWhere((i) => i.id == id);
    
    // Delete from database regardless of whether it's today's intake
    await _dbHelper.deleteIntake(id);
    
    // Only update today's totals if it's a today intake
    if (todayIntakeIndex != -1) {
      final intake = _todayIntakes[todayIntakeIndex];
      _todayTotal -= intake.amount;
      // 새로운 리스트를 생성하여 변경 감지가 제대로 되도록 함
      _todayIntakes = [
        ..._todayIntakes.sublist(0, todayIntakeIndex),
        ..._todayIntakes.sublist(todayIntakeIndex + 1)
      ];
      
      // Update persistent notification if enabled
      if (_userSettings.persistentNotificationEnabled) {
        await _notificationService.showPersistentNotification(
          currentAmount: _todayTotal,
          dailyGoal: _userSettings.dailyGoal,
        );
      }
    }
    
    notifyListeners();
  }

  Future<void> updateIntake(WaterIntake updatedIntake) async {
    await _dbHelper.updateIntake(updatedIntake);
    
    // 오늘 날짜 확인
    final today = DateTime.now();
    final intakeDate = DateTime(
      updatedIntake.timestamp.year,
      updatedIntake.timestamp.month,
      updatedIntake.timestamp.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // 오늘 날짜의 intake인 경우만 로컬 리스트 업데이트
    if (intakeDate == todayDate) {
      final index = _todayIntakes.indexWhere((i) => i.id == updatedIntake.id);
      if (index != -1) {
        final oldAmount = _todayIntakes[index].amount;
        // 새로운 리스트를 생성하여 변경 감지가 제대로 되도록 함
        _todayIntakes = [
          ..._todayIntakes.sublist(0, index),
          updatedIntake,
          ..._todayIntakes.sublist(index + 1)
        ];
        _todayTotal = _todayTotal - oldAmount + updatedIntake.amount;
      }
    }
    
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    final oldPersistentEnabled = _userSettings.persistentNotificationEnabled;
    final oldReminders = _userSettings.waterReminders;
    _userSettings = newSettings;
    await _prefsService.saveSettings(newSettings);
    AppLocalizations.setLanguage(newSettings.language);
    
    // Handle persistent notification changes
    if (newSettings.persistentNotificationEnabled && !oldPersistentEnabled) {
      // Show persistent notification if just enabled
      await _notificationService.showPersistentNotification(
        currentAmount: _todayTotal,
        dailyGoal: newSettings.dailyGoal,
      );
    } else if (!newSettings.persistentNotificationEnabled && oldPersistentEnabled) {
      // Hide persistent notification if just disabled
      await _notificationService.hidePersistentNotification();
    } else if (newSettings.persistentNotificationEnabled) {
      // Update if goal changed while enabled
      await _notificationService.showPersistentNotification(
        currentAmount: _todayTotal,
        dailyGoal: newSettings.dailyGoal,
      );
    }
    
    // Re-schedule water reminder notifications if they changed
    // Note: This is already handled in notification_settings_dialog.dart when saving
    // but we should ensure it's done here too for consistency
    if (newSettings.waterReminders != oldReminders) {
      await _notificationService.scheduleWaterReminderNotifications(newSettings.waterReminders);
    }
    
    notifyListeners();
  }

  Future<void> loadTodayData() async {
    final today = DateTime.now();
    _lastLoadedDate = today;
    _todayIntakes = await _dbHelper.getIntakesByDate(today);
    _todayTotal = _todayIntakes.fold(0, (sum, intake) => sum + intake.amount);
    
    // Show persistent notification if enabled
    if (_userSettings.persistentNotificationEnabled) {
      await _notificationService.showPersistentNotification(
        currentAmount: _todayTotal,
        dailyGoal: _userSettings.dailyGoal,
      );
    }
    
    notifyListeners();
  }

  void resetToday() {
    // 새로운 리스트를 생성하여 변경 감지가 제대로 되도록 함
    _todayIntakes = [];
    _todayTotal = 0;
    notifyListeners();
  }

  Future<void> initialize() async {
    _userSettings = await _prefsService.loadSettings();
    AppLocalizations.setLanguage(_userSettings.language);
    await loadTodayData();
    _setupMidnightTimer();
    
    // Re-schedule water reminder notifications on app start
    if (_userSettings.waterReminders.isNotEmpty) {
      await _notificationService.scheduleWaterReminderNotifications(_userSettings.waterReminders);
    }
  }
  
  void _setupMidnightTimer() {
    _midnightTimer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    
    _midnightTimer = Timer(timeUntilMidnight, () async {
      await loadTodayData();
      _setupMidnightTimer();
    });
  }
  
  Future<void> checkAndReloadIfNeeded() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (_lastLoadedDate != null) {
      final lastDate = DateTime(_lastLoadedDate!.year, _lastLoadedDate!.month, _lastLoadedDate!.day);
      if (todayDate != lastDate) {
        await loadTodayData();
      }
    }
  }
  
  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<List<WaterIntake>> getAllIntakes() async {
    return await _dbHelper.getAllIntakes();
  }

  Future<List<WaterIntake>> getIntakesBetween(DateTime start, DateTime end) async {
    return await _dbHelper.getIntakesBetween(start, end);
  }

  Future<List<WaterIntake>> getIntakesByDate(DateTime date) async {
    return await _dbHelper.getIntakesByDate(date);
  }

  Future<Map<String, int>> getWeeklyStats() async {
    return await _dbHelper.getWeeklyStats();
  }

  Future<Map<String, int>> getMonthlyStats(int year, int month) async {
    return await _dbHelper.getMonthlyStats(year, month);
  }

  Future<Map<String, int>> getYearlyStats(int year) async {
    return await _dbHelper.getYearlyStats(year);
  }

  Future<Map<String, int>> getDrinkTypeStats(DateTime start, DateTime end) async {
    return await _dbHelper.getDrinkTypeStats(start, end);
  }

  Future<int> getStreakDays() async {
    return await _dbHelper.getStreakDays(_userSettings.dailyGoal);
  }

  Future<double> getCompletionRate(DateTime date) async {
    return await _dbHelper.getCompletionRate(date, _userSettings.dailyGoal);
  }

  // 한 달치 일일 진행률 데이터를 한 번에 가져오기
  Future<Map<DateTime, double>> getMonthlyProgress(int year, int month) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    Map<DateTime, double> progress = {};
    
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      
      // 미래 날짜는 건너뜀
      if (date.isAfter(DateTime.now())) continue;
      
      final intakes = await _dbHelper.getIntakesByDate(date);
      final totalAmount = intakes.fold(0, (sum, intake) => sum + intake.amount);
      progress[date] = (totalAmount / _userSettings.dailyGoal).clamp(0.0, 1.0);
    }
    
    return progress;
  }

  // Custom drink methods
  Future<void> addCustomDrink(CustomDrink drink) async {
    final updatedDrinks = [..._userSettings.customDrinks, drink];
    _userSettings = UserSettings(
      dailyGoal: _userSettings.dailyGoal,
      reminderInterval: _userSettings.reminderInterval,
      reminderStartTime: _userSettings.reminderStartTime,
      reminderEndTime: _userSettings.reminderEndTime,
      defaultAmount: _userSettings.defaultAmount,
      isDarkMode: _userSettings.isDarkMode,
      language: _userSettings.language,
      notificationsEnabled: _userSettings.notificationsEnabled,
      persistentNotificationEnabled: _userSettings.persistentNotificationEnabled,
      customDrinks: updatedDrinks,
    );
    await _prefsService.saveSettings(_userSettings);
    notifyListeners();
  }

  Future<void> removeCustomDrink(String drinkId) async {
    final updatedDrinks = _userSettings.customDrinks
        .where((drink) => drink.id != drinkId)
        .toList();
    _userSettings = UserSettings(
      dailyGoal: _userSettings.dailyGoal,
      reminderInterval: _userSettings.reminderInterval,
      reminderStartTime: _userSettings.reminderStartTime,
      reminderEndTime: _userSettings.reminderEndTime,
      defaultAmount: _userSettings.defaultAmount,
      isDarkMode: _userSettings.isDarkMode,
      language: _userSettings.language,
      notificationsEnabled: _userSettings.notificationsEnabled,
      persistentNotificationEnabled: _userSettings.persistentNotificationEnabled,
      customDrinks: updatedDrinks,
    );
    await _prefsService.saveSettings(_userSettings);
    notifyListeners();
  }

  Future<void> updateCustomDrink(CustomDrink drink) async {
    final updatedDrinks = _userSettings.customDrinks.map((d) {
      return d.id == drink.id ? drink : d;
    }).toList();
    _userSettings = UserSettings(
      dailyGoal: _userSettings.dailyGoal,
      reminderInterval: _userSettings.reminderInterval,
      reminderStartTime: _userSettings.reminderStartTime,
      reminderEndTime: _userSettings.reminderEndTime,
      defaultAmount: _userSettings.defaultAmount,
      isDarkMode: _userSettings.isDarkMode,
      language: _userSettings.language,
      notificationsEnabled: _userSettings.notificationsEnabled,
      persistentNotificationEnabled: _userSettings.persistentNotificationEnabled,
      customDrinks: updatedDrinks,
    );
    await _prefsService.saveSettings(_userSettings);
    notifyListeners();
  }
}