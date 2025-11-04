import 'package:flutter/material.dart';

class FriendsTab extends StatelessWidget {
  final List<Map<String, dynamic>> friends;

  const FriendsTab({required this.friends, super.key});

  @override
  Widget build(BuildContext context) {
    final faculty = friends.where((f) => f['type'] == 'Faculty').toList();
    final students = friends.where((f) => f['type'] == 'Student').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 8),
            const Text("Suggestions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...students
                .map((s) => ConnectionTile(
                name: s['name'], subtitle: "${s['mutual']} mutual friends"))
                ,
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text("Faculty",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...faculty
                .map((f) => ConnectionTile(name: f['name'], subtitle: f['type']))
                ,
          ],
        ),
      ),
    );
  }
}

class ConnectionTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const ConnectionTile({required this.name, required this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(child: Text(name[0])),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text("Request"),
        ),
      ),
    );
  }
}