import 'package:flutter/material.dart';
import '../models/water_intake.dart';
import '../models/user_settings.dart';

class WaterIntakeProvider extends ChangeNotifier {
  List<WaterIntake> _todayIntakes = [];
  UserSettings _userSettings = UserSettings();
  int _todayTotal = 0;

  List<WaterIntake> get todayIntakes => _todayIntakes;
  UserSettings get userSettings => _userSettings;
  int get todayTotal => _todayTotal;
  double get progress => _todayTotal / _userSettings.dailyGoal;

  void addWaterIntake(int amount, {String? note}) {
    final intake = WaterIntake(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
    );

    _todayIntakes.add(intake);
    _todayTotal += amount;
    notifyListeners();
  }

  void removeIntake(String id) {
    final intake = _todayIntakes.firstWhere((i) => i.id == id);
    _todayTotal -= intake.amount;
    _todayIntakes.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void updateSettings(UserSettings newSettings) {
    _userSettings = newSettings;
    notifyListeners();
  }

  void loadTodayData() {
    // TODO: 데이터베이스에서 오늘 데이터 로드
    final today = DateTime.now();
    _todayIntakes = [];
    _todayTotal = _todayIntakes.fold(0, (sum, intake) => sum + intake.amount);
    notifyListeners();
  }

  void resetToday() {
    _todayIntakes.clear();
    _todayTotal = 0;
    notifyListeners();
  }
}