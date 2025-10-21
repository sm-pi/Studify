import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileTab({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 34, child: Text(profile['name'][0])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile['name'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(profile['id'],
                            style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 6),
                        Text(profile['university'],
                            style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  ElevatedButton(onPressed: () {}, child: const Text("Edit"))
                ],
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(profile['description']),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(profile['email']),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text("Activity",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                        leading: Icon(Icons.post_add),
                        title: Text("Posted new notes in Feed")),
                    ListTile(
                        leading: Icon(Icons.group),
                        title: Text("Joined AI Club")),
                    ListTile(
                        leading: Icon(Icons.star),
                        title: Text("Completed Flutter Workshop")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}