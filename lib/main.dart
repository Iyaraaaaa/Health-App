import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';

import 'package:health_project/screens/about_us.dart';
import 'package:health_project/screens/edit_profile.dart';
import 'package:health_project/screens/forgot_password.dart';
import 'package:health_project/screens/home_page.dart';
import 'package:health_project/screens/login_page.dart';
import 'package:health_project/screens/logout_page.dart';
import 'package:health_project/screens/notifications.dart';
import 'package:health_project/screens/on_bording.dart';
import 'package:health_project/screens/signup_page.dart';
import 'package:health_project/screens/splash_screen.dart';
import 'package:health_project/screens/welcome.dart';
import 'package:health_project/screens/affirmation.dart';
import 'package:health_project/screens/search.dart';
import 'package:health_project/screens/privacy.dart';
import 'package:health_project/screens/contact_us.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  bool _isDarkMode = false;

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  void toggleTheme(bool isDark) {
    setState(() => _isDarkMode = isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ministry of Health',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('si'),
        Locale('ta'),
      ],
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomePage(),
        '/on_boarding': (context) => const OnBoardingScreen(),
        '/login_page': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot_password': (context) => const ForgetPage(),
        '/home_page': (context) => HomePage(
              onLocaleChange: setLocale,
              locale: _locale,
              onThemeChanged: toggleTheme,
              isDarkMode: _isDarkMode,
            ),
        '/edit_profile': (context) => const EditProfilePage(
              userName: '',
              userEmail: '',
              userImage: '',
            ),
        '/about_us': (context) => AboutUsPage(),
        '/notifications': (context) => NotificationsPage(),
        '/logout': (context) => const LogoutPage(),
        '/affirmation': (context) => const AffirmationPage(),
        '/search': (context) => const SearchPage(),
        '/privacy': (context) => PrivacyPage(),
        '/contact_us': (context) => ContactUs()
      },
    );
  }
  
  ContactUs() {}
}
