import 'package:flutter/material.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  // Simulated data (replace this with your actual data source)
  final Map<String, Map<String, String>> mockDatabase = {
    'H-PE-0001': {
      'name': 'ඩබ්.ප්‍රශානි තාරිකා මිය',
      'nic': '945061685V',
      'designation': 'Health Technical Officer (Junior)',
      'station': 'Base Hospital - Kiribathgoda',
      'letterDate': '2025-01-15',
    },
    'H-PE-0002': {
      'name': 'පී.එස්.චන්ද්‍රලතා ප්‍රනාන්ද්‍ු මිය',
      'nic': '795650458V',
      'designation': 'Health Technical Officer (Junior)',
      'station': 'Base Hospital - Panadura',
      'letterDate': '2025-01-20',
    },
    // Add more from your PDF if needed
  };

  Map<String, String>? result;

  void searchById(String id) {
    setState(() {
      result = mockDatabase[id];
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.searchBySerialNumber),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: searchById,
              decoration: InputDecoration(
                labelText: loc.enterNICNumber,
                hintText: "e.g., 945061685V",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            if (result != null)
              Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(result!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(loc.designation + ": ${result!['designation']}"),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: Text("${loc.nicNumber}: ${result!['nic']}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.local_hospital),
                        title: Text("${loc.serviceStation}: ${result!['station']}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: Text("${loc.letterDate}: ${result!['letterDate']}"),
                      ),
                    ],
                  ),
                ),
              )
            else if (searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  loc.noResultsFound,
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
