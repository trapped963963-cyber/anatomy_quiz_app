import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/core/utils/encryption_service.dart'; // ## ADD THIS IMPORT ##


class DatabaseHelper {
  
  final EncryptionService _encryptionService;
  DatabaseHelper(this._encryptionService);
  Database? _database;

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
            throw Exception("Fatal Error: Could not copy the database from assets. $e");
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

  Future<AnatomicalDiagram?> getDiagramById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diagrams',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1, // We only expect one result
    );

    if (maps.isNotEmpty) {
      final diagram =  AnatomicalDiagram.fromMap(maps.first);
      return diagram.copyWith(title: _encryptionService.decrypt(diagram.title));
    }
    return null;
  }
  
  Future<List<Label>> getLabelsForDiagram(int diagramId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'labels',
      where: 'diagram_id = ?',
      whereArgs: [diagramId],
    );
    
    return maps.map((map) {
      final label = Label.fromMap(map);
      return label.copyWith(
        title: _encryptionService.decrypt(label.title),
        definition: _encryptionService.decrypt(label.definition),
      );
    }).toList();
  
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

  Future<List<Unit>> getUnits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('units', orderBy: 'id');
    return maps.map((map) {
      final unit = Unit.fromMap(map);
      return Unit(
        id: unit.id,
        title: _encryptionService.decrypt(unit.title),
      );
    }).toList();
  }

  Future<List<AnatomicalDiagram>> getDiagramsForUnit(int unitId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diagrams',
      where: 'unit_id = ?',
      whereArgs: [unitId],
      orderBy: 'id',
    );
    return await Future.wait(maps.map((map) async {
      final diagram = AnatomicalDiagram.fromMap(map);
      final count = await getLabelsCountForDiagram(diagram.id);
      return diagram.copyWith(
        title: _encryptionService.decrypt(diagram.title),
        totalSteps: count
      );
    }));
  }

  Future<List<Label>> getLabelsForDiagrams(List<int> diagramIds) async {
    if (diagramIds.isEmpty) return [];
    final db = await database;
    // Use a 'WHERE IN' clause to get all labels for the selected diagrams at once.
    final placeholders = ('?' * diagramIds.length).split('').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'labels',
      where: 'diagram_id IN ($placeholders)',
      whereArgs: diagramIds,
    );

    // ## DECRYPT HERE ##
    return maps.map((map) {
      final label = Label.fromMap(map);
      return label.copyWith(
        title: _encryptionService.decrypt(label.title),
        definition: _encryptionService.decrypt(label.definition),
      );
    }).toList();  
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


 

  Future<Map<String, int>> getLabelCounts(List<int> diagramIds) async {
    if (diagramIds.isEmpty) return {'total': 0, 'withDef': 0};
    final db = await database;
    final placeholders = ('?' * diagramIds.length).split('').join(',');

    // Query 1: Get the total number of labels.
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) FROM labels WHERE diagram_id IN ($placeholders)',
      diagramIds,
    );
    final totalCount = Sqflite.firstIntValue(totalResult) ?? 0;

    // Query 2: Get the count of labels that have a non-empty definition.
    // We check for NULL, empty string '', and strings with only spaces ' '.
    final withDefResult = await db.rawQuery(
      "SELECT COUNT(*) FROM labels WHERE diagram_id IN ($placeholders) AND definition IS NOT NULL AND TRIM(definition) != ''",
      diagramIds,
    );
    final withDefCount = Sqflite.firstIntValue(withDefResult) ?? 0;

    return {'total': totalCount, 'withDef': withDefCount};
  }

/// 1. Performs a search on your 'search_index' table for multiple keywords.
Future<List<int>> searchDiagramIds(String query) async {
  final trimmedQuery = query.trim().toLowerCase();
  if (trimmedQuery.isEmpty) return [];
  final db = await database;

  // ## THE FIX: Split the search query into individual keywords ##
  // This RegExp splits the string by one or more whitespace characters,
  // automatically handling single spaces, multiple spaces, tabs, etc.
  final keywords = trimmedQuery.split(RegExp(r'\s+'));
  if (keywords.isEmpty) return [];

  // This will hold the diagram IDs that match ALL keywords.
  Set<int>? matchingIds;

  // Loop through each keyword to progressively filter the results.
  for (final keyword in keywords) {
    final List<Map<String, dynamic>> maps = await db.query(
      'search_index',
      distinct: true,
      columns: ['diagram_id'],
      where: 'keyword LIKE ?',
      whereArgs: ['%$keyword%'],
    );

    // Convert the query result to a Set for efficient filtering.
    final currentIds = maps.map((map) => map['diagram_id'] as int).toSet();

    if (matchingIds == null) {
      // For the first keyword, this is our starting set.
      matchingIds = currentIds;
    } else {
      // For subsequent keywords, find the intersection.
      // This keeps only the IDs that were also found in the previous search.
      matchingIds.retainAll(currentIds);
    }

    // If at any point our set becomes empty, no diagram matches all keywords.
    if (matchingIds.isEmpty) return [];
  }

  // Return the final list of IDs that matched all keywords.
  return matchingIds?.toList() ?? [];
}
  /// 2. Fetches full diagram data for a given list of IDs in a single, efficient query.
  Future<List<AnatomicalDiagram>> getDiagramsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = ('?' * ids.length).split('').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      'diagrams',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    // We still decrypt the titles and get the total steps for each diagram
    final diagrams = await Future.wait(maps.map((map) async {
      final diagram = AnatomicalDiagram.fromMap(map);
      final count = await getLabelsCountForDiagram(diagram.id);
      return diagram.copyWith(
        title: _encryptionService.decrypt(diagram.title),
        totalSteps: count,
      );
    }));

    // The database returns items in an arbitrary order, so we need to
    // re-sort them to match the order from our original search results.
    diagrams.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return diagrams;
  }
}