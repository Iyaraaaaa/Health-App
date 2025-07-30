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
  final _formKey = GlobalKey<FormState>();
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
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
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

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> signUpUser() async {
    if (!_formKey.currentState!.validate()) {
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

      _showSuccessSnackBar('Account created successfully!');
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
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
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

  void _showSuccessSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: screenHeight,
        width: screenWidth,
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
        child: SafeArea(
          child: Stack(
            children: [
              // Theme toggle button
              Positioned(
                top: 10,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                      color: isDarkMode ? Colors.amber : Colors.white,
                      size: 24,
                    ),
                    onPressed: () => setState(() => isDarkMode = !isDarkMode),
                  ),
                ),
              ),
              // Main content
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? screenWidth * 0.25 : 20,
                    vertical: isSmallScreen ? 10 : 20,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: Card(
                          elevation: 20,
                          shadowColor: Colors.black.withOpacity(0.3),
                          color: isDarkMode
                              ? Colors.grey[900]?.withOpacity(0.95)
                              : Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 400,
                              minHeight: isSmallScreen ? 500 : 600,
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Profile image picker
                                  GestureDetector(
                                    onTap: isLoading ? null : _pickImage,
                                    child: Hero(
                                      tag: 'profile_image',
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: isSmallScreen ? 40 : 50,
                                          backgroundColor: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[300],
                                          backgroundImage: _pickedImage != null
                                              ? FileImage(_pickedImage!)
                                              : null,
                                          child: _pickedImage == null
                                              ? Icon(
                                                  Icons.add_a_photo,
                                                  size: isSmallScreen ? 30 : 35,
                                                  color: isDarkMode
                                                      ? Colors.white60
                                                      : Colors.grey[600],
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                  
                                  Text(
                                    'Add Profile Photo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // Title
                                  Text(
                                    'SIGN UP',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 24 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 20 : 24),

                                  // Form fields with border and margins
                                  _buildTextField(
                                    controller: fullNameController,
                                    label: 'Full Name',
                                    prefixIcon: Icons.person_outline,
                                    validator: _validateFullName,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),

                                  _buildTextField(
                                    controller: emailController,
                                    label: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    validator: _validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),

                                  _buildTextField(
                                    controller: passwordController,
                                    label: 'Password',
                                    prefixIcon: Icons.lock_outline,
                                    isPassword: true,
                                    isVisible: isPasswordVisible,
                                    validator: _validatePassword,
                                    onVisibilityChanged: () =>
                                        setState(() => isPasswordVisible = !isPasswordVisible),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),

                                  _buildTextField(
                                    controller: confirmPasswordController,
                                    label: 'Confirm Password',
                                    prefixIcon: Icons.lock_outline,
                                    isPassword: true,
                                    isVisible: isConfirmPasswordVisible,
                                    validator: _validateConfirmPassword,
                                    onVisibilityChanged: () => setState(
                                        () => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 20 : 28),

                                  // Sign up button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: isSmallScreen ? 48 : 52,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : signUpUser,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D40DA),
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: const Color(0xFF0D40DA).withOpacity(0.4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'SIGN UP',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 16 : 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // Login link
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pushReplacementNamed(context, '/login_page'),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 15,
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                        children: [
                                          const TextSpan(text: "Already have an account? "),
                                          TextSpan(
                                            text: "LOGIN",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0D40DA),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
    TextInputType? keyboardType,
    bool isSmallScreen = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: isSmallScreen ? 14 : 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          prefixIcon,
          color: isDarkMode ? Colors.white60 : Colors.grey[600],
          size: isSmallScreen ? 20 : 24,
        ),
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: isSmallScreen ? 14 : 16,
        ),
        filled: true,
        fillColor: isDarkMode
            ? Colors.grey[850]?.withOpacity(0.8)
            : Colors.grey[100]?.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black, // Black border color
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF0D40DA),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red[400]!,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmallScreen ? 12 : 16,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: onVisibilityChanged,
              )
            : null,
      ),
    );
  }
}
