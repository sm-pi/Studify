import 'package:flutter/material.dart';
import 'package:studify/screens/home_screen.dart';
import 'package:studify/widgets/custom_button.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> allSuggestions = [
    {"name": "Ibrahim", "mutual": 12},
    {"name": "Meherin", "mutual": 8},
    {"name": "Jahid Hossain", "mutual": 5},
    {"name": "Shanta", "mutual": 3},
    {"name": "Rafi", "mutual": 4},
    {"name": "Anika", "mutual": 2},
  ];

  List<Map<String, dynamic>> filtered = [];
  final Set<String> added = {};

  @override
  void initState() {
    super.initState();
    filtered = List.from(allSuggestions);
  }

  void onSearch(String q) {
    setState(() {
      filtered = allSuggestions
          .where((f) => f['name'].toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  void toggleAdd(String name) {
    setState(() {
      if (added.contains(name)) {
        added.remove(name);
      } else {
        added.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Friends"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: "Search for friends",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    final name = friend['name'] as String;
                    final mutual = friend['mutual'] as int;
                    final isAdded = added.contains(name);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(name[0]),
                        ),
                        title: Text(name,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$mutual mutual friends"),
                        trailing: ElevatedButton(
                          onPressed: () => toggleAdd(name),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                              isAdded ? Colors.white70 : Colors.white),
                          child: Text(isAdded ? "Added" : "Add"),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: "Continue",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}