import 'package:flutter/material.dart';

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
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loginUser() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate login

    setState(() => isLoading = false);

    if (emailController.text == "admin@example.com" &&
        passwordController.text == "password123") {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid credentials"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/login.webp',
            fit: BoxFit.cover,
          ),

          // Optional overlay
          Container(color: Colors.black.withOpacity(0.3)),

          // Login Form
          Center(
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LOGIN',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() => isPasswordVisible = !isPasswordVisible);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 13, 64, 218),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('LOGIN'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forget'),
                        child: const Text('Forgot Password?'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text("Need an account? SIGN UP"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
