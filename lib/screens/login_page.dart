import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:health_project/screens/forgot_password.dart';

class LoginPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(
        builder: (context) => const LoginPage(),
      );

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isDarkMode = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Firebase login method
  Future<void> loginUser() async {
    setState(() => isLoading = true);  // Set loading state to true

    try {
      // Sign in the user using Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Successfully logged in
      Navigator.pushReplacementNamed(context, '/home_page');  // Navigate to home page

    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);  // Set loading state to false after error

      String errorMessage = "Login Failed";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password.";
      }

      // Show error message in a dialog
      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() => isLoading = false);  // Set loading state to false after error
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

            // Center Login Card
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
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
                        TextFormField(
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
                              onPressed: () {
                                setState(() =>
                                    isPasswordVisible = !isPasswordVisible);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D40DA),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('LOGIN'),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/forgot_password'),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: Text(
                            "Need an account? SIGN UP",
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
          ],
        ),
      ),
    );
  }
}
