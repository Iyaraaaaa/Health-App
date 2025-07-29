import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';

// Import your other screens
import 'affirmation.dart';
import 'privacy.dart';
import 'search.dart';
import 'edit_profile.dart';
import 'notifications.dart';
import 'about_us.dart';
import 'login_page.dart';
import 'contact_us.dart'; // Import the new Contact Us page

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

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = "User Name";
  String _userEmail = "user@example.com";
  String _userImage = '';

  late List<Widget> _pages;
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  // Images and captions for slider
  final List<String> _sliderImages = [
    'assets/images/a.jpg', // Public Health
    'assets/images/b.jpg', // Hospital Base Care
    'assets/images/c.png', // Your Health & Well Being
  ];
  final List<String> _sliderCaptions = [
    "Public Health",
    "Hospital Base Care",
    "Your Health & Well Being",
  ];

  // Leadership team data
  final List<Map<String, String>> _leadershipTeam = [
    {
      'image': 'assets/images/p1.jpg',
      'title': 'minister',
      'name': 'Dr. Nalinda Jayatissa',
    },
    {
      'image': 'assets/images/p2.jpg',
      'title': 'deputyMinister',
      'name': 'Dr. Hansaka Vijemuni',
    },
    {
      'image': 'assets/images/p3.jpg',
      'title': 'secretary',
      'name': 'Dr. Anil Jayasighe',
    },
    {
      'image': 'assets/images/p4.jpg',
      'title': 'directorGeneral',
      'name': 'Dr. Asela Gunawaradena',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _loadUserData();
    _pages = [
      Container(), // Will set in didChangeDependencies
      const AffirmationPage(),
      const SearchPage(),
    ];
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _pages[0] = _buildHomeContent(loc);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
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
      _userName = prefs.getString('userName') ?? "User Name";
      _userEmail = prefs.getString('userEmail') ?? "user@example.com";
      _userImage = prefs.getString('userImage') ?? 'assets/images/empty.jpg';
    });
  }

  ImageProvider _getImageProvider() {
    if (_userImage.isEmpty) {
      return const AssetImage('assets/images/empty.jpg');
    } else if (_userImage.startsWith('http')) {
      return NetworkImage(_userImage);
    } else {
      return AssetImage(_userImage);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeContent(AppLocalizations loc) {
    final bool isDark = widget.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final backgroundColor = isDark ? Colors.black : Colors.grey[200]!;

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              '${loc.welcomeTo}, $_userName!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Image slider
            SizedBox(
              height: 230,
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
                              vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black54
                                : Colors.white70,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _sliderCaptions[index],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
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
            
            // Vision Section
            Text(
              loc.ourVision,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  loc.visionText,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Leadership Team
            Text(
              loc.ministryLeadership,
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
                )),
            const SizedBox(height: 30),
            
            // Mission Section
            Text(
              loc.ourMission,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  loc.missionText,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderCard(
    BuildContext context,
    String imagePath,
    String titleKey,
    String name,
    Color cardColor,
    Color textColor,
  ) {
    final loc = AppLocalizations.of(context)!;

    // Map to manually handle dynamic key translation
    final titleTranslations = {
      'minister': loc.minister,
      'deputyMinister': loc.deputyMinister,
      'secretary': loc.secretary,
      'directorGeneral': loc.directorGeneral,
    };

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
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
                    ),
                  ),
                  const SizedBox(height: 4),
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
    final loc = AppLocalizations.of(context)!;

    final List<String> _titles = [loc.home, loc.affirmation, loc.search];
    // Update home page content on every build:
    _pages[0] = _buildHomeContent(loc);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
        actions: [
          PopupMenuButton<Locale>( // Language menu
            icon: const Icon(Icons.language),
            tooltip: loc.changeLanguage,
            onSelected: (Locale locale) {
              widget.onLocaleChange(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('English'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('si'),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('සිංහල'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('ta'),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('தமிழ்'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              color: widget.isDarkMode ? Colors.amber : const Color.fromARGB(255, 247, 249, 251),
            ),
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
            tooltip: widget.isDarkMode
                ? loc.switchToLightMode
                : loc.switchToDarkMode,
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
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: loc.home),
          BottomNavigationBarItem(
              icon: const Icon(Icons.local_hospital), 
              label: loc.affirmation),
          BottomNavigationBarItem(
              icon: const Icon(Icons.search), 
              label: loc.search),
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
                  backgroundImage: _getImageProvider(),
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Failed to load image: $exception');
                  },
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
          _buildDrawerItem(Icons.notifications, loc.notifications,
              Colors.purple, NotificationsPage()),
          _buildDrawerItem(Icons.privacy_tip, loc.privacy, Colors.green,
              PrivacyPage()),
          _buildDrawerItem(Icons.info, loc.aboutUs, Colors.teal, AboutUsPage()),
          _buildDrawerItem(Icons.phone, loc.contactUs, Colors.blue, const ContactUsPage()),
          _buildDrawerItem(Icons.logout, loc.logOut,
              isDark ? const Color.fromARGB(255, 144, 231, 163) : const Color.fromARGB(255, 198, 117, 174),
              const LoginPage(),
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
