import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'notes.db');
      
      print('📁 Database path: $path');
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) {
          print('✅ Database opened successfully');
        },
      );
    } catch (e) {
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      print('✅ Database table created successfully');
    } catch (e) {
      print('❌ Database table creation error: $e');
      rethrow;
    }
  }

  // CREATE - Insert a new note
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  // READ - Get all notes
  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // READ - Get a single note by ID
  Future<Note?> getNote(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - Update a note
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // DELETE - Delete a note
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Delete all notes
  Future<int> deleteAllNotes() async {
    final db = await database;
    return await db.delete('notes');
  }

  // SEARCH - Search notes by title or content
  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // STATISTICS - Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM notes')
    ) ?? 0;
    
    final oldest = await db.rawQuery(
      'SELECT created_at FROM notes ORDER BY created_at ASC LIMIT 1'
    );
    
    final newest = await db.rawQuery(
      'SELECT created_at FROM notes ORDER BY created_at DESC LIMIT 1'
    );

    return {
      'total_notes': count,
      'oldest_note': oldest.isNotEmpty ? oldest.first['created_at'] : null,
      'newest_note': newest.isNotEmpty ? newest.first['created_at'] : null,
    };
  }

  // IMPORT - Import from JSON string
  Future<void> importFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = json.decode(jsonString);
      final db = await database;
      
      await db.transaction((txn) async {
        for (var item in jsonData) {
          await txn.insert('notes', {
            'title': item['title'] ?? '',
            'content': item['content'] ?? '',
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
    final notes = await getNotes();
    final List<Map<String, dynamic>> jsonData = notes.map((note) => note.toMap()).toList();
    return json.encode(jsonData);
  }

  // IMPORT - Import from CSV string
  Future<void> importFromCsv(String csvData) async {
    try {
      final lines = csvData.split('\n');
      final db = await database;
      
      await db.transaction((txn) async {
        // Skip header row
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty) {
            final parts = line.split(',');
            if (parts.length >= 2) {
              await txn.insert('notes', {
                'title': parts[0].replaceAll('"', ''),
                'content': parts[1].replaceAll('"', ''),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to import CSV: $e');
    }
  }

  // EXPORT - Export to CSV string
  Future<String> exportToCsv() async {
    final notes = await getNotes();
    final csvData = StringBuffer();
    csvData.writeln('title,content,created_at,updated_at');
    
    for (var note in notes) {
      csvData.writeln('"${note.title}","${note.content}","${note.createdAt}","${note.updatedAt}"');
    }
    
    return csvData.toString();
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
} 