import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SignupPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(
        builder: (context) => const SignupPage(),
      );

  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isDarkMode = false;
  bool isLoading = false;

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_pickedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
        'profile_images/$userId${path.extension(_pickedImage!.path)}',
      );
      await imageRef.putFile(_pickedImage!);
      return await imageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveUserData(User user, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': user.email,
        'fullName': fullNameController.text.trim(),
        'profileImage': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<void> signUpUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    if (fullNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your full name.');
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String? imageUrl = await _uploadImage(userCredential.user!.uid);
      await _saveUserData(userCredential.user!, imageUrl);

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The email is already in use.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? const LinearGradient(
                  colors: [Color(0xFF121212), Color(0xFF424242)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF008080), Color(0xFF4F86F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(
                  isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                  color: isDarkMode ? Colors.amber : Colors.white,
                ),
                onPressed: () => setState(() => isDarkMode = !isDarkMode),
              ),
            ),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                child: Card(
                  elevation: 12,
                  color: isDarkMode
                      ? Colors.grey[900]
                      : Colors.white.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              backgroundImage: _pickedImage != null
                                  ? FileImage(_pickedImage!)
                                  : const AssetImage('assets/images/empty.jpg')
                                      as ImageProvider,
                              child: _pickedImage == null && !isLoading
                                  ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                                  : isLoading
                                      ? const CircularProgressIndicator()
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// Full Name
                          _buildTextField(
                            controller: fullNameController,
                            label: 'Full Name',
                            isPassword: false,
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: emailController,
                            label: 'Email',
                            isPassword: false,
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: passwordController,
                            label: 'Password',
                            isPassword: true,
                            isVisible: isPasswordVisible,
                            onVisibilityChanged: () =>
                                setState(() => isPasswordVisible = !isPasswordVisible),
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: confirmPasswordController,
                            label: 'Confirm Password',
                            isPassword: true,
                            isVisible: isConfirmPasswordVisible,
                            onVisibilityChanged: () => setState(
                                () => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: isLoading ? null : signUpUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D40DA),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('SIGN UP'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/login_page'),
                            child: Text(
                              "Already have an account? LOGIN",
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDarkMode ? Colors.white70 : Colors.black45,
                ),
                onPressed: onVisibilityChanged,
              )
            : null,
      ),
    );
  }
}
