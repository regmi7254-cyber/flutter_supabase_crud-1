# Flutter Data Demo App

A comprehensive Flutter application demonstrating local and server data management with SQLite, JSON, Excel, and Supabase integration.

## 🚀 Features

### Local Data Management (Tab 1)
- **SQLite Database**: Full CRUD operations on local SQLite database
- **JSON Import/Export**: Import data from JSON files and export to JSON
- **Excel Import/Export**: Import data from Excel files and export to Excel
- **SQL Queries**: Execute custom SQL queries on local database
- **Search & Filter**: Search items by name or description
- **Statistics**: View database statistics (total items, oldest/newest)
- **Sample Data**: Automatic sample data loading for testing

### Server Data Management (Tab 2)
- **Supabase Integration**: Full server-side CRUD operations
- **File Upload**: Upload JSON files to Supabase Storage
- **Data Sync**: Upload local SQLite data to server
- **File Download**: Download JSON files from server
- **Server SQL Queries**: Execute SQL queries on server database
- **Connection Status**: Real-time server connection monitoring

## 📋 Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- For Linux: `libsqlite3-dev` package
- Supabase account (for server features)

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_data_demo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Install system dependencies (Linux)**
   ```bash
   sudo apt-get update
   sudo apt-get install -y libsqlite3-dev
   ```

4. **Configure Supabase (Optional)**
   - Create a Supabase project at https://supabase.com
   - Get your project URL and anon key
   - Update `lib/services/supabase_service.dart`:
     ```dart
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🗄️ Database Schema

The app uses a simple `items` table with the following structure:

```sql
CREATE TABLE items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

## 📁 Project Structure

```
lib/
├── models/
│   └── item.dart              # Data model for items
├── services/
│   ├── local_database_service.dart  # SQLite operations
│   └── supabase_service.dart        # Supabase operations
├── screens/
│   ├── local_data_screen.dart       # Local data management UI
│   └── server_data_screen.dart      # Server data management UI
└── main.dart                         # App entry point

assets/
├── json/
│   └── sample_items.json      # Sample JSON data
└── excel/                     # Excel files (if any)
```

## 🎯 Usage Guide

### Local Data Management

1. **Add Items**: Use the form to add new items with name and description
2. **Edit Items**: Click the edit icon on any item to modify it
3. **Delete Items**: Click the delete icon to remove items
4. **Search**: Use the search bar to filter items
5. **Import JSON**: Use the menu to import JSON files
6. **Export JSON**: Export current data to JSON file
7. **Import Excel**: Import data from Excel files
8. **Export Excel**: Export data to Excel format
9. **SQL Queries**: Execute custom SQL queries
10. **Statistics**: View database statistics in the top bar

### Server Data Management

1. **Configure Supabase**: Add your credentials to enable server features
2. **Add Server Items**: Add items directly to the server database
3. **Upload JSON**: Upload JSON files to Supabase Storage
4. **Upload SQLite Data**: Export local data and upload to server
5. **Download Files**: Download JSON files from server storage
6. **Sync Data**: Synchronize local data with server
7. **Server SQL Queries**: Execute queries on server database
8. **Connection Status**: Monitor server connection status

## 🔧 Configuration

### Supabase Setup

1. Create a new Supabase project
2. Create a table named `items` with the schema above
3. Set up Row Level Security (RLS) policies:
   ```sql
   -- Enable RLS
   ALTER TABLE items ENABLE ROW LEVEL SECURITY;
   
   -- Allow all operations for authenticated users
   CREATE POLICY "Allow all operations" ON items
   FOR ALL USING (true);
   ```

4. Create a storage bucket named `json-files`:
   ```sql
   -- Create storage bucket
   INSERT INTO storage.buckets (id, name)
   VALUES ('json-files', 'json-files');
   
   -- Allow public access to storage
   CREATE POLICY "Public Access" ON storage.objects
   FOR SELECT USING (bucket_id = 'json-files');
   
   CREATE POLICY "Public Upload" ON storage.objects
   FOR INSERT WITH CHECK (bucket_id = 'json-files');
   ```

### Local Database

The local SQLite database is automatically created in the app's documents directory. No additional setup required.

## 📊 Features Overview

| Feature | Local | Server | Status |
|---------|-------|--------|--------|
| CRUD Operations | ✅ | ✅ | Complete |
| JSON Import/Export | ✅ | ✅ | Complete |
| Excel Import/Export | ✅ | ❌ | Local Only |
| SQL Queries | ✅ | ✅ | Complete |
| Search & Filter | ✅ | ✅ | Complete |
| Statistics | ✅ | ✅ | Complete |
| File Upload | ❌ | ✅ | Server Only |
| Data Sync | ❌ | ✅ | Server Only |

## 🐛 Troubleshooting

### Common Issues

1. **SQLite not working on Linux**
   ```bash
   sudo apt-get install -y libsqlite3-dev
   ```

2. **Supabase connection failed**
   - Check your URL and anon key
   - Ensure RLS policies are configured
   - Verify network connectivity

3. **File import/export not working**
   - Check file permissions
   - Ensure file format is correct
   - Verify file path is accessible

4. **App crashes on startup**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check console for error messages

## 🚀 Demo Data

The app includes sample data that's automatically loaded when the database is empty. You can also import the provided `assets/json/sample_items.json` file for testing.

## 📝 License

This project is for demonstration purposes. Feel free to use and modify as needed.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review the console logs for error messages
- Ensure all dependencies are properly installed

---

**Happy Coding! 🎉** 