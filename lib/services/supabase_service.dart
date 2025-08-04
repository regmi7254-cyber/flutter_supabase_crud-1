import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://vimxlyhhfamfposdmopp.supabase.co', 
      anonKey: 'sb_publishable_kLpTNBmMXonVjtPf_dh67A_T1N8wCET', 
    );
    _client = Supabase.instance.client;
  }

  
  Future<Map<String, dynamic>> insertItem(Item item) async {
    try {
      final insertData = {
        'name': item.name,
        'description': item.description,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      };
      
      print('🔄 Attempting to insert item: $insertData');
      
      final response = await client
          .from('items')
          .insert(insertData)
          .select()
          .single();
      
      print('✅ Item inserted successfully: $response');
      return response;
    } catch (e) {
      print('❌ Failed to insert item: $e');
      throw Exception('Failed to insert item: $e');
    }
  }

  Future<List<Item>> getItems() async {
    try {
      final response = await client
          .from('items')
          .select()
          .order('created_at', ascending: false);
      
      return response.map((item) => Item.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to get items: $e');
    }
  }

  Future<Item?> getItem(int id) async {
    try {
      final response = await client
          .from('items')
          .select()
          .eq('id', id)
          .single();
      
      return Item.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateItem(Item item) async {
    try {
      final response = await client
          .from('items')
          .update(item.copyWith(updatedAt: DateTime.now()).toMap())
          .eq('id', item.id!)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await client
          .from('items')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<String> uploadJsonToStorage(String jsonData, String fileName) async {
    try {
      final bytes = utf8.encode(jsonData);
      final response = await client.storage
          .from('json-files')
          .uploadBinary(fileName, bytes);
      
      return response;
    } catch (e) {
      throw Exception('Failed to upload JSON to storage: $e');
    }
  }

  Future<String> downloadJsonFromStorage(String fileName) async {
    try {
      final response = await client.storage
          .from('json-files')
          .download(fileName);
      
      return utf8.decode(response);
    } catch (e) {
      throw Exception('Failed to download JSON from storage: $e');
    }
  }

  Future<void> uploadSQLiteDataToServer(List<Item> items) async {
    try {
      final jsonData = json.encode(items.map((item) => item.toMap()).toList());
      final fileName = 'sqlite_data_${DateTime.now().millisecondsSinceEpoch}.json';
      
      await uploadJsonToStorage(jsonData, fileName);
    } catch (e) {
      throw Exception('Failed to upload SQLite data to server: $e');
    }
  }

  Future<List<Item>> downloadSQLiteDataFromServer(String fileName) async {
    try {
      final jsonString = await downloadJsonFromStorage(fileName);
      final List<dynamic> jsonData = json.decode(jsonString);
      
      return jsonData.map((item) => Item.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to download SQLite data from server: $e');
    }
  }

  Future<List<String>> getAvailableJsonFiles() async {
    try {
      final response = await client.storage
          .from('json-files')
          .list();
      
      return response.map((file) => file.name).toList();
    } catch (e) {
      throw Exception('Failed to get available JSON files: $e');
    }
  }

  Future<void> syncWithServer(List<Item> localItems) async {
    try {
      await uploadSQLiteDataToServer(localItems);
      
    } catch (e) {
      throw Exception('Failed to sync with server: $e');
    }
  }

  Future<Map<String, dynamic>> getServerStats() async {
    try {
      final items = await getItems();
      final files = await getAvailableJsonFiles();
      
      return {
        'total_items': items.length,
        'total_files': files.length,
        'oldest_item': items.isNotEmpty ? items.last.createdAt.toIso8601String() : null,
        'newest_item': items.isNotEmpty ? items.first.createdAt.toIso8601String() : null,
        'available_files': files,
      };
    } catch (e) {
      throw Exception('Failed to get server stats: $e');
    }
  }

  Future<List<Item>> searchItems(String query) async {
    try {
      final response = await client
          .from('items')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response.map((item) => Item.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to search items: $e');
    }
  }

  Future<void> bulkInsertItems(List<Item> items) async {
    try {
      final itemsData = items.map((item) => item.toMap()).toList();
      await client.from('items').insert(itemsData);
    } catch (e) {
      throw Exception('Failed to bulk insert items: $e');
    }
  }

  Future<List<Map<String, dynamic>>> executeSQLQuery(String query) async {
    try {
      final response = await client.rpc('execute_sql', params: {'query': query});
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to execute SQL query: $e');
    }
  }

  Future<bool> checkConnection() async {
    try {
      print('🔍 Testing Supabase connection...');
      
      final response = await client.from('items').select('id').limit(1);
      print(' Connection test successful: $response');
      
      try {
        final testItem = {
          'name': 'Test Item',
          'description': 'Test Description',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        print('🧪 Testing insert capability...');
        final insertResponse = await client.from('items').insert(testItem).select().single();
        print('Insert test successful: $insertResponse');
        
        await client.from('items').delete().eq('id', insertResponse['id']);
        print('🧹 Test item cleaned up');
        
      } catch (insertError) {
        print(' Insert test failed: $insertError');
        print(' This indicates RLS policies are blocking inserts');
      }
      
      return true;
    } catch (e) {
      print(' Connection test failed: $e');
      print(' This might be because:');
      print('   1. The "items" table doesn\'t exist in your Supabase project');
      print('   2. RLS (Row Level Security) policies are blocking access');
      print('   3. Network connectivity issues');
      return false;
    }
  }
} 