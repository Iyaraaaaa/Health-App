import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _items = [
    'Motivation',
    'Mindfulness',
    'Productivity',
    'Gratitude',
    'Well-being',
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items
        .where((item) =>
            item.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (text) {
                setState(() {
                  _searchText = text;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search topics...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (_, index) {
                  return ListTile(
                    title: Text(filteredItems[index]),
                    leading: const Icon(Icons.bubble_chart),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
