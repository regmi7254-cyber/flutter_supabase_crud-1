# Flutter SQLite CRUD App

A comprehensive Flutter application demonstrating SQLite database operations with JSON and CSV import/export functionality.

## 🚀 Features

### **SQLite Database Operations**
- ✅ **CREATE**: Add new notes with title and content
- ✅ **READ**: Display all notes with search functionality
- ✅ **UPDATE**: Edit existing notes with inline editing
- ✅ **DELETE**: Remove individual notes or all notes
- ✅ **SEARCH**: Real-time search in title and content
- ✅ **STATISTICS**: Database stats (total, oldest, newest)

### **Import/Export Features**
- ✅ **JSON Import**: Import notes from JSON files
- ✅ **JSON Export**: Export all notes to JSON file
- ✅ **CSV Import**: Import notes from CSV files (Excel format)
- ✅ **CSV Export**: Export all notes to CSV file
- ✅ **File Picker**: Native file selection dialog

### **Advanced Features**
- ✅ **Error Handling**: Comprehensive error messages
- ✅ **Loading States**: Progress indicators
- ✅ **Confirmation Dialogs**: Safe delete operations
- ✅ **Real-time Updates**: UI updates after operations
- ✅ **Database Stats**: Live statistics display

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── note.dart            # Note data model
├── screens/
│   └── sqlite_screen.dart   # Main SQLite CRUD screen
└── services/
    └── database_service.dart # SQLite database service

assets/
└── json/
    ├── sample_notes.json    # Sample JSON data
    └── sample_notes.csv     # Sample CSV data
```

## 🛠️ Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

## 📱 Usage

### **Main Screen Features**

#### **Database Statistics**
- View total number of notes
- See oldest and newest note dates
- Real-time updates after operations

#### **Search Functionality**
- Real-time search in title and content
- Clear search with one click
- Instant filtering of results

#### **CRUD Operations**
- **Add Note**: Fill title and content, click "Add Note"
- **Edit Note**: Click edit icon, modify fields, click "Update Note"
- **Delete Note**: Click delete icon to remove individual notes
- **Delete All**: Use menu to delete all notes with confirmation

#### **Import/Export Menu**
Access via the menu button (⋮) in the app bar:
- **Import JSON**: Select JSON file to import notes
- **Export JSON**: Export all notes to JSON file
- **Import CSV**: Select CSV file to import notes
- **Export CSV**: Export all notes to CSV file
- **Delete All**: Bulk delete with confirmation

## 📊 Database Schema

```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

## 📁 Sample Files

The app includes sample files for testing import functionality:

### **JSON Format** (`assets/json/sample_notes.json`)
```json
[
  {
    "title": "Welcome Note",
    "content": "Welcome to the Flutter SQLite CRUD app!",
    "created_at": "2024-01-15T10:00:00.000Z",
    "updated_at": "2024-01-15T10:00:00.000Z"
  }
]
```

### **CSV Format** (`assets/json/sample_notes.csv`)
```csv
title,content,created_at,updated_at
"Welcome Note","Welcome to the Flutter SQLite CRUD app!","2024-01-15T10:00:00.000Z","2024-01-15T10:00:00.000Z"
```

## 🔧 Dependencies

- `flutter`: Core Flutter framework
- `sqflite`: SQLite database for Flutter
- `path_provider`: File system access
- `file_picker`: File selection for import/export
- `http`: HTTP requests for file operations

## 🎯 Key Features

### **SQLite Database**
- Local database with offline support
- Automatic database creation
- Transaction support for bulk operations
- SQL queries for search and statistics

### **File Operations**
- Import from JSON files
- Export to JSON files
- Import from CSV files (Excel format)
- Export to CSV files
- File picker integration
- Automatic file naming with timestamps

### **User Interface**
- Modern Material Design
- Responsive layout
- Loading indicators
- Error handling with user feedback
- Confirmation dialogs for destructive actions

## 📝 Testing

### **Manual Testing Steps**
1. **Add Notes**: Create several notes with different titles and content
2. **Search**: Use the search bar to find specific notes
3. **Edit**: Modify existing notes using the edit functionality
4. **Delete**: Remove individual notes
5. **Import JSON**: Use the sample JSON file to test import
6. **Import CSV**: Use the sample CSV file to test import
7. **Export**: Export data to both JSON and CSV formats
8. **Delete All**: Test the bulk delete functionality

### **Sample Data**
The app includes sample files in `assets/json/`:
- `sample_notes.json` - 5 sample notes in JSON format
- `sample_notes.csv` - 5 sample notes in CSV format

## 🚀 Getting Started

1. **Clone the repository**
2. **Install dependencies**: `flutter pub get`
3. **Run the app**: `flutter run`
4. **Test features**: Use the sample files to test import/export

## 📝 License

This project is open source and available under the MIT License. 