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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100], // Background color for dark/light mode
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Text(
              'Get Your Information Here',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

            // Instructions Section
            Text(
              'Please Enter Your NIC Number',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 20),

            // Search Input Field
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: searchById,
              decoration: InputDecoration(
                labelText: loc.enterNICNumber, // Updated label
                hintText: "e.g., 945061685V", // NIC number hint
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Results Section
            if (result != null)
              Card(
                elevation: 8,
                color: isDark ? Colors.grey[850] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.blueAccent),
                        title: Text(
                          result!['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text("${loc.designation}: ${result!['designation']}"),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.badge, color: Colors.blueAccent),
                        title: Text("${loc.nicNumber}: ${result!['nic']}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.local_hospital, color: Colors.blueAccent),
                        title: Text("${loc.serviceStation}: ${result!['station']}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.date_range, color: Colors.blueAccent),
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

            // Submit Button (Search Button)
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (searchController.text.isNotEmpty) {
                    searchById(searchController.text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
