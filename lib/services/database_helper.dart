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

  Future<int> getStreakDays(int dailyGoal) async {
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    while (true) {
      final total = await getTotalForDate(currentDate);
      if (total >= dailyGoal) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
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