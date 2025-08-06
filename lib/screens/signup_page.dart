import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  final bool isDarkMode;
  final Future<void> Function(bool isDark) onThemeChanged;

  const SignUpPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isEmailVerified = false;
  late bool isDarkMode;
  StreamSubscription? _verificationSubscription;
  
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _verificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleDarkMode() async {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    await widget.onThemeChanged(isDarkMode);
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length() / 1024 / 1024; // Size in MB
        
        if (fileSize > 5) {
          _showErrorSnackBar('Image size should be less than 5MB');
          return;
        }
        
        setState(() {
          _profileImage = file;
        });
      }
    } on PlatformException catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
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
      return 'Please enter your password';
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

  Future<void> _sendVerificationEmail() async {
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

      await userCredential.user!.updateDisplayName(nameController.text.trim());
      await userCredential.user!.sendEmailVerification();

      _showSuccessSnackBar('Verification email sent! Please check your inbox.');
      
      // Start checking for email verification
      _startEmailVerificationCheck();
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration Failed";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Email already in use. Please use a different email.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak. Please choose a stronger password.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Email/password accounts are not enabled.";
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startEmailVerificationCheck() {
    _verificationSubscription?.cancel();
    _verificationSubscription = Stream.periodic(const Duration(seconds: 3)).listen((_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null && user.emailVerified) {
        _verificationSubscription?.cancel();
        if (mounted) {
          setState(() {
            isEmailVerified = true;
          });
          _showSuccessSnackBar('Email verified successfully!');
        }
      }
    });
  }

  Future<void> _registerUser() async {
    if (!isEmailVerified) {
      _showErrorSnackBar('Please verify your email first.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('User not found. Please try again.');
        return;
      }

      // Convert image to Base64 if exists
      String? profileImageBase64;
      if (_profileImage != null) {
        final bytes = await _profileImage!.readAsBytes();
        profileImageBase64 = base64Encode(bytes);
      }

      // Create user data map with consistent field names
      final userData = {
        'uid': user.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // Add profile image field that matches what HomePage expects
      if (profileImageBase64 != null) {
        userData['profileImageBase64'] = profileImageBase64;
        userData['imageUrl'] = 'data:image/jpeg;base64,$profileImageBase64'; // For compatibility
      } else {
        userData['imageUrl'] = ''; // Empty string if no image
      }

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      // Save user data to SharedPreferences for immediate access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.uid);
      await prefs.setString('userName', nameController.text.trim());
      await prefs.setString('userEmail', emailController.text.trim());
      if (profileImageBase64 != null) {
        await prefs.setString('userImage', 'data:image/jpeg;base64,$profileImageBase64');
      }

      _showSuccessSnackBar('Registration completed successfully!');
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to complete registration. Please try again.');
      debugPrint('Error saving user data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
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

  void _showSuccessSnackBar(String message) {
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
                    onPressed: _toggleDarkMode,
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? screenWidth * 0.25 : 20,
                    vertical: isSmallScreen ? 20 : 40,
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
                              minHeight: isSmallScreen ? 600 : 680,
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SIGN UP',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 24 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 8),
                                  Text(
                                    'Create your account',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: isDarkMode ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 20 : 24),

                                  // Profile Image Picker
                                  _buildProfileImagePicker(isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  _buildTextField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    prefixIcon: Icons.person_outline,
                                    validator: _validateName,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  _buildTextField(
                                    controller: emailController,
                                    label: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    validator: _validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

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
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  _buildTextField(
                                    controller: confirmPasswordController,
                                    label: 'Confirm Password',
                                    prefixIcon: Icons.lock_outline,
                                    isPassword: true,
                                    isVisible: isConfirmPasswordVisible,
                                    validator: _validateConfirmPassword,
                                    onVisibilityChanged: () =>
                                        setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 24 : 32),

                                  // Verify Email Button or Sign Up Button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: isSmallScreen ? 48 : 52,
                                    child: ElevatedButton(
                                      onPressed: isLoading 
                                          ? null 
                                          : (isEmailVerified ? _registerUser : _sendVerificationEmail),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isEmailVerified 
                                            ? Colors.green[600]
                                            : const Color(0xFF0D40DA),
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: (isEmailVerified 
                                            ? Colors.green[600] 
                                            : const Color(0xFF0D40DA))?.withOpacity(0.4),
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
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  isEmailVerified 
                                                      ? Icons.check_circle_outline
                                                      : Icons.email_outlined,
                                                  size: isSmallScreen ? 20 : 24,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  isEmailVerified ? 'COMPLETE REGISTRATION' : 'SEND VERIFICATION',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 24),

                                  if (!isEmailVerified)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDarkMode 
                                            ? Colors.blue[900]?.withOpacity(0.3)
                                            : Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDarkMode 
                                              ? Colors.blue[400]!
                                              : Colors.blue[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: isDarkMode 
                                                ? Colors.blue[300]
                                                : Colors.blue[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Click the verification link sent to your email',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 12 : 14,
                                                color: isDarkMode 
                                                    ? Colors.blue[300]
                                                    : Colors.blue[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (isEmailVerified)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDarkMode 
                                            ? Colors.green[900]?.withOpacity(0.3)
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDarkMode 
                                              ? Colors.green[400]!
                                              : Colors.green[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: isDarkMode 
                                                ? Colors.green[300]
                                                : Colors.green[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Email verified! You can now complete registration',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 12 : 14,
                                                color: isDarkMode 
                                                    ? Colors.green[300]
                                                    : Colors.green[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  SizedBox(height: isSmallScreen ? 16 : 24),

                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pushReplacementNamed(context, '/login'),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 15,
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                        children: [
                                          const TextSpan(text: "Already have an account? "),
                                          TextSpan(
                                            text: "SIGN IN",
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

  Widget _buildProfileImagePicker(bool isSmallScreen) {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        width: isSmallScreen ? 80 : 100,
        height: isSmallScreen ? 80 : 100,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          shape: BoxShape.circle,
          border: Border.all(
            color: isDarkMode ? Colors.white60 : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: _profileImage != null
            ? ClipOval(
                child: Image.file(
                  _profileImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Icon(
                Icons.add_a_photo,
                size: isSmallScreen ? 30 : 40,
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
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
          borderSide: const BorderSide(
            color: Colors.black,
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