import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';

class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userImage;

  const EditProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userImage,
  });

  @override
  _EditProfilePage createState() => _EditProfilePage();
}

class _EditProfilePage extends State<EditProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      nameController.text = widget.userName;
      emailController.text = widget.userEmail;
    } catch (e) {
      _showErrorSnackbar('Failed to load profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() => _image = file);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  Future<void> _saveChanges() async {
    if (nameController.text.isEmpty) {
      _showErrorSnackbar('Name is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagePath = widget.userImage;
      if (_image != null) {
        imagePath = _image!.path;
      }

      final profileData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'imagePath': imagePath ?? '',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nameController.text);
      await prefs.setString('userEmail', emailController.text);
      await prefs.setString('userImage', imagePath ?? '');

      _showSuccessSnackbar('Profile updated successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackbar('Failed to save changes: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.editProfile),
        centerTitle: true,
        backgroundColor: Colors.blue, // Keep it blue for both light and dark modes
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 25),
                  _buildFormFields(loc),
                  const SizedBox(height: 30),
                  _buildSaveButton(loc),
                ],
              ),
            ),
    );
  }
      ),
    );
  }
}
