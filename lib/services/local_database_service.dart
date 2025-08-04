import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../models/item.dart';

class LocalDatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'items.db');
      
      print('📁 Local Database path: $path');
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) {
          print('✅ Local Database opened successfully');
        },
      );
    } catch (e) {
      print('❌ Local Database initialization error: $e');
      rethrow;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      print('✅ Local Database table created successfully');
    } catch (e) {
      print('❌ Local Database table creation error: $e');
      rethrow;
    }
  }

  // CREATE - Insert a new item
  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  // READ - Get all items
  Future<List<Item>> getItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  // READ - Get a single item by ID
  Future<Item?> getItem(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - Update an item
  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      item.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // DELETE - Delete an item
  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Delete all items
  Future<int> deleteAllItems() async {
    final db = await database;
    return await db.delete('items');
  }

  // SEARCH - Search items by name or description
  Future<List<Item>> searchItems(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  // STATISTICS - Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM items')
    ) ?? 0;

    final oldest = await db.rawQuery(
      'SELECT created_at FROM items ORDER BY created_at ASC LIMIT 1'
    );

    final newest = await db.rawQuery(
      'SELECT created_at FROM items ORDER BY created_at DESC LIMIT 1'
    );

    return {
      'total_items': count,
      'oldest_item': oldest.isNotEmpty ? oldest.first['created_at'] : null,
      'newest_item': newest.isNotEmpty ? newest.first['created_at'] : null,
    };
  }

  // IMPORT - Import from JSON string
  Future<void> importFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = json.decode(jsonString);
      final db = await database;
      
      await db.transaction((txn) async {
        for (var item in jsonData) {
          await txn.insert('items', {
            'name': item['name'] ?? '',
            'description': item['description'] ?? '',
            'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': item['updated_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to import JSON: $e');
    }
  }

  // EXPORT - Export to JSON string
  Future<String> exportToJson() async {
    final items = await getItems();
    final List<Map<String, dynamic>> jsonData = items.map((item) => item.toMap()).toList();
    return json.encode(jsonData);
  }

  // IMPORT - Import from Excel file
  Future<void> importFromExcel(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final db = await database;
      
      await db.transaction((txn) async {
        for (var table in excel.tables.keys) {
          final sheet = excel.tables[table]!;
          
          // Skip header row
          for (int row = 1; row < sheet.maxRows; row++) {
            final name = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value?.toString() ?? '';
            final description = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value?.toString() ?? '';
            
            if (name.isNotEmpty) {
              await txn.insert('items', {
                'name': name,
                'description': description,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to import Excel: $e');
    }
  }

  // EXPORT - Export to Excel file
  Future<String> exportToExcel() async {
    try {
      final items = await getItems();
      final excel = Excel.createExcel();
      final sheet = excel['Items'];
      
      // Add headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Name';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'Description';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'Created At';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'Updated At';
      
      // Add data
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = item.name;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = item.description;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = item.createdAt.toIso8601String();
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = item.updatedAt.toIso8601String();
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'items_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export Excel: $e');
    }
  }

  // SAVE - Save data to file
  Future<String> saveToFile(String data, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(data);
    return file.path;
  }

  // LOAD - Load data from file
  Future<String> loadFromFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }

  // EXECUTE - Execute custom SQL query
  Future<List<Map<String, dynamic>>> executeSQLQuery(String query) async {
    try {
      final db = await database;
      final results = await db.rawQuery(query);
      return results;
    } catch (e) {
      throw Exception('Failed to execute SQL query: $e');
    }
  }

  // BULK INSERT - Insert multiple items at once
  Future<void> bulkInsertItems(List<Item> items) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        for (var item in items) {
          await txn.insert('items', item.toMap());
        }
      });
    } catch (e) {
      throw Exception('Failed to bulk insert items: $e');
    }
  }
} 