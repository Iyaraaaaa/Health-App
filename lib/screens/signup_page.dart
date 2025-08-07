import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

  // Separate loading states for each button
  bool isEmailLoading = false;
  bool isGoogleLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isEmailVerified = false;
  bool isGoogleSignUp = false; // Track if user is signing up with Google
  late bool isDarkMode;
  StreamSubscription? _verificationSubscription;
  
  File? _profileImage;
  String? _googleImageUrl; // Store Google profile image URL
  final ImagePicker _picker = ImagePicker();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

  Future<void> _signUpWithGoogle() async {
    setState(() => isGoogleLoading = true);

    try {
      // Sign out any existing Google account first
      await _googleSignIn.signOut();
      
      // Start the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        setState(() => isGoogleLoading = false);
        return;
      }

      // Get the authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;
      
      if (user != null) {
        // Pre-fill the form with Google account data
        setState(() {
          nameController.text = user.displayName ?? '';
          emailController.text = user.email ?? '';
          _googleImageUrl = user.photoURL;
          isGoogleSignUp = true;
          isEmailVerified = true; // Google accounts are considered verified
        });

        _showSuccessSnackBar('Google account connected! Complete your registration below.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Google Sign-In failed";
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage = "An account already exists with this email using a different sign-in method.";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "Invalid credentials. Please try again.";
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: ${e.toString()}');
    } finally {
      setState(() => isGoogleLoading = false);
    }
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
          _googleImageUrl = null; // Clear Google image when user picks a new one
        });
      }
    } on PlatformException catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<String?> _downloadImageAsBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
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
    if (isGoogleSignUp) return null; // Skip password validation for Google sign-up
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (isGoogleSignUp) return null; // Skip confirm password validation for Google sign-up
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _sendVerificationEmail() async {
    if (isGoogleSignUp) {
      // Skip email verification for Google accounts
      await _registerUser();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isEmailLoading = true);

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
      if (mounted) setState(() => isEmailLoading = false);
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
    if (!isEmailVerified && !isGoogleSignUp) {
      _showErrorSnackBar('Please verify your email first.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isEmailLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('User not found. Please try again.');
        return;
      }

      // Handle profile image
      String? profileImageBase64;
      String imageUrl = '';

      if (_profileImage != null) {
        // Use manually selected image
        final bytes = await _profileImage!.readAsBytes();
        profileImageBase64 = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$profileImageBase64';
      } else if (_googleImageUrl != null) {
        // Use Google profile image
        profileImageBase64 = await _downloadImageAsBase64(_googleImageUrl!);
        if (profileImageBase64 != null) {
          imageUrl = 'data:image/jpeg;base64,$profileImageBase64';
        } else {
          imageUrl = _googleImageUrl!; // Fallback to original URL
        }
      }

      // Create user data map with consistent field names
      final userData = {
        'uid': user.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'signUpMethod': isGoogleSignUp ? 'google' : 'email',
      };

      // Add profile image fields
      if (profileImageBase64 != null) {
        userData['profileImageBase64'] = profileImageBase64;
      }
      userData['imageUrl'] = imageUrl;

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
      await prefs.setString('signUpMethod', isGoogleSignUp ? 'google' : 'email');
      if (imageUrl.isNotEmpty) {
        await prefs.setString('userImage', imageUrl);
      }

      _showSuccessSnackBar('Registration completed successfully!');
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to complete registration. Please try again.');
      debugPrint('Error saving user data: $e');
    } finally {
      if (mounted) setState(() => isEmailLoading = false);
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
    final isVerySmallScreen = screenHeight < 600;

    // Check if any loading is happening for UI interactions
    final isAnyLoading = isEmailLoading || isGoogleLoading;

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
                    onPressed: _toggleDarkMode,
                  ),
                ),
              ),
              // Main content
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? screenWidth * 0.25 : 16,
                        vertical: isVerySmallScreen ? 8 : (isSmallScreen ? 16 : 24),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - (isVerySmallScreen ? 16 : (isSmallScreen ? 32 : 48)),
                          ),
                          child: IntrinsicHeight(
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
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxWidth: 400),
                                  padding: EdgeInsets.all(isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title
                                        Text(
                                          'SIGN UP',
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 28),
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        SizedBox(height: isVerySmallScreen ? 2 : 4),
                                        Text(
                                          'Create your account',
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 16),
                                            color: isDarkMode ? Colors.white60 : Colors.black54,
                                          ),
                                        ),
                                        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

                                        // Profile Image Picker
                                        _buildProfileImagePicker(isSmallScreen, isVerySmallScreen),
                                        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),

                                        // Form fields with reduced spacing
                                        _buildTextField(
                                          controller: nameController,
                                          label: 'Full Name',
                                          prefixIcon: Icons.person_outline,
                                          validator: _validateName,
                                          isSmallScreen: isSmallScreen,
                                          isVerySmallScreen: isVerySmallScreen,
                                        ),
                                        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),

                                        _buildTextField(
                                          controller: emailController,
                                          label: 'Email',
                                          prefixIcon: Icons.email_outlined,
                                          validator: _validateEmail,
                                          keyboardType: TextInputType.emailAddress,
                                          isSmallScreen: isSmallScreen,
                                          isVerySmallScreen: isVerySmallScreen,
                                          enabled: !isGoogleSignUp, // Disable if Google sign-up
                                        ),
                                        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),

                                        // Hide password fields for Google sign-up
                                        if (!isGoogleSignUp) ...[
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
                                            isVerySmallScreen: isVerySmallScreen,
                                          ),
                                          SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),

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
                                            isVerySmallScreen: isVerySmallScreen,
                                          ),
                                          SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
                                        ],

                                        // Main action button (Email signup/verification)
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: double.infinity,
                                          height: isVerySmallScreen ? 42 : (isSmallScreen ? 45 : 52),
                                          child: ElevatedButton(
                                            onPressed: isAnyLoading 
                                                ? null 
                                                : (isEmailVerified || isGoogleSignUp ? _registerUser : _sendVerificationEmail),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (isEmailVerified || isGoogleSignUp)
                                                  ? Colors.green[600]
                                                  : const Color(0xFF0D40DA),
                                              foregroundColor: Colors.white,
                                              elevation: 8,
                                              shadowColor: ((isEmailVerified || isGoogleSignUp)
                                                  ? Colors.green[600] 
                                                  : const Color(0xFF0D40DA))?.withOpacity(0.4),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: isEmailLoading
                                                ? SizedBox(
                                                    height: isVerySmallScreen ? 16 : 20,
                                                    width: isVerySmallScreen ? 16 : 20,
                                                    child: const CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        (isEmailVerified || isGoogleSignUp)
                                                            ? Icons.check_circle_outline
                                                            : Icons.email_outlined,
                                                        size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                          (isEmailVerified || isGoogleSignUp) ? 'COMPLETE REGISTRATION' : 'SEND VERIFICATION',
                                                          style: TextStyle(
                                                            fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

                                        // Status messages
                                        if (!isEmailVerified && !isGoogleSignUp)
                                          _buildInfoContainer(
                                            icon: Icons.info_outline,
                                            text: 'Click the verification link sent to your email',
                                            color: Colors.blue,
                                            isSmallScreen: isSmallScreen,
                                            isVerySmallScreen: isVerySmallScreen,
                                          ),

                                        if (isEmailVerified && !isGoogleSignUp)
                                          _buildInfoContainer(
                                            icon: Icons.check_circle,
                                            text: 'Email verified! You can now complete registration',
                                            color: Colors.green,
                                            isSmallScreen: isSmallScreen,
                                            isVerySmallScreen: isVerySmallScreen,
                                          ),

                                        if (isGoogleSignUp)
                                          _buildInfoContainer(
                                            icon: Icons.check_circle,
                                            text: 'Google account connected! Complete registration below',
                                            color: Colors.green,
                                            isSmallScreen: isSmallScreen,
                                            isVerySmallScreen: isVerySmallScreen,
                                          ),

                                        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

                                        // OR Divider (only show if not using Google signup)
                                        if (!isGoogleSignUp) ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: isDarkMode ? Colors.white30 : Colors.black26,
                                                  thickness: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Text(
                                                  'OR',
                                                  style: TextStyle(
                                                    color: isDarkMode ? Colors.white60 : Colors.black54,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: isDarkMode ? Colors.white30 : Colors.black26,
                                                  thickness: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

                                          // Google Sign-Up Button (moved to bottom like LoginPage)
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: double.infinity,
                                            height: isVerySmallScreen ? 42 : (isSmallScreen ? 45 : 52),
                                            child: ElevatedButton(
                                              onPressed: isAnyLoading ? null : _signUpWithGoogle,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                                foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                                                elevation: 2,
                                                shadowColor: Colors.black26,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: isGoogleLoading
                                                  ? SizedBox(
                                                      height: isVerySmallScreen ? 16 : 20,
                                                      width: isVerySmallScreen ? 16 : 20,
                                                      child: CircularProgressIndicator(
                                                        color: isDarkMode ? Colors.white : Colors.black54,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Container(
                                                          width: isVerySmallScreen ? 16 : 20,
                                                          height: isVerySmallScreen ? 16 : 20,
                                                          child: CustomPaint(
                                                            painter: GoogleIconPainter(),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          'GOOGLE SIGN UP',
                                                          style: TextStyle(
                                                            fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                                                            fontWeight: FontWeight.bold,
                                                            color: isDarkMode ? Colors.white : Colors.black87,
                                                            letterSpacing: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                          SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
                                        ],

                                        // Sign in link
                                        TextButton(
                                          onPressed: isAnyLoading
                                              ? null
                                              : () => Navigator.pushReplacementNamed(context, '/login'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                          ),
                                          child: RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 15),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker(bool isSmallScreen, bool isVerySmallScreen) {
    final size = isVerySmallScreen ? 60.0 : (isSmallScreen ? 70.0 : 80.0);
    
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        width: size,
        height: size,
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
            : _googleImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _googleImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDarkMode ? Colors.white60 : Colors.grey[600],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.add_a_photo,
                        size: isVerySmallScreen ? 20 : (isSmallScreen ? 25 : 30),
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  )
                : Icon(
                    Icons.add_a_photo,
                    size: isVerySmallScreen ? 20 : (isSmallScreen ? 25 : 30),
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
      ),
    );
  }

  Widget _buildInfoContainer({
    required IconData icon,
    required String text,
    required MaterialColor color,
    required bool isSmallScreen,
    required bool isVerySmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 16)),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? color[900]?.withOpacity(0.3)
            : color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode 
              ? color[400]!
              : color[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode 
                ? color[300]
                : color[600],
            size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 14),
                color: isDarkMode 
                    ? color[300]
                    : color[700],
              ),
            ),
          ),
        ],
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
    bool isVerySmallScreen = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        color: enabled 
            ? (isDarkMode ? Colors.white : Colors.black87)
            : (isDarkMode ? Colors.white54 : Colors.black54),
        fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 16),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          prefixIcon,
          color: enabled 
              ? (isDarkMode ? Colors.white60 : Colors.grey[600])
              : (isDarkMode ? Colors.white38 : Colors.grey[400]),
          size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
        ),
        labelStyle: TextStyle(
          color: enabled 
              ? (isDarkMode ? Colors.white70 : Colors.black54)
              : (isDarkMode ? Colors.white38 : Colors.black38),
          fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 16),
        ),
        filled: true,
        fillColor: enabled 
            ? (isDarkMode 
                ? Colors.grey[850]?.withOpacity(0.8) 
                : Colors.grey[100]?.withOpacity(0.8))
            : (isDarkMode 
                ? Colors.grey[800]?.withOpacity(0.5)
                : Colors.grey[200]?.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: enabled ? Colors.black : Colors.grey,
            width: enabled ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: enabled ? const Color(0xFF0D40DA) : Colors.grey,
            width: enabled ? 2 : 1,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
          vertical: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 16),
        ),
        isDense: isVerySmallScreen || isSmallScreen,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: enabled 
                      ? (isDarkMode ? Colors.white60 : Colors.grey[600])
                      : (isDarkMode ? Colors.white38 : Colors.grey[400]),
                  size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                ),
                onPressed: enabled ? onVisibilityChanged : null,
              )
            : null,
      ),
    );
  }
}

// Add the GoogleIconPainter class (same as in LoginPage)
class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Google "G" colors
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw the Google "G" logo
    // Blue section (top right)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees in radians
      1.57,  // 90 degrees in radians
      true,
      bluePaint,
    );
    
    // Green section (bottom right)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,     // 0 degrees
      1.57,  // 90 degrees
      true,
      greenPaint,
    );
    
    // Yellow section (bottom left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57,  // 90 degrees
      1.57,  // 90 degrees
      true,
      yellowPaint,
    );
    
    // Red section (top left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,  // 180 degrees
      1.57,  // 90 degrees
      true,
      redPaint,
    );
    
    // Draw white circle in center to create the "G" shape
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, whitePaint);
    
    // Draw the horizontal line to complete the "G"
    final linePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = radius * 0.2
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.7, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}