import 'package:flutter/material.dart';

class CombinedOnboardingScreen extends StatefulWidget {
  const CombinedOnboardingScreen({super.key});

  @override
  State<CombinedOnboardingScreen> createState() => _CombinedOnboardingScreenState();
}

class _CombinedOnboardingScreenState extends State<CombinedOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = [
    // Landing Page (now first onboarding screen)
    _buildLandingPage(),
    
    // Regular onboarding screens
    _buildOnboardingPage(
      image: 'assets/images/on_board_1.avif',
      title: 'Access Quality Healthcare',
      description: 'Connect with certified doctors and health services near you.',
    ),
    _buildOnboardingPage(
      image: 'assets/images/on_board_2.jpg',
      title: 'Easy Appointment Booking',
      description: 'Schedule your health visits seamlessly and securely.',
    ),
    _buildOnboardingPage(
      image: 'assets/images/on_board_3.jpg',
      title: 'Your Health, Our Priority',
      description: 'Committed to providing reliable and caring health support.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: _pages,
          ),
          
          // Page indicators
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          
          // Navigation buttons
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip button (shown on all pages except last)
                if (_currentPage < _pages.length - 1)
                  TextButton(
                    onPressed: () => _goToLogin(),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                
                // Next/Get Started button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      _goToLogin();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  static Widget _buildLandingPage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/landing.jpg', height: 300),
          const SizedBox(height: 40),
          const Text(
            'Welcome to Ministry of Health',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'සෞඛ්‍ය අමාත්‍යාංශයට සාදරයෙන් පිළිගනිමු',
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'சுகாதார அமைச்சில் உங்களை வரவேற்கிறோம்',
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildOnboardingPage({
    required String image,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}