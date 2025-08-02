import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
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
import 'package:health_project/screens/verified_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class RouteNames {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const onBoarding = '/on_boarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot_password';
  static const home = '/home';
  static const editProfile = '/edit_profile';
  static const aboutUs = '/about_us';
  static const notifications = '/notifications';
  static const logout = '/logout';
  static const affirmation = '/affirmation';
  static const search = '/search';
  static const privacy = '/privacy';
  static const contactUs = '/contact_us';
  static const verified = '/verified';
}

Future<void> handleEmailLinkAuth() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
  final Uri? deepLink = data?.link;

  if (deepLink != null && auth.isSignInWithEmailLink(deepLink.toString())) {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('emailForSignIn');

    if (email != null) {
      try {
        await auth.signInWithEmailLink(
          email: email, 
          emailLink: deepLink.toString()
        );
        prefs.remove('emailForSignIn');
        navigatorKey.currentState?.pushReplacementNamed(RouteNames.home);
      } catch (e) {
        debugPrint('Email link sign-in failed: $e');
      }
    } else {
      debugPrint('No saved email found for sign-in link.');
    }
  }
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await handleEmailLinkAuth();
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() => _isDarkMode = isDark);
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (navigatorKey.currentState?.mounted ?? false) {
        navigatorKey.currentState?.pushReplacementNamed(RouteNames.home);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (navigatorKey.currentState?.mounted ?? false) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(content: Text('Google Sign-In Failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ministry of Health',
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(_isDarkMode),
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
      routes: _buildAppRoutes(),
    );
  }

  ThemeData _buildThemeData(bool isDark) {
    return isDark
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.blue[800],
            colorScheme: ColorScheme.dark(
              primary: Colors.blue[800]!,
              secondary: Colors.blue[200]!,
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.grey[900],
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.lightBlue,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.white,
            ),
          );
  }

  Map<String, WidgetBuilder> _buildAppRoutes() {
    return {
      RouteNames.splash: (context) => const SplashScreen(),
      RouteNames.welcome: (context) => const WelcomePage(),
      RouteNames.onBoarding: (context) => const OnBoardingScreen(),
      RouteNames.login: (context) => LoginPage(
            onThemeChanged: toggleTheme,
            isDarkMode: _isDarkMode,
            onGoogleSignIn: signInWithGoogle,
          ),
      RouteNames.signup: (context) => SignUpPage(
            onThemeChanged: toggleTheme,
            isDarkMode: _isDarkMode,
          ),
      RouteNames.verified: (context) => const VerifiedScreen(),
      RouteNames.forgotPassword: (context) => const ForgetPasswordPage(),
      RouteNames.home: (context) => HomePage(
            onLocaleChange: setLocale,
            locale: _locale,
            onThemeChanged: toggleTheme,
            isDarkMode: _isDarkMode,
          ),
      RouteNames.editProfile: (context) => EditProfilePage(
            userName: '',
            userEmail: '',
            userImage: '',
          ),
      RouteNames.aboutUs: (context) => const AboutUsPage(),
      RouteNames.notifications: (context) => const NotificationsPage(),
      RouteNames.logout: (context) => const LogoutPage(),
      RouteNames.affirmation: (context) => const AffirmationPage(),
      RouteNames.search: (context) => const SearchPage(),
      RouteNames.privacy: (context) => PrivacyPage(),
      RouteNames.contactUs: (context) => const ContactUsPage(),
    };
  }
}