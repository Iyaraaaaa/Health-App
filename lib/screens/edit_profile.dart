import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
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
  File? _newImage;
  String _currentImageData = '';
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
          
          // Handle profile image data
          if (userData['profileImageBase64'] != null && userData['profileImageBase64'].toString().isNotEmpty) {
            _currentImageData = 'data:image/jpeg;base64,${userData['profileImageBase64']}';
          } else if (userData['imageUrl'] != null && userData['imageUrl'].toString().isNotEmpty) {
            _currentImageData = userData['imageUrl'].toString();
          } else {
            _currentImageData = widget.userImage;
          }
        } else {
          // Use widget data if Firestore document doesn't exist
          nameController.text = widget.userName;
          emailController.text = widget.userEmail;
          _currentImageData = widget.userImage;
        }
      } else {
        // Use widget data if no current user
        nameController.text = widget.userName;
        emailController.text = widget.userEmail;
        _currentImageData = widget.userImage;
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load profile: ${e.toString()}');
      // Fallback to widget data
      nameController.text = widget.userName;
      emailController.text = widget.userEmail;
      _currentImageData = widget.userImage;
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
        setState(() {
          _newImage = file;
        });
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
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

      // Prepare user data for Firestore
      final Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle profile image update
      String? updatedImageData;
      if (_newImage != null) {
        // New image selected - convert to Base64
        final bytes = await _newImage!.readAsBytes();
        final base64String = base64Encode(bytes);
        userData['profileImageBase64'] = base64String;
        userData['imageUrl'] = 'data:image/jpeg;base64,$base64String';
        updatedImageData = 'data:image/jpeg;base64,$base64String';
      } else {
        // Keep existing image data
        if (_currentImageData.isNotEmpty) {
          if (_currentImageData.startsWith('data:image')) {
            final base64String = _currentImageData.split(',')[1];
            userData['profileImageBase64'] = base64String;
            userData['imageUrl'] = _currentImageData;
          } else {
            userData['imageUrl'] = _currentImageData;
            userData['profileImageBase64'] = '';
          }
        } else {
          userData['profileImageBase64'] = '';
          userData['imageUrl'] = '';
        }
        updatedImageData = _currentImageData;
      }

      // Update user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(userData, SetOptions(merge: true));

      // Update SharedPreferences for immediate access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nameController.text.trim());
      await prefs.setString('userEmail', emailController.text.trim());
      if (updatedImageData != null && updatedImageData.isNotEmpty) {
        await prefs.setString('userImage', updatedImageData);
      } else {
        await prefs.remove('userImage');
      }

      _showSuccessSnackbar('Profile updated successfully!');
      
      // Wait a bit for the success message to show, then navigate back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true);
      
    } catch (e) {
      _showErrorSnackbar('Failed to save changes: ${e.toString()}');
      debugPrint('Save changes error: $e');
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
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 58,
            backgroundColor: isDark ? Colors.grey[800] : Colors.blue.shade100,
            backgroundImage: _getImageProvider(),
            child: _getImageProvider() == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  )
                : null,
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Failed to load profile image: $exception');
            },
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _getImageProvider() {
    // Priority: New image -> Current image data -> Fallback to null
    if (_newImage != null) {
      return FileImage(_newImage!);
    } else if (_currentImageData.isNotEmpty) {
      if (_currentImageData.startsWith('data:image')) {
        // Handle Base64 images
        try {
          final base64String = _currentImageData.split(',')[1];
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        } catch (e) {
          debugPrint('Error decoding Base64 image: $e');
          return null;
        }
      } else if (_currentImageData.startsWith('http')) {
        // Handle network images
        return NetworkImage(_currentImageData);
      } else if (_currentImageData.startsWith('assets/')) {
        // Handle asset images
        return AssetImage(_currentImageData);
      }
    }
    return null;
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
              color: isDark ? Colors.grey[400] : Colors.grey[600],
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
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon, 
          color: isDark ? Colors.white60 : Colors.blueAccent,
          size: 24,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.blue[400]! : Colors.blueAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red[400]!,
            width: 1,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isDark ? Colors.blue[700] : Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: (isDark ? Colors.blue[700] : Colors.blueAccent)?.withOpacity(0.3),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
      ),
    );
  }
}