// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'login.dart';
import 'register.dart';
import 'settings.dart';
import 'diary_helper.dart';
import 'user_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

AppTheme currentAppTheme = AppTheme();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbPath = join(await getDatabasesPath(), 'user_diary_app.db');
  await deleteDatabase(dbPath);
  print('✅ Database deleted');

  await UserHelper.database;
  await DiaryHelper.database;

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isLoggedIn) {
    await UserHelper.getCurrentUserId();
  }

  await _loadAndApplyTheme();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> _loadAndApplyTheme() async {
  final settings = await DiaryHelper.getSettings();
  if (settings != null) {
    Color loadedColor;
    try {
      loadedColor = Color(int.parse(settings['backgroundColor'], radix: 16));
    } catch (e) {
      debugPrint('Error parsing background color in _loadAndApplyTheme: $e');
      loadedColor = Colors.white;
    }

    currentAppTheme = AppTheme(
      fontSize: settings['fontSize'] ?? 16.0,
      backgroundColor: loadedColor,
      backgroundImagePath: settings['backgroundImagePath'],
    );
  } else {
    currentAppTheme = AppTheme();
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _updateAppTheme(AppTheme newTheme) {
    setState(() {
      currentAppTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diarily', // ✅ Added app title
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: Theme.of(context).textTheme.copyWith(
              bodyLarge: TextStyle(fontSize: currentAppTheme.fontSize),
              bodyMedium: TextStyle(fontSize: currentAppTheme.fontSize),
              bodySmall: TextStyle(fontSize: currentAppTheme.fontSize - 2),
            ),
        scaffoldBackgroundColor: currentAppTheme.backgroundColor,
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          backgroundColor: Colors.deepPurple
        ),
      ),
      home: widget.isLoggedIn
          ? HomePage(onThemeChanged: _updateAppTheme)
          : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => HomePage(onThemeChanged: _updateAppTheme),
      },
    );
  }
}
