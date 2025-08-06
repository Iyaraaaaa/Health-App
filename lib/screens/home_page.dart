import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:health_project/screens/about_us.dart';
import 'package:health_project/screens/affirmation.dart';
import 'package:health_project/screens/contact_us.dart';
import 'package:health_project/screens/edit_profile.dart';
import 'package:health_project/screens/login_page.dart';
import 'package:health_project/screens/notifications.dart';
import 'package:health_project/screens/privacy.dart';
import 'package:health_project/screens/search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  final Function(Locale) onLocaleChange;
  final Locale locale;

  const HomePage({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.onLocaleChange,
    required this.locale,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = "User Name";
  String _userEmail = "user@example.com";
  String _userImage = '';
  String _userId = '';

  late List<Widget> _pages;
  late PageController _pageController;
  late Timer _timer;
  late AnimationController _networkAnimationController;
  int _currentPage = 0;

  // Country flag icons using emoji flags
  final Map<String, String> flagIcons = {
    'en': '🇺🇸', // United States flag
    'si': '🇱🇰', // Sri Lanka flag
    'ta': '🇮🇳', // India flag (for Tamil)
  };

  // Language names
  final Map<String, String> languageNames = {
    'en': 'English',
    'si': 'Sinhala',
    'ta': 'Tamil',
  };

  final List<String> _sliderImages = [
    'assets/images/a.jpg',
    'assets/images/b.jpg',
    'assets/images/c.png',
  ];

  final List<Map<String, String>> _leadershipTeam = [
    {'image': 'assets/images/p1.jpg', 'title': 'minister', 'name': 'Dr. Nalinda Jayatissa'},
    {'image': 'assets/images/p2.jpg', 'title': 'deputyMinister', 'name': 'Dr. Hansaka Vijemuni'},
    {'image': 'assets/images/p3.jpg', 'title': 'secretary', 'name': 'Dr. Anil Jayasighe'},
    {'image': 'assets/images/p4.jpg', 'title': 'directorGeneral', 'name': 'Dr. Asela Gunawaradena'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _networkAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _loadUserData();
    _pages = [
      Container(),
      const AffirmationPage(),
      const SearchPage(),
    ];
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      setState(() {
        _pages[0] = _buildHomeContent(loc);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _networkAnimationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _sliderImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
      _userName = prefs.getString('userName') ?? "User Name";
      _userEmail = prefs.getString('userEmail') ?? "user@example.com";
      _userImage = prefs.getString('userImage') ?? '';
    });

    if (_userId.isNotEmpty) {
      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          _userName = userData?['name'] ?? _userName;
          _userEmail = userData?['email'] ?? _userEmail;
          _userImage = userData?['imageUrl'] ?? _userImage;
        });

        // Update shared preferences
        await prefs.setString('userName', _userName);
        await prefs.setString('userEmail', _userEmail);
        if (_userImage.isNotEmpty) {
          await prefs.setString('userImage', _userImage);
        }
      }
    }
  }

  Widget _getProfileImage() {
    if (_userImage.isEmpty) {
      return Icon(
        Icons.account_circle,
        size: 40,
        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          _userImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.account_circle,
              size: 40,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            );
          },
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getSliderCaption(int index, AppLocalizations loc) {
    switch (index) {
      case 0: return loc.publicHealth ?? "Public Health";
      case 1: return loc.hospitalBaseCare ?? "Hospital Base Care";
      case 2: return loc.yourHealthWellBeing ?? "Your Health & Well Being";
      default: return "Health Services";
    }
  }

  Widget _buildNetworkBackground() {
    return AnimatedBuilder(
      animation: _networkAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: NetworkPainter(
            animationValue: _networkAnimationController.value,
            isDarkMode: widget.isDarkMode,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHomeContent(AppLocalizations loc) {
    final bool isDark = widget.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey[850]!.withOpacity(0.9) : Colors.white.withOpacity(0.95);

    return Stack(
      children: [
        Positioned.fill(child: _buildNetworkBackground()),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [Colors.blue.shade900.withOpacity(0.8), Colors.purple.shade900.withOpacity(0.8)]
                        : [Colors.blue.shade100.withOpacity(0.9), Colors.purple.shade100.withOpacity(0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    loc.welcomeToHealthMinistry ?? 'Welcome to Health Ministry',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Container(
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _sliderImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(_sliderImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getSliderCaption(index, loc),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  onPageChanged: (index) {
                    _currentPage = index;
                  },
                ),
              ),
              const SizedBox(height: 30),
              
              Text(
                loc.ourVision ?? 'Our Vision',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: cardColor,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    loc.visionText ?? 'To provide quality healthcare services to all citizens.',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Text(
                loc.ministryLeadership ?? 'Ministry Leadership',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              ..._leadershipTeam.map((leader) => _buildLeaderCard(
                    context,
                    leader['image']!,
                    leader['title']!,
                    leader['name']!,
                    cardColor,
                    textColor,
                    loc,
                  )),
              const SizedBox(height: 30),
              
              Text(
                loc.ourMission ?? 'Our Mission',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: cardColor,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    loc.missionText ?? 'To ensure accessible, equitable, and quality healthcare for all.',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderCard(
    BuildContext context,
    String imagePath,
    String titleKey,
    String name,
    Color cardColor,
    Color textColor,
    AppLocalizations loc,
  ) {
    final titleTranslations = {
      'minister': loc.minister ?? 'Minister',
      'deputyMinister': loc.deputyMinister ?? 'Deputy Minister',
      'secretary': loc.secretary ?? 'Secretary',
      'directorGeneral': loc.directorGeneral ?? 'Director General',
    };

    return Card(
      color: cardColor,
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleTranslations[titleKey] ?? titleKey,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    if (loc == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<String> _titles = [
      loc.home ?? 'Home', 
      loc.affirmation ?? 'Affirmation', 
      loc.search ?? 'Search'
    ];
    
    _pages[0] = _buildHomeContent(loc);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
        elevation: 0,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: loc.changeLanguage ?? 'Change Language',
            onSelected: (Locale locale) {
              widget.onLocaleChange(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: [
                    Text(flagIcons['en']!),
                    const SizedBox(width: 8),
                    Text('${languageNames['en']}'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('si'),
                child: Row(
                  children: [
                    Text(flagIcons['si']!),
                    const SizedBox(width: 8),
                    Text('${languageNames['si']}'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('ta'),
                child: Row(
                  children: [
                    Text(flagIcons['ta']!),
                    const SizedBox(width: 8),
                    Text('${languageNames['ta']}'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              color: widget.isDarkMode ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
            tooltip: widget.isDarkMode
                ? (loc.switchToLightMode ?? 'Switch to Light Mode')
                : (loc.switchToDarkMode ?? 'Switch to Dark Mode'),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: widget.isDarkMode ? Colors.white70 : Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home), 
            label: loc.home ?? 'Home'
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_hospital), 
            label: loc.affirmation ?? 'Affirmation'
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search), 
            label: loc.search ?? 'Search'
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      drawer: _buildDrawer(loc),
    );
  }

  Widget _buildDrawer(AppLocalizations loc) {
    final bool isDark = widget.isDarkMode;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(_userName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(_userEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: _getProfileImage(),
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.blue,
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          userName: _userName,
                          userEmail: _userEmail,
                          userImage: _userImage,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _loadUserData();
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          _buildDrawerItem(Icons.notifications, loc.notifications ?? 'Notifications',
              Colors.purple, NotificationsPage()),
          _buildDrawerItem(Icons.privacy_tip, loc.privacy ?? 'Privacy', Colors.green,
              PrivacyPage()),
          _buildDrawerItem(Icons.info, loc.aboutUs ?? 'About Us', Colors.teal, AboutUsPage()),
          _buildDrawerItem(Icons.phone, loc.contactUs ?? 'Contact Us', Colors.blue, const ContactUsPage()),
          _buildDrawerItem(Icons.logout, loc.logOut ?? 'Log Out',
              isDark ? const Color.fromARGB(255, 144, 231, 163) : const Color.fromARGB(255, 198, 117, 174),
              LoginPage(
                onThemeChanged: (bool value) async {
                  widget.onThemeChanged(value);
                },
                onGoogleSignIn: () async {
                  // Provide your Google sign-in logic here
                  return;
                },
                isDarkMode: widget.isDarkMode,
              ),
              isLogout: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    Color iconColor,
    Widget page, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      tileColor: isLogout
          ? (widget.isDarkMode ? Colors.deepPurple : Colors.amber.shade100)
          : null,
      textColor: widget.isDarkMode ? Colors.white : Colors.black,
      onTap: () async {
        if (isLogout) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => page));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        }
      },
    );
  }
}

class NetworkPainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  NetworkPainter({required this.animationValue, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..style = PaintingStyle.fill;

    final nodes = <Offset>[];
    final random = math.Random(42);
    
    for (int i = 0; i < 20; i++) {
      nodes.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }

    paint.color = isDarkMode 
        ? Colors.blue.withOpacity(0.3)
        : Colors.blue.withOpacity(0.2);

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        if (distance < 150) {
          final opacity = (1 - distance / 150) * 0.5;
          paint.color = isDarkMode
              ? Colors.blue.withOpacity(opacity * 0.6)
              : Colors.blue.withOpacity(opacity * 0.4);
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    for (int i = 0; i < nodes.length; i++) {
      final animatedRadius = 3 + math.sin((animationValue * 2 * math.pi) + i) * 2;
      nodePaint.color = isDarkMode
          ? Colors.orange.withOpacity(0.8)
          : Colors.orange.withOpacity(0.6);
      canvas.drawCircle(nodes[i], animatedRadius, nodePaint);
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDarkMode
          ? [
              Colors.black.withOpacity(0.1),
              Colors.transparent,
              Colors.black.withOpacity(0.1),
            ]
          : [
              Colors.white.withOpacity(0.3),
              Colors.transparent,
              Colors.white.withOpacity(0.3),
            ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect);
    canvas.drawRect(rect, gradientPaint);
  }

  @override
  bool shouldRepaint(NetworkPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}