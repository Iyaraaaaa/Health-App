import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';

import 'affirmation.dart';
import 'privacy.dart';
import 'search.dart';
import 'edit_profile.dart';
import 'notifications.dart';
import 'about_us.dart';
import 'login_page.dart';

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

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildHomePlaceholder("Welcome"), // placeholder text
      const AffirmationPage(),
      const SearchPage(),
    ];
    _loadUserData();
  }

  Widget _buildHomePlaceholder(String text) {
    return Center(
      child: Text(
        '$text, $_userName!',
        style: const TextStyle(fontSize: 24),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final List<String> _titles = [loc.home, loc.affirmation, loc.search];
    _pages[0] = _buildHomePlaceholder(loc.welcome); // update localized welcome text

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: loc.changeLanguage,
            onSelected: (Locale locale) {
              widget.onLocaleChange(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: const [
                    Icon(Icons.language, color: Colors.red),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('si'),
                child: Row(
                  children: const [
                    Icon(Icons.language, color: Colors.green),
                    SizedBox(width: 8),
                    Text('සිංහල'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('ta'),
                child: Row(
                  children: const [
                    Icon(Icons.language, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('தமிழ்'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
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
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: loc.home),
          BottomNavigationBarItem(
              icon: const Icon(Icons.local_hospital), label: loc.affirmation),
          BottomNavigationBarItem(
              icon: const Icon(Icons.search), label: loc.search),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      drawer: _buildDrawer(loc),
    );
  }

  Widget _buildDrawer(AppLocalizations loc) {
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
                decoration: const BoxDecoration(color: Colors.blue),
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
          _buildDrawerItem(
              Icons.info, loc.aboutUs, Colors.teal, AboutUsPage()),
          _buildDrawerItem(Icons.logout, loc.logOut, Colors.amber,
              const LoginPage(),
              isLogout: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      IconData icon, String title, Color iconColor, Widget page,
      {bool isLogout = false}) {
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
