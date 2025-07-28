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

class RouteNames {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const onBoarding = '/on_boarding';
  static const login = '/login_page';
  static const signup = '/signup';
  static const forgotPassword = '/forgot_password';
  static const home = '/home_page';
  static const editProfile = '/edit_profile';
  static const aboutUs = '/about_us';
  static const notifications = '/notifications';
  static const logout = '/logout';
  static const affirmation = '/affirmation';
  static const search = '/search';
  static const privacy = '/privacy';
  static const contactUs = '/contact_us';
}

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
      initialRoute: RouteNames.splash,
      routes: {
        RouteNames.splash: (context) => const SplashScreen(),
        RouteNames.welcome: (context) => const WelcomePage(),
        RouteNames.onBoarding: (context) => const OnBoardingScreen(),
        RouteNames.login: (context) => const LoginPage(),
        RouteNames.signup: (context) => const SignupPage(),
        RouteNames.forgotPassword: (context) => const ForgetPage(),
        RouteNames.home: (context) => HomePage(
              onLocaleChange: setLocale,
              locale: _locale,
              onThemeChanged: toggleTheme,
              isDarkMode: _isDarkMode,
            ),
        RouteNames.editProfile: (context) => const EditProfilePage(
              userName: '',
              userEmail: '',
              userImage: '',
            ),
        RouteNames.aboutUs: (context) => AboutUsPage(),
        RouteNames.notifications: (context) => NotificationsPage(),
        RouteNames.logout: (context) => const LogoutPage(),
        RouteNames.affirmation: (context) => AffirmationPage(), // Ensure it's being used as a Widget here
        RouteNames.search: (context) => const SearchPage(),
        RouteNames.privacy: (context) => PrivacyPage(),
        RouteNames.contactUs: (context) => const ContactUsPage(),
      },
    );
  }

}