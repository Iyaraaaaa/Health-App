import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SignupPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(
        builder: (context) => const SignupPage(),
      );

  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isDarkMode = false;

  File? _pickedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
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

  void signUpUser() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? const LinearGradient(
                  colors: [
                    Color(0xFF121212),
                    Color(0xFF424242),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFF008080),
                    Color(0xFF4F86F7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Dark Mode Toggle
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

            // Center Signup Card
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
                          // Image picker avatar
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              backgroundImage: _pickedImage != null
                                  ? FileImage(_pickedImage!)
                                  : const AssetImage('assets/images/empty.jpg')
                                      as ImageProvider,
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

                          // Email Field
                          TextField(
                            controller: emailController,
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password Field
                          TextField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible,
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black45,
                                ),
                                onPressed: () => setState(
                                    () => isPasswordVisible = !isPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password Field
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: !isConfirmPasswordVisible,
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black45,
                                ),
                                onPressed: () => setState(() =>
                                    isConfirmPasswordVisible =
                                        !isConfirmPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sign Up Button
                          ElevatedButton(
                            onPressed: signUpUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D40DA),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('SIGN UP'),
                          ),
                          const SizedBox(height: 10),

                          // Login Link
                          TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/login_page'),
                            child: Text(
                              "Already have an account? LOGIN",
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
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
}