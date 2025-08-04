import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/item.dart';
import '../services/supabase_service.dart';
import '../services/local_database_service.dart';

class JsonFilesScreen extends StatefulWidget {
  @override
  _JsonFilesScreenState createState() => _JsonFilesScreenState();
}

class _JsonFilesScreenState extends State<JsonFilesScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  
  List<String> _availableFiles = [];
  List<Item> _downloadedItems = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _selectedFile;
  String _fileContent = '';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await _supabaseService.checkConnection();
      setState(() => _isConnected = connected);
      if (connected) {
        await _loadAvailableFiles();
      }
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  Future<void> _loadAvailableFiles() async {
    if (!_isConnected) return;
    
    setState(() => _isLoading = true);
    try {
      final files = await _supabaseService.getAvailableJsonFiles();
      setState(() => _availableFiles = files);
    } catch (e) {
      _showSnackBar('Error loading files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadLocalJsonFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        setState(() => _isLoading = true);
        
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final fileName = 'local_${DateTime.now().millisecondsSinceEpoch}.json';
        
        await _supabaseService.uploadJsonToStorage(jsonString, fileName);
        await _loadAvailableFiles();
        _showSnackBar('JSON file uploaded successfully');
      }
    } catch (e) {
      _showSnackBar('Error uploading file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadSQLiteDataAsJson() async {
    try {
      setState(() => _isLoading = true);
      
      final items = await _localDatabaseService.getItems();
      await _supabaseService.uploadSQLiteDataToServer(items);
      await _loadAvailableFiles();
      _showSnackBar('SQLite data uploaded as JSON successfully');
    } catch (e) {
      _showSnackBar('Error uploading SQLite data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadAndReadJsonFile(String fileName) async {
    try {
      setState(() => _isLoading = true);
      
      final jsonString = await _supabaseService.downloadJsonFromStorage(fileName);
      final List<dynamic> jsonData = json.decode(jsonString);
      
      final items = jsonData.map((item) => Item.fromMap(item)).toList();
      
      setState(() {
        _downloadedItems = items;
        _selectedFile = fileName;
        _fileContent = jsonString;
      });
      
      _showSnackBar('JSON file downloaded and read successfully');
    } catch (e) {
      _showSnackBar('Error downloading file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _readSQLiteDataFromServer(String fileName) async {
    try {
      setState(() => _isLoading = true);
      
      final items = await _supabaseService.downloadSQLiteDataFromServer(fileName);
      
      setState(() {
        _downloadedItems = items;
        _selectedFile = fileName;
        _fileContent = json.encode(items.map((item) => item.toMap()).toList());
      });
      
      _showSnackBar('SQLite data read from server successfully');
    } catch (e) {
      _showSnackBar('Error reading SQLite data from server: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _readLocalSQLiteData() async {
    try {
      setState(() => _isLoading = true);
      
      final items = await _localDatabaseService.getItems();
      
      setState(() {
        _downloadedItems = items;
        _selectedFile = 'Local SQLite Database';
        _fileContent = json.encode(items.map((item) => item.toMap()).toList());
      });
      
      _showSnackBar('Local SQLite data read successfully');
    } catch (e) {
      _showSnackBar('Error reading local SQLite data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _readServerSQLiteData() async {
    try {
      setState(() => _isLoading = true);
      
      // Find SQLite data files on server
      final files = await _supabaseService.getAvailableJsonFiles();
      final sqliteFiles = files.where((file) => file.contains('sqlite')).toList();
      
      if (sqliteFiles.isEmpty) {
        _showSnackBar('No SQLite data files found on server');
        return;
      }
      
      // Read the most recent SQLite file
      final latestFile = sqliteFiles.last;
      final items = await _supabaseService.downloadSQLiteDataFromServer(latestFile);
      
      setState(() {
        _downloadedItems = items;
        _selectedFile = latestFile;
        _fileContent = json.encode(items.map((item) => item.toMap()).toList());
      });
      
      _showSnackBar('Server SQLite data read successfully from $latestFile');
    } catch (e) {
      _showSnackBar('Error reading server SQLite data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importToLocalDatabase() async {
    if (_downloadedItems.isEmpty) {
      _showSnackBar('No items to import');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      for (var item in _downloadedItems) {
        await _localDatabaseService.insertItem(item);
      }
      
      _showSnackBar('Items imported to local database successfully');
    } catch (e) {
      _showSnackBar('Error importing items: $e');
    } finally {
      setState(() => _isLoading = false);
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Connection Status
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _isConnected ? Icons.cloud_done : Icons.cloud_off,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _isConnected ? 'Connected to Server' : 'Not Connected to Server',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isConnected ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Upload Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Files',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isConnected ? _uploadLocalJsonFile : null,
                                  icon: Icon(Icons.upload_file),
                                  label: Text('Upload JSON File'),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isConnected ? _uploadSQLiteDataAsJson : null,
                                  icon: Icon(Icons.storage),
                                  label: Text('Upload SQLite Data'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // SQLite Data Operations Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SQLite Data Operations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isConnected ? _readLocalSQLiteData : null,
                                  icon: Icon(Icons.read_more),
                                  label: Text('Read Local SQLite'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isConnected ? _readServerSQLiteData : null,
                                  icon: Icon(Icons.cloud_download),
                                  label: Text('Read Server SQLite'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Available Files Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Files',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _isConnected ? _loadAvailableFiles : null,
                                icon: Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (_availableFiles.isEmpty)
                            Text('No files available')
                          else
                            ..._availableFiles.map((fileName) => ListTile(
                              leading: Icon(Icons.file_copy),
                              title: Text(fileName),
                              subtitle: Text(fileName.contains('sqlite') ? 'SQLite Data' : 'JSON File'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _downloadAndReadJsonFile(fileName),
                                    child: Text('Read JSON'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  if (fileName.contains('sqlite'))
                                    ElevatedButton(
                                      onPressed: () => _readSQLiteDataFromServer(fileName),
                                      child: Text('Read SQLite'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Downloaded Content Section
                  if (_downloadedItems.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Downloaded Content',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _importToLocalDatabase,
                                  child: Text('Import to Local DB'),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'File: $_selectedFile',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Items: ${_downloadedItems.length}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Source: ${_selectedFile?.contains('sqlite') == true ? 'SQLite Data' : 'JSON File'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  _fileContent,
                                  style: TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Items List
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items from JSON',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            ..._downloadedItems.map((item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text(item.description),
                              trailing: Text(
                                'ID: ${item.id}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
} 