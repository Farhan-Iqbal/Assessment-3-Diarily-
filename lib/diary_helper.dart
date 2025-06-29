// lib/diary_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'user_helper.dart'; // Import UserHelper

class DiaryHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'user_diary_app.db'); // Same database file as UserHelper
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for diary entries, linked to users table
        await db.execute('''
          CREATE TABLE diaries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL, -- Added NOT NULL
            title TEXT,
            feeling TEXT,
            description TEXT,
            imagePath TEXT,
            createdAt TEXT,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        // NOTE: The 'settings' table is created in UserHelper._initDB()
        // If you were to create a new database file here, you'd need to
        // ensure settings table creation logic is consistent or merged.
      },
      // onUpgrade logic would go here if you modify schema later
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON'); // Enable foreign keys
      },
    );
  }

  // --- Diary Operations (Updated to include userId) ---

  static Future<int> createDiary(String title, String feeling, String description, String? imagePath) async {
    final db = await database;
    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      print('Error: No user logged in to create diary.');
      return -1; // Indicate failure
    }
    final data = {
      'userId': userId,
      'title': title,
      'feeling': feeling,
      'description': description,
      'imagePath': imagePath,
      'createdAt': DateTime.now().toIso8601String(),
    };
    return await db.insert('diaries', data);
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await database;
    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      print('Error: No user logged in to retrieve diaries.');
      return [];
    }
    // Order by id DESC to show most recent first
    return db.query('diaries', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
  }

  static Future<List<Map<String, dynamic>>> getDiary(int id) async {
    final db = await database;
    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      print('Error: No user logged in to retrieve diary.');
      return [];
    }
    return db.query('diaries', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  static Future<int> updateDiary(int id, String title, String feeling, String description, String? imagePath) async {
    final db = await database;
    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      print('Error: No user logged in to update diary.');
      return -1;
    }
    final data = {
      'title': title,
      'feeling': feeling,
      'description': description,
      'imagePath': imagePath,
      'createdAt': DateTime.now().toIso8601String(), // Update timestamp if desired
    };
    return await db.update('diaries', data, where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  static Future<void> deleteDiary(int id) async {
    final db = await database;
    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      print('Error: No user logged in to delete diary.');
      return;
    }
    await db.delete('diaries', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  // --- Settings Operations (Now per user) ---
  static Future<void> saveSettings(double fontSize, String backgroundColor, String? backgroundImagePath) async {
    final db = await database;
    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      print('Error: No user logged in to save settings.');
      return;
    }
    final data = {
      'userId': userId,
      'fontSize': fontSize,
      'backgroundColor': backgroundColor,
      'backgroundImagePath': backgroundImagePath,
    };
    // Use insert with conflictAlgorithm: ConflictAlgorithm.replace to update if settings exist for userId
    await db.insert(
      'settings',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Settings saved for userId: $userId');
  }

  static Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      print('Error: No user logged in to get settings.');
      return null;
    }
    final List<Map<String, dynamic>> settings = await db.query(
      'settings',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (settings.isNotEmpty) {
      print('Settings loaded for userId: $userId');
      return settings.first;
    }
    print('No settings found for userId: $userId');
    return null;
  }
}