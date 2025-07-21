
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required void Function(Locale locale) onLocaleChange, required Locale locale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/landing_bg.jpg', fit: BoxFit.cover),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Welcome to Ministry of Health Sri Lanka',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
                Text('ශ්‍රී ලංකා සෞඛ්‍ය අමාත්‍යාංශයට සාදරයෙන් පිළිගනිමු',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Text('இலங்கை சுகாதார அமைச்சில் உங்களை வரவேற்கிறோம்',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
