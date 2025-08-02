import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  Map<String, String>? result;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> searchById(String id) async {
    try {
      // Search for a document with the given NIC number in the Firestore collection 'affirmations'
      final querySnapshot = await _firestore
          .collection('affirmations')
          .where('nic', isEqualTo: id)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Fetch the first document that matches
        var data = querySnapshot.docs[0].data();
        setState(() {
          result = {
            'name': data['name'] ?? 'N/A',
            'nic': data['nic'] ?? 'N/A',
            'designation': data['designation'] ?? 'N/A',
            'station': data['station'] ?? 'N/A',
            'letterDate': data['letterDate'] ?? 'N/A',
          };
        });
      } else {
        setState(() {
          result = null;
        });
      }
    } catch (e) {
      print("Error searching NIC: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100], // Background color for dark/light mode
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(  // Ensures that if there's a lot of content, it scrolls
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Text(
                loc.getYourInformation, // Using localized text
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              // Instructions Section
              Text(
                loc.enterNICNumber, // Using localized text
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 20),

              // Search Input Field
              _buildSearchField(isDark, loc),

              const SizedBox(height: 20),

              // Results Section
              _buildResultsSection(isDark, loc),

              // Submit Button (Search Button)
              const SizedBox(height: 20),
              _buildSearchButton(loc),
            ],
          ),
        ),
      ),
    );
  }

  // This method will build the search field with a modern look
  Widget _buildSearchField(bool isDark, AppLocalizations loc) {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: searchById,
      decoration: InputDecoration(
        labelText: loc.enterNICNumber, // Localized label
        hintText: "e.g., 945061685V", // NIC number hint
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),  // Rounded corners
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black45),
      ),
    );
  }

  // This method builds the result card when information is found
  Widget _buildResultsSection(bool isDark, AppLocalizations loc) {
    return result != null
        ? Card(
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
        : Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              loc.noResultsFound, // Localized "no results" message
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          );
  }

  // This method builds the search button with enhanced styling
  Widget _buildSearchButton(AppLocalizations loc) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(
          loc.search ?? 'Search',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          shadowColor: Colors.blueAccent.withOpacity(0.5),
        ),
        onPressed: () {
          if (searchController.text.isNotEmpty) {
            searchById(searchController.text);
          }
        },
      ),
    );
  }
}
