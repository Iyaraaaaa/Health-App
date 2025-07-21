import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';
import 'package:health_project/screens/forgot_password.dart';

import 'screens/landing_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/forget_password.dart';  
import 'screens/home_screen.dart';

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

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ministry of Health',
      debugShowCheckedModeBanner: false,
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
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(onLocaleChange: setLocale, locale: _locale),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot_password': (context) => const ForgetPage(),  // <-- Use ForgetPage here
        '/home': (context) => HomeScreen(onLocaleChange: setLocale, locale: _locale),
      },
    );
  }
}
