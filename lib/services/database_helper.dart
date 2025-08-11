import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/water_intake.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'water_reminder.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water_intakes (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT,
        drinkType TEXT DEFAULT 'Water'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 컬럼이 이미 존재하는지 확인
      final List<Map<String, dynamic>> tableInfo = await db.rawQuery('PRAGMA table_info(water_intakes)');
      final bool columnExists = tableInfo.any((column) => column['name'] == 'drinkType');
      
      if (!columnExists) {
        await db.execute('ALTER TABLE water_intakes ADD COLUMN drinkType TEXT DEFAULT "Water"');
      }
    }
  }

  Future<int> insertIntake(WaterIntake intake) async {
    final db = await database;
    return await db.insert(
      'water_intakes',
      intake.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WaterIntake>> getIntakesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'water_intakes',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return WaterIntake.fromMap(maps[i]);
    });
  }

  Future<int> deleteIntake(String id) async {
    final db = await database;
    return await db.delete(
      'water_intakes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateIntake(WaterIntake intake) async {
    final db = await database;
    return await db.update(
      'water_intakes',
      intake.toMap(),
      where: 'id = ?',
      whereArgs: [intake.id],
    );
  }

  Future<Map<String, int>> getWeeklyStats() async {
    final Map<String, int> stats = {};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final intakes = await getIntakesByDate(date);
      final total = intakes.fold<int>(0, (sum, intake) => sum + intake.amount);
      stats[date.toString().split(' ')[0]] = total;
    }

    return stats;
  }

  Future<List<WaterIntake>> getAllIntakes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'water_intakes',
      orderBy: 'timestamp DESC',
    );
    
    return List.generate(maps.length, (i) {
      return WaterIntake.fromMap(maps[i]);
    });
  }

  Future<List<WaterIntake>> getIntakesBetween(
      DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'water_intakes',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return WaterIntake.fromMap(maps[i]);
    });
  }

  Future<int> getTotalForDate(DateTime date) async {
    final intakes = await getIntakesByDate(date);
    return intakes.fold<int>(0, (sum, intake) => sum + intake.amount);
  }

  Future<Map<String, int>> getMonthlyStats(int year, int month) async {
    final Map<String, int> stats = {};
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final total = await getTotalForDate(date);
      stats[date.toString().split(' ')[0]] = total;
    }
    
    return stats;
  }

  Future<Map<String, int>> getYearlyStats(int year) async {
    final Map<String, int> stats = {};
    
    for (int month = 1; month <= 12; month++) {
      int monthTotal = 0;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final dayTotal = await getTotalForDate(date);
        monthTotal += dayTotal;
      }
      
      stats['$year-${month.toString().padLeft(2, '0')}'] = monthTotal;
    }
    
    return stats;
  }

  Future<Map<String, int>> getDrinkTypeStats(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT drinkType, SUM(amount) as total
      FROM water_intakes
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY drinkType
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    final Map<String, int> stats = {};
    for (var row in result) {
      stats[row['drinkType'] ?? 'Water'] = row['total'] as int;
    }
    return stats;
  }

  // 최적화된 배치 쿼리 메서드들
  Future<Map<String, int>> getDailyTotalsBetween(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        DATE(timestamp) as date,
        SUM(amount) as total
      FROM water_intakes
      WHERE timestamp >= ? AND timestamp < ?
      GROUP BY DATE(timestamp)
      ORDER BY date
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    final Map<String, int> dailyTotals = {};
    for (var row in result) {
      dailyTotals[row['date'] as String] = row['total'] as int;
    }
    
    // 범위 내 모든 날짜에 대해 값 채우기 (없는 날은 0)
    DateTime currentDate = start;
    while (currentDate.isBefore(end)) {
      final dateKey = currentDate.toIso8601String().split('T')[0];
      dailyTotals.putIfAbsent(dateKey, () => 0);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return dailyTotals;
  }

  // 최적화된 주간 통계
  Future<Map<String, int>> getWeeklyStatsOptimized(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return await getDailyTotalsBetween(weekStart, weekEnd);
  }

  // 최적화된 월간 통계 (주 단위 평균)
  Future<Map<String, int>> getMonthlyStatsOptimized(int year, int month) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final endDay = lastDay.add(const Duration(days: 1));
    
    final dailyTotals = await getDailyTotalsBetween(firstDay, endDay);
    
    // 주 단위로 그룹화
    final Map<String, int> weeklyStats = {};
    for (int week = 0; week < 5; week++) {
      int weekTotal = 0;
      int dayCount = 0;
      
      for (int day = week * 7 + 1; day <= lastDay.day && day <= (week + 1) * 7; day++) {
        final date = DateTime(year, month, day);
        final dateKey = date.toIso8601String().split('T')[0];
        final dayTotal = dailyTotals[dateKey] ?? 0;
        weekTotal += dayTotal;
        if (dayTotal > 0) dayCount++;
      }
      
      final weekKey = 'week_$week';
      weeklyStats[weekKey] = dayCount > 0 ? (weekTotal / dayCount).round() : 0;
    }
    
    return weeklyStats;
  }

  // 최적화된 연간 통계 (월 단위 평균)
  Future<Map<String, int>> getYearlyStatsOptimized(int year) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        strftime('%m', timestamp) as month,
        SUM(amount) as total,
        COUNT(DISTINCT DATE(timestamp)) as days
      FROM water_intakes
      WHERE timestamp >= ? AND timestamp < ?
      GROUP BY strftime('%m', timestamp)
      ORDER BY month
    ''', [
      DateTime(year, 1, 1).toIso8601String(),
      DateTime(year + 1, 1, 1).toIso8601String()
    ]);
    
    final Map<String, int> monthlyStats = {};
    
    for (int month = 1; month <= 12; month++) {
      final monthStr = month.toString().padLeft(2, '0');
      final monthData = result.firstWhere(
        (row) => row['month'] == monthStr,
        orElse: () => {'total': 0, 'days': 0},
      );
      
      final total = monthData['total'] as int? ?? 0;
      final days = monthData['days'] as int? ?? 0;
      
      final monthKey = 'month_${month - 1}';
      monthlyStats[monthKey] = days > 0 ? (total / days).round() : 0;
    }
    
    return monthlyStats;
  }

  Future<int> getStreakDays(int dailyGoal) async {
    final db = await database;
    final today = DateTime.now();
    
    // 최근 365일간의 데이터를 한 번에 가져오기 (충분한 범위)
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        DATE(timestamp) as date,
        SUM(amount) as total
      FROM water_intakes
      WHERE timestamp >= ? AND timestamp < ?
      GROUP BY DATE(timestamp)
      ORDER BY date DESC
    ''', [
      today.subtract(const Duration(days: 365)).toIso8601String(),
      today.add(const Duration(days: 1)).toIso8601String()
    ]);
    
    int streak = 0;
    DateTime checkDate = today;
    
    for (var row in result) {
      final dateStr = row['date'] as String;
      final checkDateStr = checkDate.toIso8601String().split('T')[0];
      
      // 날짜가 연속적인지 확인
      if (dateStr == checkDateStr) {
        final total = row['total'] as int;
        if (total >= dailyGoal) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          // 목표량 미달성 시 연속 기록 중단
          break;
        }
      } else if (dateStr.compareTo(checkDateStr) < 0) {
        // 데이터가 없는 날 = 목표 미달성으로 간주
        break;
      }
    }
    
    return streak;
  }

  Future<double> getCompletionRate(DateTime date, int dailyGoal) async {
    final total = await getTotalForDate(date);
    return (total / dailyGoal * 100).clamp(0, 100);
  }
}