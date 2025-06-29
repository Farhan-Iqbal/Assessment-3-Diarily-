// lib/diary_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'diary_helper.dart'; // Import the new diary_helper

class DiaryFormPage extends StatefulWidget {
  final int? id;

  const DiaryFormPage({Key? key, this.id}) : super(key: key);

  @override
  _DiaryFormPageState createState() => _DiaryFormPageState();
}

class _DiaryFormPageState extends State<DiaryFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadDiaryData();
    }
  }

  Future<void> _loadDiaryData() async {
    final data = await DiaryHelper.getDiary(widget.id!);
    if (data.isNotEmpty) {
      final existingDiary = data.first;
      _titleController.text = existingDiary['title'];
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
      if (existingDiary['imagePath'] != null) {
        _image = File(existingDiary['imagePath']);
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _saveDiary() async {
    final title = _titleController.text;
    final feeling = _feelingController.text;
    final description = _descriptionController.text;
    final imagePath = _image?.path;

    if (widget.id == null) {
      await DiaryHelper.createDiary(title, feeling, description, imagePath);
    } else {
      await DiaryHelper.updateDiary(widget.id!, title, feeling, description, imagePath);
    }
    Navigator.of(context).pop(true); // Pop with true to indicate a refresh is needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Create Diary' : 'Edit Diary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feelingController,
              decoration: const InputDecoration(labelText: 'Feeling (e.g., Happy, Sad, Angry)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Your Thoughts',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            _image != null
                ? Image.file(
                    _image!,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : const Text('No image selected.'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _getImage(ImageSource.camera),
                  tooltip: 'Take a picture',
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: () => _getImage(ImageSource.gallery),
                  tooltip: 'Choose from gallery',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveDiary,
              child: Text(widget.id == null ? 'Save Diary' : 'Update Diary'),
            ),
          ],
        ),
      ),
    );
  }
}
