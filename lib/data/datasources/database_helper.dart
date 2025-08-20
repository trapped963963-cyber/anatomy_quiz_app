import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anatomy_quiz_app/data/models/models.dart'; // A helper file we'll create

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'mcq_app_db.db');

    // Check if the database exists
    bool dbExists = await databaseExists(path);

    if (!dbExists) {
      // If not, copy from assets
      try {
        ByteData data = await rootBundle.load(join('assets/db', 'mcq_app_db.db'));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print("Error copying database: $e");
      }
    }

    // Open the database
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  // This function is only called if the database is created for the first time
  // by `openDatabase`. It's our safety net to ensure the stats table exists.
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS level_stats (
        level_id INTEGER PRIMARY KEY,
        completed_steps INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        last_visited TEXT NOT NULL
      )
    ''');
  }

  // --- Data Fetching Methods ---

  Future<List<AnatomicalDiagram>> getDiagrams() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('diagrams');

    return List.generate(maps.length, (i) {
      return AnatomicalDiagram.fromMap(maps[i]);
    });
  }
  
  Future<List<Label>> getLabelsForDiagram(int diagramId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'labels',
      where: 'diagram_id = ?',
      whereArgs: [diagramId],
    );

    return List.generate(maps.length, (i) {
      return Label.fromMap(maps[i]);
    });
  }
  
  Future<bool> validatePromoCode(String hash) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'promo_codes',
      where: 'hash = ?',
      whereArgs: [hash],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // --- User Progress Methods ---

  Future<Map<int, LevelStat>> getAllLevelStats() async {
    final db = await database;
    // Ensure the table exists before querying.
    await _createDb(db, 1);
    final List<Map<String, dynamic>> maps = await db.query('level_stats');
    
    Map<int, LevelStat> stats = {};
    for (var map in maps) {
      final stat = LevelStat.fromMap(map);
      stats[stat.levelId] = stat;
    }
    return stats;
  }

  Future<void> updateLevelStat(LevelStat stat) async {
    final db = await database;
    await db.insert(
      'level_stats',
      stat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getLabelsCountForDiagram(int diagramId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM labels WHERE diagram_id = ?',
      [diagramId],
    );
    // This is an efficient way to get a single integer value from a query.
    return Sqflite.firstIntValue(result) ?? 0;
  }
}