import 'package:flutter/material.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';
import '../widgets/language_switcher.dart';

class HomeScreen extends StatelessWidget {
  final void Function(Locale) onLocaleChange;
  final Locale locale;

  const HomeScreen({
    super.key,
    required this.onLocaleChange,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) return const SizedBox(); // Handle null safety

    return Scaffold(
      appBar: AppBar(
        title: Text(t.ministryName ?? ''), // <-- Use fallback or !
        actions: [
          LanguageSwitcher(
            onLocaleChange: onLocaleChange,
            locale: locale,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(t.news ?? '', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            Text(t.services ?? '', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone),
              label: Text(t.emergency ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: t.home ?? ''),
          BottomNavigationBarItem(icon: const Icon(Icons.article), label: t.news ?? ''),
          BottomNavigationBarItem(icon: const Icon(Icons.local_hospital), label: t.services ?? ''),
          BottomNavigationBarItem(icon: const Icon(Icons.phone), label: t.emergency ?? ''),
          BottomNavigationBarItem(icon: const Icon(Icons.more_horiz), label: t.settings ?? ''),
        ],
      ),
    );
  }
}
