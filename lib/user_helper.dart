import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHelper {
  static Database? _database;
  static String? _currentUsername;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'user_diary_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            profilePicturePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE settings(
            userId INTEGER PRIMARY KEY,
            fontSize REAL,
            backgroundColor TEXT,
            backgroundImagePath TEXT,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE diaries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            title TEXT,
            feeling TEXT,
            description TEXT,
            imagePath TEXT,
            createdAt TEXT,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ------------------ User Management ------------------

  static Future<bool> registerUser(String username, String password) async {
    final db = await database;
    try {
      final existingUsers = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      if (existingUsers.isNotEmpty) {
        print('Registration failed: Username already exists.');
        return false;
      }

      await db.insert('users', {
        'username': username,
        'password': password,
        'profilePicturePath': null,
      });
      print('User "$username" registered successfully.');
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  static Future<bool> loginUser(String username, String password) async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (users.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loggedInUsername', username);
      _currentUsername = username;
      print('User "$username" logged in successfully.');
      return true;
    }
    print('Login failed: Invalid username or password for "$username".');
    return false;
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('loggedInUsername');
    _currentUsername = null;
    print('User logged out.');
  }

  static Future<int?> getCurrentUserId() async {
    if (_currentUsername == null) {
      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('loggedInUsername');
    }

    if (_currentUsername != null) {
      final db = await database;
      final user = await db.query(
        'users',
        columns: ['id'],
        where: 'username = ?',
        whereArgs: [_currentUsername],
      );
      if (user.isNotEmpty) {
        return user.first['id'] as int;
      } else {
        print('Warning: Username found in prefs but not in DB. Logging out.');
        await logoutUser();
        return null;
      }
    }
    return null;
  }

  // ------------------ Profile Picture ------------------

  static Future<String?> getUserProfilePicturePath(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['profilePicturePath'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return result.first['profilePicturePath'] as String?;
    }
    return null;
  }

  static Future<void> updateUserProfilePicturePath(int userId, String? path) async {
    final db = await database;
    await db.update(
      'users',
      {'profilePicturePath': path},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ------------------ Get Username ------------------

  static Future<String> getCurrentUsername() async {
    if (_currentUsername == null) {
      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('loggedInUsername');
    }

    return _currentUsername ?? 'Unknown';
  }

  // ------------------ Get Password ------------------

  static Future<String> getCurrentPassword() async {
    final db = await database;
    if (_currentUsername == null) {
      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('loggedInUsername');
    }

    if (_currentUsername != null) {
      final result = await db.query(
        'users',
        columns: ['password'],
        where: 'username = ?',
        whereArgs: [_currentUsername],
      );
      if (result.isNotEmpty) {
        return result.first['password'] as String;
      }
    }

    return 'Unknown';
  }

  // ------------------ Get Username & Password ------------------

  static Future<Map<String, String>> getUsernameAndPassword() async {
    final db = await database;
    if (_currentUsername == null) {
      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('loggedInUsername');
    }

    if (_currentUsername != null) {
      final result = await db.query(
        'users',
        columns: ['username', 'password'],
        where: 'username = ?',
        whereArgs: [_currentUsername],
      );
      if (result.isNotEmpty) {
        return {
          'username': result.first['username'] as String,
          'password': result.first['password'] as String,
        };
      }
    }

    return {'username': 'Unknown', 'password': 'Unknown'};
  }

  // ------------------ Update Username ------------------

  static Future<bool> updateUsername(int userId, String newUsername) async {
    final db = await database;

    final existing = await db.query(
      'users',
      where: 'username = ? AND id != ?',
      whereArgs: [newUsername, userId],
    );

    if (existing.isNotEmpty) return false;

    await db.update(
      'users',
      {'username': newUsername},
      where: 'id = ?',
      whereArgs: [userId],
    );

    _currentUsername = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUsername', newUsername);
    return true;
  }

  // ------------------ Update Password ------------------

  static Future<bool> updatePassword(int userId, String newPassword) async {
    final db = await database;

    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return true;
  }

  static getUserInfo(int userId) {}
}