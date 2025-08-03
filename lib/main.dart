import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'services/database_service.dart';
import 'screens/sqlite_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
 
  try {
    await DatabaseService.database;
    print('✅ Database initialized successfully');
  } catch (e) {
    print('❌ Database initialization failed: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SQLite CRUD',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: SQLiteScreen(),
    );
  }
} 