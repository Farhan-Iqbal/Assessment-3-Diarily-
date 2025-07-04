// lib/settings.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login.dart';
import 'diary_helper.dart';
import 'user_helper.dart';

class AppTheme {
  double fontSize;
  Color backgroundColor;
  String? backgroundImagePath;

  AppTheme({
    this.fontSize = 16.0,
    this.backgroundColor = Colors.white,
    this.backgroundImagePath,
  });
}

class SettingsPage extends StatefulWidget {
  final Function(AppTheme) onThemeChanged;

  const SettingsPage({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _fontSize = 16.0;
  Color _backgroundColor = Colors.white;
  File? _backgroundImage;
  File? _profilePicture;
  String _username = 'User';
  int? _currentUserId;

  final Map<String, Color> _availableBackgroundColors = {
    'Light Purple': const Color.fromARGB(255, 184, 147, 249),
    'Light Green': const Color.fromARGB(255, 148, 215, 175),
    'Light Blue': const Color.fromARGB(255, 133, 145, 237),
    'Light Pink': const Color.fromARGB(255, 241, 143, 226),
    'Peach': const Color.fromARGB(255, 238, 197, 149),
    'Gray': const Color.fromARGB(255, 116, 128, 126),
    'White': Colors.white,
  };

  late final List<MapEntry<String, Color>> _sortedBackgroundColors;

  @override
  void initState() {
    super.initState();
    _sortedBackgroundColors = _availableBackgroundColors.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    _loadSettingsAndProfile();
  }

  Future<void> _loadSettingsAndProfile() async {
    _currentUserId = await UserHelper.getCurrentUserId();
    if (_currentUserId == null) return;

    final settings = await DiaryHelper.getSettings();
    if (settings != null) {
      setState(() {
        _fontSize = settings['fontSize'] ?? 16.0;
        try {
          final parsedColor = Color(int.parse(settings['backgroundColor'], radix: 16));
          if (_availableBackgroundColors.containsValue(parsedColor)) {
            _backgroundColor = parsedColor;
          }
        } catch (_) {
          _backgroundColor = Colors.white;
        }
        _backgroundImage = settings['backgroundImagePath'] != null
            ? File(settings['backgroundImagePath'])
            : null;
      });
    }

    final username = await UserHelper.getCurrentUsername();
    final profilePath = await UserHelper.getUserProfilePicturePath(_currentUserId!);
    if (mounted) {
      setState(() {
        _username = username;
        _profilePicture = profilePath != null && File(profilePath).existsSync()
            ? File(profilePath)
            : null;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_currentUserId == null) return;

    await DiaryHelper.saveSettings(
      _fontSize,
      _backgroundColor.value.toRadixString(16),
      _backgroundImage?.path,
    );

    widget.onThemeChanged(AppTheme(
      fontSize: _fontSize,
      backgroundColor: _backgroundColor,
      backgroundImagePath: _backgroundImage?.path,
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  void _logout() async {
    await UserHelper.logoutUser();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: _backgroundImage == null ? _backgroundColor : null,
          image: _backgroundImage != null
              ? DecorationImage(image: FileImage(_backgroundImage!), fit: BoxFit.cover)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.white.withOpacity(0.9),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profilePicture != null
                          ? FileImage(_profilePicture!)
                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      _username,
                      style: TextStyle(fontSize: _fontSize + 2, fontWeight: FontWeight.w600), // Apply font size
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Font Size', style: TextStyle(fontSize: _fontSize)), // Apply font size
                    trailing: DropdownButton<double>(
                      value: _fontSize,
                      onChanged: (newValue) => setState(() => _fontSize = newValue!),
                      items: [12.0, 14.0, 16.0, 18.0, 20.0, 22.0]
                          .map((value) => DropdownMenuItem(value: value, child: Text(value.toString(), style: TextStyle(fontSize: _fontSize)))) // Apply font size
                          .toList(),
                    ),
                  ),
                  ListTile(
                    title: Text('Background Color', style: TextStyle(fontSize: _fontSize)), // Apply font size
                    trailing: DropdownButton<Color>(
                      value: _availableBackgroundColors.containsValue(_backgroundColor)
                          ? _backgroundColor
                          : Colors.white,
                      onChanged: (newValue) {
                        setState(() {
                          _backgroundColor = newValue!;
                          _backgroundImage = null;
                        });
                      },
                      items: _sortedBackgroundColors
                          .map((entry) => DropdownMenuItem(
                                value: entry.value,
                                child: Text(entry.key, style: TextStyle(color: Colors.black, fontSize: _fontSize)), // Apply font size
                              ))
                          .toList(),
                    ),
                  ),
                  ListTile(
                    title: Text('Background Image', style: TextStyle(fontSize: _fontSize)), // Apply font size
                    trailing: IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _backgroundImage = File(pickedFile.path);
                            _backgroundColor = Colors.transparent;
                          });
                        }
                      },
                    ),
                  ),
                  if (_backgroundImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.file(_backgroundImage!, height: 150, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)), // Apply font size
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Logout', style: TextStyle(color: Colors.white, fontSize: _fontSize)), // Apply font size
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}