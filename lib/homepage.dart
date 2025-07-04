// lib/homepage.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import 'diary_helper.dart';
import 'diary_form.dart';
import 'diary_view.dart';
import 'settings.dart';
import 'login.dart';
import 'user_helper.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  final Function(AppTheme) onThemeChanged;
  const HomePage({super.key, required this.onThemeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _filteredDiaries = [];
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  AppTheme _currentTheme = AppTheme();

  int _selectedIndex = 0;
  int? _currentUserId;
  String? _profilePicturePath;
  String _username = 'Unknown';
  String _password = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkLoginStatus();
    _currentUserId = await UserHelper.getCurrentUserId();
    if (_currentUserId != null) {
      _profilePicturePath = await UserHelper.getUserProfilePicturePath(_currentUserId!);
      _username = await UserHelper.getCurrentUsername();
      _password = await UserHelper.getCurrentPassword();
      await _loadSettings();
      _refreshDiaries();
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _loadSettings() async {
    final settings = await DiaryHelper.getSettings();
    if (settings != null) {
      setState(() {
        Color bgColor;
        try {
          bgColor = Color(int.parse(settings['backgroundColor'], radix: 16));
        } catch (_) {
          bgColor = Colors.white;
        }
        _currentTheme = AppTheme(
          fontSize: settings['fontSize'] ?? 16.0,
          backgroundColor: bgColor,
          backgroundImagePath: settings['backgroundImagePath'],
        );
      });
    }
  }

  void _refreshDiaries() async {
    final data = await DiaryHelper.getDiaries();
    final search = _searchText.toLowerCase();

    final filtered = _searchText.isEmpty
        ? data
        : data.where((entry) {
            final createdAt = entry['createdAt'] ?? '';
            final formattedDate = createdAt.toString().substring(0, 10);
            return (entry['title'] ?? '').toString().toLowerCase().contains(search) ||
                (entry['description'] ?? '').toString().toLowerCase().contains(search) ||
                (entry['feeling'] ?? '').toString().toLowerCase().contains(search) ||
                formattedDate.contains(search);
          }).toList();

    setState(() {
      _filteredDiaries = filtered;
      _events.clear();
      for (var diary in data) {
        final createdAt = DateTime.parse(diary['createdAt']);
        final key = DateTime(createdAt.year, createdAt.month, createdAt.day);
        _events[key] = [...?_events[key], diary];
      }
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
      _selectedIndex = 0;
    });
  }

  void _viewDiary(int index) {
    final diaries = _selectedDay != null ? _getEventsForDay(_selectedDay!) : _filteredDiaries;
    if (index < 0 || index >= diaries.length) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryViewPage(
          entry: diaries[index],
          onPrevious: index > 0 ? () => _viewDiary(index - 1) : null,
          onNext: index < diaries.length - 1 ? () => _viewDiary(index + 1) : null,
        ),
      ),
    );
  }

  Future<void> _deleteDiary(int id) async {
    await DiaryHelper.deleteDiary(id);
    _refreshDiaries();
  }

  Widget _buildAboutPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome to Diarily — Your Personal Space to Reflect, Remember, and Grow.\n\n'
              'Diarily is a modern personal diary app designed to help you capture your thoughts, '
              'emotions, and memories in a safe, private space. Whether you’re experiencing a joyful moment '
              'or going through a tough day, Diarily lets you express your feelings freely and honestly.\n\n'
              'Add photos to your diary entries to bring your stories to life and make each memory more special. '
              'With its simple and user-friendly design, Diarily is the perfect companion for self-reflection, '
              'emotional wellness, and creative expression.\n\n'
              'Start your journey today — because every feeling matters, and every moment deserves to be remembered.',
              style: TextStyle(fontSize: _currentTheme.fontSize),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return ProfilePage(
      username: _username,
      password: _password,
      profilePicturePath: _profilePicturePath,
      appTheme: _currentTheme,
    );
  }

  Widget _buildHomePage() {
    final diaries = _selectedDay != null ? _getEventsForDay(_selectedDay!) : _filteredDiaries;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchText = value);
              _refreshDiaries();
            },
            decoration: InputDecoration(
              hintText: 'Search diary...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(fontSize: _currentTheme.fontSize), // Apply font size to hint text
            ),
            style: TextStyle(fontSize: _currentTheme.fontSize), // Apply font size to input text
          ),
        ),
        Expanded(
          child: LiquidPullToRefresh(
            onRefresh: () async => _refreshDiaries(),
            color: Colors.deepPurple,
            backgroundColor: Colors.deepPurpleAccent,
            showChildOpacityTransition: false,
            child: diaries.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          _selectedDay != null
                              ? 'No entries for ${DateFormat('yyyy-MM-dd').format(_selectedDay!)}'
                              : 'No diary entries yet. Click "+" to add one!',
                          style: TextStyle(fontSize: _currentTheme.fontSize), // Apply font size
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: diaries.length,
                    itemBuilder: (_, index) {
                      final diary = diaries[index];
                      return Dismissible(
                        key: Key(diary['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Confirm Delete', style: TextStyle(fontSize: _currentTheme.fontSize)), // Apply font size
                              content: Text('Are you sure you want to delete this diary entry?', style: TextStyle(fontSize: _currentTheme.fontSize)), // Apply font size
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(fontSize: _currentTheme.fontSize))), // Apply font size
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(fontSize: _currentTheme.fontSize))), // Apply font size
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _deleteDiary(diary['id']),
                        child: Card(
                          color: Colors.deepPurpleAccent.withOpacity(0.8),
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            onTap: () => _viewDiary(index),
                            leading: CircleAvatar(
                              backgroundImage: diary['imagePath'] != null && File(diary['imagePath']).existsSync()
                                  ? FileImage(File(diary['imagePath']))
                                  : const AssetImage('assets/images/happy.png') as ImageProvider,
                            ),
                            title: Text(
                              diary['title'] ?? 'No Title',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: _currentTheme.fontSize), // Apply font size
                            ),
                            subtitle: Text(
                              'Feeling: ${diary['feeling']}\n${diary['description']}\n${DateFormat('yyyy-MM-dd').format(DateTime.parse(diary['createdAt']))}',
                              style: TextStyle(fontSize: _currentTheme.fontSize - 2), // Apply font size, slightly smaller
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DiaryFormPage(id: diary['id'])),
                                );
                                if (result == true) _refreshDiaries();
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _onAddPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryFormPage(id: null)),
    );
    if (result == true) _refreshDiaries();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      _buildAboutPage(),
      _buildProfilePage(),
      SettingsPage(
        onThemeChanged: (theme) async {
          final id = await UserHelper.getCurrentUserId();
          final profilePath = id != null ? await UserHelper.getUserProfilePicturePath(id) : null;
          final username = await UserHelper.getCurrentUsername();
          final password = await UserHelper.getCurrentPassword();

          setState(() {
            _currentTheme = theme;
            _profilePicturePath = profilePath;
            _username = username;
            _password = password;
          });

          widget.onThemeChanged(theme);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: _currentTheme.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          switch (_selectedIndex) {
            0 => 'Diarily — Home',
            1 => 'Diarily — About',
            2 => 'Diarily — Profile',
            3 => 'Diarily — Settings',
            _ => 'Diarily',
          },
        ),
        actions: _selectedIndex == 0
            ? [IconButton(icon: const Icon(Icons.calendar_today), onPressed: _showCalendarPopup)]
            : null,
      ),
      body: Container(
        decoration: _currentTheme.backgroundImagePath != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(_currentTheme.backgroundImagePath!)),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: pages[_selectedIndex],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed from spaceAround
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => setState(() => _selectedIndex = 0),
              tooltip: 'Home',
              color: _selectedIndex == 0 ? Colors.deepPurple : null,
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => setState(() => _selectedIndex = 1),
              tooltip: 'About',
              color: _selectedIndex == 1 ? Colors.deepPurple : null,
            ),
            // REMOVED THE SIZEDBOX HERE
            // const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => setState(() => _selectedIndex = 2),
              tooltip: 'Profile',
              color: _selectedIndex == 2 ? Colors.deepPurple : null,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => setState(() => _selectedIndex = 3),
              tooltip: 'Settings',
              color: _selectedIndex == 3 ? Colors.deepPurple : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarPopup() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        eventLoader: _getEventsForDay,
        headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
        ),
      ),
    );
  }
}