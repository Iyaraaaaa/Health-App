import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Load from Firebase Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          nameController.text = userData['name'] ?? widget.userName;
          emailController.text = userData['email'] ?? widget.userEmail;
        } else {
          // Use widget data if Firestore document doesn't exist
          nameController.text = widget.userName;
          emailController.text = widget.userEmail;
        }
      } else {
        // Use widget data if no current user
        nameController.text = widget.userName;
        emailController.text = widget.userEmail;
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load profile: ${e.toString()}');
      // Fallback to widget data
      nameController.text = widget.userName;
      emailController.text = widget.userEmail;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length() / 1024 / 1024;
        if (fileSize > 5) {
          _showErrorSnackbar('Image size should be less than 5MB');
          return;
        }
        setState(() => _image = file);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar('User not authenticated');
        return;
      }

      if (newEmail == currentUser.email) {
        return; // No change needed
      }

      // Update email in Firebase Auth
      await currentUser.updateEmail(newEmail);
      await currentUser.sendEmailVerification();
      
      _showSuccessSnackbar('Email updated! Please verify your new email address.');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to update email';
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Please log in again to update your email';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already in use by another account';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
      }
      _showErrorSnackbar(errorMessage);
    } catch (e) {
      _showErrorSnackbar('Failed to update email: ${e.toString()}');
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar('User not authenticated');
        return;
      }

      if (newPassword.length < 6) {
        _showErrorSnackbar('Password should be at least 6 characters');
        return;
      }

      await currentUser.updatePassword(newPassword);
      _showSuccessSnackbar('Password updated successfully!');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to update password';
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Please log in again to update your password';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      }
      _showErrorSnackbar(errorMessage);
    } catch (e) {
      _showErrorSnackbar('Failed to update password: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _saveChanges() async {
    if (nameController.text.trim().isEmpty) {
      _showErrorSnackbar('Name is required');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      _showErrorSnackbar('Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar('User not authenticated');
        return;
      }

      // Update email if changed
      if (emailController.text.trim() != currentUser.email) {
        await _updateEmail(emailController.text.trim());
      }

      // Update password if provided
      if (passwordController.text.isNotEmpty) {
        await _updatePassword(passwordController.text);
      }

      // Update display name in Firebase Auth
      await currentUser.updateDisplayName(nameController.text.trim());

      // Update user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nameController.text.trim());
      await prefs.setString('userEmail', emailController.text.trim());

      _showSuccessSnackbar('Profile updated successfully!');
      
      // Wait a bit for the success message to show, then navigate back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true);
      
    } catch (e) {
      _showErrorSnackbar('Failed to save changes: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: isDark ? Colors.black : Colors.blueAccent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileImage(isDark),
                  const SizedBox(height: 25),
                  _buildFormFields(isDark),
                  const SizedBox(height: 30),
                  _buildSaveButton(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImage(bool isDark) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: isDark ? Colors.grey[800] : Colors.blue.shade100,
          backgroundImage: _getImageProvider(),
          child: (_image == null && widget.userImage.isEmpty)
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Failed to load profile image: $exception');
          },
        ),
        Positioned(
          child: FloatingActionButton.small(
            onPressed: _pickImage,
            backgroundColor: isDark ? Colors.grey[800] : Colors.blueAccent,
            child: const Icon(Icons.camera_alt, size: 20),
          ),
        ),
      ],
    );
  }

  ImageProvider _getImageProvider() {
    if (_image != null) {
      return FileImage(_image!);
    } else if (widget.userImage.isNotEmpty) {
      if (widget.userImage.startsWith('http')) {
        return NetworkImage(widget.userImage);
      } else {
        return AssetImage(widget.userImage);
      }
    } else {
      return const AssetImage('assets/images/empty.jpg');
    }
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      children: [
        _customTextField(nameController, 'Full Name', Icons.person, isDark),
        const SizedBox(height: 15),
        _customTextField(emailController, 'Email', Icons.email, isDark),
        const SizedBox(height: 15),
        _customTextField(
          passwordController,
          'New Password (Optional)',
          Icons.lock,
          isDark,
          obscureText: !_isPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() => _isPasswordVisible = !_isPasswordVisible);
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Leave password field empty if you don\'t want to change it',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _customTextField(
    TextEditingController controller, 
    String label, 
    IconData icon,
    bool isDark, {
    bool obscureText = false, 
    Widget? suffixIcon
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon, 
          color: isDark ? Colors.white60 : Colors.blueAccent
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.blue : Colors.blueAccent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isDark ? Colors.blue[700] : Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}