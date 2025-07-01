// lib/diary_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiaryViewPage extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const DiaryViewPage({
    super.key,
    required this.entry,
    this.onPrevious,
    this.onNext,
  });

  String getMoodIcon(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'happy':
        return 'assets/images/happy.png';
      case 'sad':
        return 'assets/images/sad.png';
      case 'angry':
        return 'assets/images/angry.png';
      case 'excited':
        return 'assets/images/excited.png';
      default:
        return 'assets/images/neutral.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = entry['title'] ?? '(No Title)';
    final String description = entry['description'] ?? '(No Content)';
    final String feeling = entry['feeling'] ?? 'neutral';
    final String createdAtString = entry['createdAt'] ?? 'Unknown Date';
    final String? imagePath = entry['imagePath'];

    String formattedDate = 'Unknown Date';
    try {
      final DateTime dateTime = DateTime.parse(createdAtString);
      formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Entry'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Image.asset(getMoodIcon(feeling), width: 30, height: 30),
                const SizedBox(width: 10),
                Text(feeling, style: const TextStyle(fontSize: 18)),
                const Spacer(),
                Text(formattedDate, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),

            if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (imagePath != null && imagePath.isNotEmpty && !File(imagePath).existsSync())
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Image not found.', style: TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onPrevious != null)
                  ElevatedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                if (onPrevious != null && onNext != null) const Spacer(),
                if (onNext != null)
                  ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}