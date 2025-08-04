import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/item.dart';
import '../services/supabase_service.dart';
import '../services/local_database_service.dart';

class ServerDataScreen extends StatefulWidget {
  @override
  _ServerDataScreenState createState() => _ServerDataScreenState();
}

class _ServerDataScreenState extends State<ServerDataScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sqlQueryController = TextEditingController();
  
  List<Item> _serverItems = [];
  List<Item> _filteredServerItems = [];
  List<Map<String, dynamic>> _sqlQueryResults = [];
  List<String> _availableFiles = [];
  bool _isLoading = false;
  int? _editingId;
  Map<String, dynamic>? _serverStats;
  bool _showSQLQuery = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      setState(() => _isLoading = true);
      _isConnected = await _supabaseService.checkConnection();
      if (_isConnected) {
        await _loadServerItems();
        await _loadServerStats();
        await _loadAvailableFiles();
      }
    } catch (e) {
      print('❌ Connection check failed: $e');
      _isConnected = false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServerItems() async {
    if (!_isConnected) return;
    
    setState(() => _isLoading = true);
    try {
      print('🔄 Loading server items...');
      final items = await _supabaseService.getItems();
      print('📝 Loaded ${items.length} server items');
      setState(() {
        _serverItems = items;
        _filteredServerItems = items;
      });
    } catch (e) {
      print('❌ Error loading server items: $e');
      _showSnackBar('Error loading server items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServerStats() async {
    if (!_isConnected) return;
    
    try {
      print('📊 Loading server stats...');
      final stats = await _supabaseService.getServerStats();
      print('📈 Server stats: $stats');
      setState(() => _serverStats = stats);
    } catch (e) {
      print('❌ Error loading server stats: $e');
    }
  }

  Future<void> _loadAvailableFiles() async {
    if (!_isConnected) return;
    
    try {
      print('📁 Loading available files...');
      final files = await _supabaseService.getAvailableJsonFiles();
      print('📄 Available files: $files');
      setState(() => _availableFiles = files);
    } catch (e) {
      print('❌ Error loading available files: $e');
    }
  }

  Future<void> _addServerItem() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    final item = Item(
      name: _nameController.text,
      description: _descriptionController.text,
    );

    try {
      await _supabaseService.insertItem(item);
      _nameController.clear();
      _descriptionController.clear();
      await _loadServerItems();
      await _loadServerStats();
      _showSnackBar('Item added to server successfully');
    } catch (e) {
      _showSnackBar('Error adding item to server: $e');
    }
  }

  Future<void> _updateServerItem() async {
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
      await _supabaseService.updateItem(item);
      _nameController.clear();
      _descriptionController.clear();
      setState(() => _editingId = null);
      await _loadServerItems();
      await _loadServerStats();
      _showSnackBar('Server item updated successfully');
    } catch (e) {
      _showSnackBar('Error updating server item: $e');
    }
  }

  Future<void> _deleteServerItem(int id) async {
    try {
      await _supabaseService.deleteItem(id);
      await _loadServerItems();
      await _loadServerStats();
      _showSnackBar('Server item deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting server item: $e');
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

  Future<void> _searchServerItems(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredServerItems = _serverItems);
      return;
    }

    try {
      final results = await _supabaseService.searchItems(query);
      setState(() => _filteredServerItems = results);
    } catch (e) {
      _showSnackBar('Error searching server items: $e');
    }
  }

  // Upload Operations
  Future<void> _uploadJsonToServer() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final fileName = 'uploaded_${DateTime.now().millisecondsSinceEpoch}.json';
        
        await _supabaseService.uploadJsonToStorage(jsonString, fileName);
        await _loadAvailableFiles();
        _showSnackBar('JSON uploaded to server successfully');
      }
    } catch (e) {
      _showSnackBar('Error uploading JSON to server: $e');
    }
  }

  Future<void> _uploadSQLiteDataToServer() async {
    try {
      final localItems = await _localDatabaseService.getItems();
      await _supabaseService.uploadSQLiteDataToServer(localItems);
      await _loadAvailableFiles();
      _showSnackBar('SQLite data uploaded to server successfully');
    } catch (e) {
      _showSnackBar('Error uploading SQLite data to server: $e');
    }
  }

  // Download Operations
  Future<void> _downloadJsonFromServer(String fileName) async {
    try {
      final jsonString = await _supabaseService.downloadJsonFromStorage(fileName);
      final localFileName = 'downloaded_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = await _localDatabaseService.saveToFile(jsonString, localFileName);
      _showSnackBar('JSON downloaded to: $filePath');
    } catch (e) {
      _showSnackBar('Error downloading JSON from server: $e');
    }
  }

  Future<void> _downloadSQLiteDataFromServer(String fileName) async {
    try {
      final items = await _supabaseService.downloadSQLiteDataFromServer(fileName);
      await _localDatabaseService.bulkInsertItems(items);
      _showSnackBar('SQLite data downloaded and imported successfully');
    } catch (e) {
      _showSnackBar('Error downloading SQLite data from server: $e');
    }
  }

  // Sync Operations
  Future<void> _syncWithServer() async {
    try {
      final localItems = await _localDatabaseService.getItems();
      await _supabaseService.syncWithServer(localItems);
      await _loadAvailableFiles();
      _showSnackBar('Data synced with server successfully');
    } catch (e) {
      _showSnackBar('Error syncing with server: $e');
    }
  }

  // SQL Query
  Future<void> _executeServerSQLQuery() async {
    if (_sqlQueryController.text.isEmpty) {
      _showSnackBar('Please enter a SQL query');
      return;
    }

    setState(() {
      _isLoading = true;
      _sqlQueryResults = [];
    });

    try {
      final results = await _supabaseService.executeSQLQuery(_sqlQueryController.text);
      setState(() {
        _sqlQueryResults = results;
        _isLoading = false;
      });
      _showSnackBar('Server SQL query executed successfully (${results.length} results)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error executing server SQL query: $e');
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
        title: Text('Server Data Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _checkConnection,
            tooltip: _isConnected ? 'Connected' : 'Disconnected',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'upload_json':
                  _uploadJsonToServer();
                  break;
                case 'upload_sqlite':
                  _uploadSQLiteDataToServer();
                  break;
                case 'sync':
                  _syncWithServer();
                  break;
                case 'sql_query':
                  _toggleSQLQuery();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'upload_json',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Upload JSON'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'upload_sqlite',
                child: Row(
                  children: [
                    Icon(Icons.storage),
                    SizedBox(width: 8),
                    Text('Upload SQLite Data'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Sync with Server'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sql_query',
                child: Row(
                  children: [
                    Icon(Icons.query_stats),
                    SizedBox(width: 8),
                    Text('Server SQL Query'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: !_isConnected
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Not Connected to Server',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please configure Supabase credentials in supabase_service.dart',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkConnection,
                    child: Text('Retry Connection'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Server Stats
                if (_serverStats != null)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.green[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Server Items: ${_serverStats!['total_items']}'),
                        Text('Files: ${_serverStats!['total_files']}'),
                        Text('Connected: ✅'),
                      ],
                    ),
                  ),

                // Search Bar
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search server items...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchServerItems('');
                        },
                      ),
                    ),
                    onChanged: _searchServerItems,
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
                          'Server SQL Query',
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
                                onPressed: _executeServerSQLQuery,
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
                                onPressed: _editingId == null ? _addServerItem : _updateServerItem,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: Text(_editingId == null ? 'Add to Server' : 'Update Server Item'),
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

                // Available Files Section
                if (_availableFiles.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Files on Server',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 100,
                          child: ListView.builder(
                            itemCount: _availableFiles.length,
                            itemBuilder: (context, index) {
                              final fileName = _availableFiles[index];
                              return Card(
                                child: ListTile(
                                  title: Text(fileName),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.download),
                                        onPressed: () => _downloadJsonFromServer(fileName),
                                        tooltip: 'Download JSON',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.storage),
                                        onPressed: () => _downloadSQLiteDataFromServer(fileName),
                                        tooltip: 'Download as SQLite Data',
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
                  ),

                // Server Items List
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _filteredServerItems.isEmpty
                          ? Center(child: Text('No server items found'))
                          : ListView.builder(
                              itemCount: _filteredServerItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredServerItems[index];
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
                                           onPressed: () => _deleteServerItem(item.id ?? 0),
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