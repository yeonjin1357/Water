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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water_intakes (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT
      )
    ''');
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

  Future<Map<String, int>> getWeeklyStats() async {
    final db = await database;
    final Map<String, int> stats = {};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final intakes = await getIntakesByDate(date);
      final total = intakes.fold(0, (sum, intake) => sum + intake.amount);
      stats[date.toString().split(' ')[0]] = total;
    }

    return stats;
  }
}