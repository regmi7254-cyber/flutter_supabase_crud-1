import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class SQLiteScreen extends StatefulWidget {
  @override
  _SQLiteScreenState createState() => _SQLiteScreenState();
}

class _SQLiteScreenState extends State<SQLiteScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = false;
  int? _editingId;
  Map<String, dynamic>? _databaseStats;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _loadNotes();
      await _loadDatabaseStats();
      
      // Add sample data if database is empty
      if (_notes.isEmpty) {
        await _addSampleData();
      }
    } catch (e) {
      print('Error initializing app: $e');
      _showSnackBar('Error initializing app: $e');
    }
  }

  Future<void> _addSampleData() async {
    try {
      final sampleNotes = [
        Note(
          title: 'Welcome Note',
          content: 'Welcome to the Flutter SQLite CRUD app! This is your first note.',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
        Note(
          title: 'Shopping List',
          content: 'Milk, Bread, Eggs, Vegetables, Fruits, Meat',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
        Note(
          title: 'Meeting Notes',
          content: 'Team meeting tomorrow at 2 PM. Agenda: Project updates, Q&A session, Next steps',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ];

      for (var note in sampleNotes) {
        await _databaseService.insertNote(note);
      }

      await _loadNotes();
      await _loadDatabaseStats();
      _showSnackBar('Sample data added successfully');
    } catch (e) {
      print('Error adding sample data: $e');
      _showSnackBar('Error adding sample data: $e');
    }
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Loading notes...');
      final notes = await _databaseService.getNotes();
      print('📝 Loaded ${notes.length} notes');
      setState(() {
        _notes = notes;
        _filteredNotes = notes;
      });
    } catch (e) {
      print('❌ Error loading notes: $e');
      _showSnackBar('Error loading notes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDatabaseStats() async {
    try {
      print('📊 Loading database stats...');
      final stats = await _databaseService.getDatabaseStats();
      print('📈 Database stats: $stats');
      setState(() => _databaseStats = stats);
    } catch (e) {
      print('❌ Error loading stats: $e');
      // Don't show snackbar for stats errors as they're not critical
    }
  }

  Future<void> _addNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    final note = Note(
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    try {
      await _databaseService.insertNote(note);
      _titleController.clear();
      _contentController.clear();
      await _loadNotes();
      await _loadDatabaseStats();
      _showSnackBar('Note added successfully');
    } catch (e) {
      _showSnackBar('Error adding note: $e');
    }
  }

  Future<void> _updateNote() async {
    if (_editingId == null) {
      _showSnackBar('No note selected for editing');
      return;
    }

    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    final note = Note(
      id: _editingId,
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    try {
      await _databaseService.updateNote(note);
      _titleController.clear();
      _contentController.clear();
      setState(() => _editingId = null);
      await _loadNotes();
      await _loadDatabaseStats();
      _showSnackBar('Note updated successfully');
    } catch (e) {
      _showSnackBar('Error updating note: $e');
    }
  }

  Future<void> _deleteNote(int id) async {
    try {
      await _databaseService.deleteNote(id);
      await _loadNotes();
      await _loadDatabaseStats();
      _showSnackBar('Note deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting note: $e');
    }
  }

  Future<void> _deleteAllNotes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete All'),
        content: Text('Are you sure you want to delete all notes? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteAllNotes();
        await _loadNotes();
        await _loadDatabaseStats();
        _showSnackBar('All notes deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting all notes: $e');
      }
    }
  }

  void _startEditing(Note note) {
    setState(() {
      _editingId = note.id;
      _titleController.text = note.title;
      _contentController.text = note.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingId = null;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredNotes = _notes);
      return;
    }

    try {
      final results = await _databaseService.searchNotes(query);
      setState(() => _filteredNotes = results);
    } catch (e) {
      _showSnackBar('Error searching notes: $e');
    }
  }

  Future<void> _importFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        await _databaseService.importFromJson(jsonString);
        await _loadNotes();
        await _loadDatabaseStats();
        _showSnackBar('JSON imported successfully');
      }
    } catch (e) {
      _showSnackBar('Error importing JSON: $e');
    }
  }

  Future<void> _exportToJson() async {
    try {
      final jsonString = await _databaseService.exportToJson();
      final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = await _databaseService.saveToFile(jsonString, fileName);
      _showSnackBar('JSON exported to: $filePath');
    } catch (e) {
      _showSnackBar('Error exporting JSON: $e');
    }
  }

  Future<void> _importFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final csvString = await file.readAsString();
        await _databaseService.importFromCsv(csvString);
        await _loadNotes();
        await _loadDatabaseStats();
        _showSnackBar('CSV imported successfully');
      }
    } catch (e) {
      _showSnackBar('Error importing CSV: $e');
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final csvString = await _databaseService.exportToCsv();
      final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _databaseService.saveToFile(csvString, fileName);
      _showSnackBar('CSV exported to: $filePath');
    } catch (e) {
      _showSnackBar('Error exporting CSV: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite Database'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import_json':
                  _importFromJson();
                  break;
                case 'export_json':
                  _exportToJson();
                  break;
                case 'import_csv':
                  _importFromCsv();
                  break;
                case 'export_csv':
                  _exportToCsv();
                  break;
                case 'delete_all':
                  _deleteAllNotes();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import_json',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Import JSON'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_json',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export JSON'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Import CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Database Stats
          if (_databaseStats != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Total: ${_databaseStats!['total_notes']}'),
                  Text('Oldest: ${_databaseStats!['oldest_note']?.substring(0, 10) ?? 'N/A'}'),
                  Text('Newest: ${_databaseStats!['newest_note']?.substring(0, 10) ?? 'N/A'}'),
                ],
              ),
            ),
          
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchNotes('');
                  },
                ),
              ),
              onChanged: _searchNotes,
            ),
          ),

          // Input Form
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _editingId == null ? _addNote : _updateNote,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: Text(_editingId == null ? 'Add Note' : 'Update Note'),
                      ),
                    ),
                    if (_editingId != null) ...[
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _cancelEditing,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          child: Text('Cancel'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? Center(child: Text('No notes found'))
                    : ListView.builder(
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(note.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note.content),
                                  SizedBox(height: 4),
                                  Text(
                                    'ID: ${note.id} | Created: ${note.createdAt.substring(0, 19)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => _startEditing(note),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _deleteNote(note.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 