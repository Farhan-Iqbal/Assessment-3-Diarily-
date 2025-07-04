// lib/profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_diary/settings.dart';
import 'user_helper.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String password;
  final String? profilePicturePath;
  final AppTheme appTheme;

  const ProfilePage({
    super.key,
    required this.username,
    required this.password,
    required this.profilePicturePath,
    required this.appTheme,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isPasswordVisible = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _passwordController = TextEditingController(text: widget.password);
    if (widget.profilePicturePath != null &&
        File(widget.profilePicturePath!).existsSync()) {
      _profileImage = File(widget.profilePicturePath!);
    }
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      final userId = await UserHelper.getCurrentUserId();
      if (userId != null) {
        await UserHelper.updateUserProfilePicturePath(userId, pickedFile.path);
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final newUsername = _usernameController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (newUsername.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password cannot be empty')),
      );
      return;
    }

    // Add password length validation
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    final userId = await UserHelper.getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final usernameSuccess =
        await UserHelper.updateUsername(userId, newUsername);
    final passwordSuccess =
        await UserHelper.updatePassword(userId, newPassword);

    if (usernameSuccess && passwordSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // START OF CHANGE
        decoration: BoxDecoration(
          color: widget.appTheme.backgroundImagePath == null
              ? widget.appTheme.backgroundColor // Use background color if no image
              : null, // Otherwise, let the image handle the background
          image: widget.appTheme.backgroundImagePath != null
              ? DecorationImage(
                  image: FileImage(File(widget.appTheme.backgroundImagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        // END OF CHANGE
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickProfilePicture,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                        child: _profileImage == null
                            ? Icon(Icons.camera_alt, color: Colors.grey[700], size: 32)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _pickProfilePicture,
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(
                        'Change Profile Picture',
                        style: TextStyle(fontSize: widget.appTheme.fontSize),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(fontSize: widget.appTheme.fontSize),
                      ),
                      style: TextStyle(fontSize: widget.appTheme.fontSize),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(fontSize: widget.appTheme.fontSize),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      style: TextStyle(fontSize: widget.appTheme.fontSize),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.appTheme.fontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}