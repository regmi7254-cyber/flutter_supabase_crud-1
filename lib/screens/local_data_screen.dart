import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/item.dart';
import '../services/local_database_service.dart';

class LocalDataScreen extends StatefulWidget {
  @override
  _LocalDataScreenState createState() => _LocalDataScreenState();
}

class _LocalDataScreenState extends State<LocalDataScreen> {
  final LocalDatabaseService _databaseService = LocalDatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sqlQueryController = TextEditingController();
  
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  List<Map<String, dynamic>> _sqlQueryResults = [];
  bool _isLoading = false;
  int? _editingId;
  Map<String, dynamic>? _databaseStats;
  bool _showSQLQuery = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _loadItems();
      await _loadDatabaseStats();
      
      // Add sample data if database is empty
      if (_items.isEmpty) {
        await _addSampleData();
      }
    } catch (e) {
      print('Error initializing app: $e');
      _showSnackBar('Error initializing app: $e');
    }
  }

  Future<void> _addSampleData() async {
    try {
      final sampleItems = [
        Item(
          name: 'Sample Item 1',
          description: 'This is a sample item for demonstration',
        ),
        Item(
          name: 'Sample Item 2',
          description: 'Another sample item with different content',
        ),
        Item(
          name: 'Sample Item 3',
          description: 'Third sample item for comprehensive testing',
        ),
      ];

      for (var item in sampleItems) {
        await _databaseService.insertItem(item);
      }

      await _loadItems();
      await _loadDatabaseStats();
      _showSnackBar('Sample data added successfully');
    } catch (e) {
      _showSnackBar('Error adding sample data: $e');
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _databaseService.getItems();
      setState(() {
        _items = items;
        _filteredItems = items;
      });
    } catch (e) {
      _showSnackBar('Error loading items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDatabaseStats() async {
    try {
      final stats = await _databaseService.getDatabaseStats();
      setState(() => _databaseStats = stats);
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  Future<void> _addItem() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    final item = Item(
      name: _nameController.text,
      description: _descriptionController.text,
    );

    try {
      await _databaseService.insertItem(item);
      _nameController.clear();
      _descriptionController.clear();
      await _loadItems();
      await _loadDatabaseStats();
      _showSnackBar('Item added successfully');
    } catch (e) {
      _showSnackBar('Error adding item: $e');
    }
  }

  Future<void> _updateItem() async {
    if (_editingId == null) {
      _showSnackBar('No item selected for editing');
      return;
    }

    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    final item = Item(
      id: _editingId,
      name: _nameController.text,
      description: _descriptionController.text,
    );

    try {
      await _databaseService.updateItem(item);
      _nameController.clear();
      _descriptionController.clear();
      setState(() => _editingId = null);
      await _loadItems();
      await _loadDatabaseStats();
      _showSnackBar('Item updated successfully');
    } catch (e) {
      _showSnackBar('Error updating item: $e');
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await _databaseService.deleteItem(id);
      await _loadItems();
      await _loadDatabaseStats();
      _showSnackBar('Item deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting item: $e');
    }
  }

  Future<void> _deleteAllItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete All'),
        content: Text('Are you sure you want to delete all items? This action cannot be undone.'),
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
        await _databaseService.deleteAllItems();
        await _loadItems();
        await _loadDatabaseStats();
        _showSnackBar('All items deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting all items: $e');
      }
    }
  }

  void _startEditing(Item item) {
    setState(() {
      _editingId = item.id;
      _nameController.text = item.name;
      _descriptionController.text = item.description;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingId = null;
      _nameController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _searchItems(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredItems = _items);
      return;
    }

    try {
      final results = await _databaseService.searchItems(query);
      setState(() => _filteredItems = results);
    } catch (e) {
      _showSnackBar('Error searching items: $e');
    }
  }

  // JSON Import/Export
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
        await _loadItems();
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
      final fileName = 'items_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = await _databaseService.saveToFile(jsonString, fileName);
      _showSnackBar('JSON exported to: $filePath');
    } catch (e) {
      _showSnackBar('Error exporting JSON: $e');
    }
  }

  // Excel Import/Export
  Future<void> _importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        final filePath = result.files.single.path!;
        await _databaseService.importFromExcel(filePath);
        await _loadItems();
        await _loadDatabaseStats();
        _showSnackBar('Excel imported successfully');
      }
    } catch (e) {
      _showSnackBar('Error importing Excel: $e');
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final filePath = await _databaseService.exportToExcel();
      _showSnackBar('Excel exported to: $filePath');
    } catch (e) {
      _showSnackBar('Error exporting Excel: $e');
    }
  }

  // SQL Query
  Future<void> _executeSQLQuery() async {
    if (_sqlQueryController.text.isEmpty) {
      _showSnackBar('Please enter a SQL query');
      return;
    }

    setState(() {
      _isLoading = true;
      _sqlQueryResults = [];
    });

    try {
      final results = await _databaseService.executeSQLQuery(_sqlQueryController.text);
      setState(() {
        _sqlQueryResults = results;
        _isLoading = false;
      });
      _showSnackBar('SQL query executed successfully (${results.length} results)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error executing SQL query: $e');
    }
  }

  void _toggleSQLQuery() {
    setState(() {
      _showSQLQuery = !_showSQLQuery;
      if (!_showSQLQuery) {
        _sqlQueryResults = [];
        _sqlQueryController.clear();
      }
    });
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
        title: Text('Local Data Management'),
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
                case 'import_excel':
                  _importFromExcel();
                  break;
                case 'export_excel':
                  _exportToExcel();
                  break;
                case 'sql_query':
                  _toggleSQLQuery();
                  break;
                case 'delete_all':
                  _deleteAllItems();
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
                value: 'import_excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Import Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sql_query',
                child: Row(
                  children: [
                    Icon(Icons.query_stats),
                    SizedBox(width: 8),
                    Text('SQL Query'),
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
                  Text('Total: ${_databaseStats!['total_items']}'),
                  Text('Oldest: ${_databaseStats!['oldest_item']?.substring(0, 10) ?? 'N/A'}'),
                  Text('Newest: ${_databaseStats!['newest_item']?.substring(0, 10) ?? 'N/A'}'),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchItems('');
                  },
                ),
              ),
              onChanged: _searchItems,
            ),
          ),

          // SQL Query Section
          if (_showSQLQuery)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SQL Query',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _sqlQueryController,
                    decoration: InputDecoration(
                      labelText: 'Enter SQL Query',
                      hintText: 'SELECT * FROM items WHERE name LIKE "%search%"',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _executeSQLQuery,
                          icon: Icon(Icons.play_arrow),
                          label: Text('Execute Query'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleSQLQuery,
                          icon: Icon(Icons.close),
                          label: Text('Close'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  if (_sqlQueryResults.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Query Results (${_sqlQueryResults.length} results)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _sqlQueryResults.length,
                        itemBuilder: (context, index) {
                          final result = _sqlQueryResults[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              title: Text('Result ${index + 1}'),
                              subtitle: Text(result.toString()),
                              trailing: Icon(Icons.query_stats),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Input Form
          if (!_showSQLQuery)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _editingId == null ? _addItem : _updateItem,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: Text(_editingId == null ? 'Add Item' : 'Update Item'),
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

          // Items List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(child: Text('No items found'))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description),
                                  SizedBox(height: 4),
                                  Text(
                                    'ID: ${item.id} | Created: ${item.createdAt.toString().substring(0, 19)}',
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
                                    onPressed: () => _startEditing(item),
                                  ),
                                                                     IconButton(
                                     icon: Icon(Icons.delete),
                                     onPressed: () => _deleteItem(item.id ?? 0),
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