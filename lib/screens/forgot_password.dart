import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final emailController = TextEditingController();
  bool isLoading = false;
  bool isDarkMode = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // Firebase password reset method
  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your email.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      // Show success dialog
      _showSuccessDialog('Password reset email sent!');
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      String errorMessage = "Failed to send reset email";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('An unexpected error occurred: $e');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login_page'); // Navigate back to login
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
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
                              minHeight: isSmallScreen ? 300 : 380,
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                            child: Form(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title
                                  Text(
                                    'FORGOT PASSWORD',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 24 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // Email field
                                  _buildTextField(
                                    controller: emailController,
                                    label: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // Reset button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: isSmallScreen ? 48 : 52,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : resetPassword,
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
                                              'SEND RESET LINK',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 16 : 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // Login link with blue and underlined text
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushReplacementNamed(context, '/login_page'),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 15,
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                        children: [
                                          const TextSpan(text: "Remembered your password? "),
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
    TextInputType? keyboardType,
    bool isSmallScreen = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Adding bottom margin for spacing
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2), // Black border around text field
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: isSmallScreen ? 14 : 16,
        ),
        keyboardType: keyboardType,
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
            borderSide: BorderSide.none,
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
        ),
      ),
    );
  }
}
