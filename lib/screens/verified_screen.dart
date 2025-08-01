import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class VerifiedScreen extends StatefulWidget {
  final User user;
  final File? imageFile;
  final String fullName;

  const VerifiedScreen({
    Key? key,
    required this.user,
    required this.imageFile,
    required this.fullName,
  }) : super(key: key);

  @override
  State<VerifiedScreen> createState() => _VerifiedScreenState();
}

class _VerifiedScreenState extends State<VerifiedScreen> {
  bool isDarkMode = false;
  bool isLoading = false;

  Future<void> checkEmailVerifiedAndSave() async {
    setState(() => isLoading = true);

    // Reload the user
    await widget.user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      // Save user data to Firestore
      String? imageUrl;
      if (widget.imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref();
        final imageRef = storageRef.child(
          'profile_images/${widget.user.uid}${path.extension(widget.imageFile!.path)}',
        );
        await imageRef.putFile(widget.imageFile!);
        imageUrl = await imageRef.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'id': widget.user.uid,
        'email': widget.user.email,
        'fullName': widget.fullName,
        'profileImage': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Go to home or any next page
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home_page');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email not verified yet. Please check your inbox.'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
    setState(() => isLoading = false);
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
                    vertical: isSmallScreen ? 20 : 40,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
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
                            minHeight: isSmallScreen ? 350 : 420,
                          ),
                          padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show profile image (optional)
                              if (widget.imageFile != null)
                                CircleAvatar(
                                  radius: isSmallScreen ? 40 : 50,
                                  backgroundImage: FileImage(widget.imageFile!),
                                  backgroundColor: Colors.transparent,
                                ),
                              if (widget.imageFile != null)
                                SizedBox(height: isSmallScreen ? 12 : 20),

                              Icon(
                                Icons.email_outlined,
                                size: isSmallScreen ? 60 : 80,
                                color: isDarkMode ? Colors.white70 : Colors.blueAccent,
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 22),
                              Text(
                                'Verify Your Email',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 22 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 16),
                              Text(
                                'We\'ve sent an email verification link to:\n${widget.user.email}\n\nPlease verify and then click below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 24 : 32),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                height: isSmallScreen ? 48 : 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : checkEmailVerifiedAndSave,
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
                                          "I've Verified, Continue",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 16 : 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        await widget.user.sendEmailVerification();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Verification email resent!'),
                                            backgroundColor: Colors.green[600],
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Resend Verification Email',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
      ),
    );
  }
}