import 'package:flutter/material.dart';
import '../models/water_intake.dart';
import '../models/user_settings.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../localization/app_localizations.dart';

class WaterIntakeProvider extends ChangeNotifier {
  List<WaterIntake> _todayIntakes = [];
  UserSettings _userSettings = UserSettings();
  int _todayTotal = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PreferencesService _prefsService = PreferencesService();

  List<WaterIntake> get todayIntakes => _todayIntakes;
  UserSettings get userSettings => _userSettings;
  int get todayTotal => _todayTotal;
  double get progress => _todayTotal / _userSettings.dailyGoal;

  Future<void> addWaterIntake(int amount, {String? note, String drinkType = 'water'}) async {
    final intake = WaterIntake(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
      drinkType: drinkType,
    );

    await _dbHelper.insertIntake(intake);
    _todayIntakes.add(intake);
    _todayTotal += amount;
    notifyListeners();
  }

  Future<void> removeIntake(String id) async {
    final intake = _todayIntakes.firstWhere((i) => i.id == id);
    await _dbHelper.deleteIntake(id);
    _todayTotal -= intake.amount;
    _todayIntakes.removeWhere((i) => i.id == id);
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
        _todayIntakes[index] = updatedIntake;
        _todayTotal = _todayTotal - oldAmount + updatedIntake.amount;
      }
    }
    
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _userSettings = newSettings;
    await _prefsService.saveSettings(newSettings);
    AppLocalizations.setLanguage(newSettings.language);
    notifyListeners();
  }

  Future<void> loadTodayData() async {
    final today = DateTime.now();
    _todayIntakes = await _dbHelper.getIntakesByDate(today);
    _todayTotal = _todayIntakes.fold(0, (sum, intake) => sum + intake.amount);
    notifyListeners();
  }

  void resetToday() {
    _todayIntakes.clear();
    _todayTotal = 0;
    notifyListeners();
  }

  Future<void> initialize() async {
    _userSettings = await _prefsService.loadSettings();
    AppLocalizations.setLanguage(_userSettings.language);
    await loadTodayData();
  }

  Future<List<WaterIntake>> getAllIntakes() async {
    return await _dbHelper.getAllIntakes();
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
}