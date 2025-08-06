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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> searchById(String id) async {
    try {
      final querySnapshot = await _firestore
          .collection('affirmations')
          .where('nic', isEqualTo: id)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
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
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.getYourInformation,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.enterNICNumber,
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchField(isDark, loc),
              const SizedBox(height: 20),
              _buildResultsSection(isDark, loc),
              const SizedBox(height: 20),
              _buildSearchButton(loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark, AppLocalizations loc) {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: searchById,
      decoration: InputDecoration(
        labelText: loc.enterNICNumber,
        hintText: "e.g., 945061685V",
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black45),
      ),
    );
  }

  Widget _buildResultsSection(bool isDark, AppLocalizations loc) {
    if (result != null) {
      return Card(
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
      );
    } else if (searchController.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 72, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              loc.noResultsFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.pleaseCheckNIC, // <- Add this key in localization
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

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
