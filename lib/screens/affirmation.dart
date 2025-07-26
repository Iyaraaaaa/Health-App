import 'package:flutter/material.dart';

class AffirmationPage extends StatelessWidget {
  const AffirmationPage({super.key});

  final List<String> affirmations = const [
    "I am confident and capable.",
    "I believe in myself.",
    "Every day is a fresh start.",
    "I radiate positivity.",
    "I deserve success and happiness.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affirmations'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: affirmations.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                affirmations[index],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
