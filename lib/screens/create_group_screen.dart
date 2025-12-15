// lib/screens/create_group_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GroupService _groupService = GroupService();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  List<String> _selectedFriendUids = [];
  bool _isLoading = false;

  void _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a group name")));
      return;
    }
    if (_selectedFriendUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least 1 student")));
      return;
    }

    setState(() => _isLoading = true);

    // Create the group immediately (Faculty privilege)
    await _groupService.createGroup(_nameController.text.trim(), _selectedFriendUids);

    if (mounted) {
      Navigator.pop(context); // Close screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Group")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createGroup,
        backgroundColor: Colors.white,
        label: _isLoading ? const Text("Creating...") : const Text("Create Group"),
        icon: const Icon(Icons.check),
      ),
      body: Column(
        children: [
          // 1. Group Name Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Select Students from your Network", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),

          // 2. Friends List (with Checkboxes)
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var userDoc = snapshot.data!.data() as Map<String, dynamic>;
                List friendUids = userDoc['friend_uids'] ?? [];

                if (friendUids.isEmpty) return const Center(child: Text("You need to add students to your network first!"));

                return ListView.builder(
                  itemCount: friendUids.length,
                  itemBuilder: (context, index) {
                    String friendUid = friendUids[index];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
                      builder: (context, friendSnap) {
                        if (!friendSnap.hasData) return const SizedBox.shrink();
                        var data = friendSnap.data!.data() as Map<String, dynamic>;

                        bool isSelected = _selectedFriendUids.contains(friendUid);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: Colors.indigo,
                          title: Text(data['name'] ?? 'Unknown'),
                          subtitle: Text(data['department'] ?? ''),
                          secondary: CircleAvatar(
                            backgroundImage: (data['profilePicUrl'] ?? '').isNotEmpty
                                ? NetworkImage(data['profilePicUrl'])
                                : null,
                            child: (data['profilePicUrl'] ?? '').isEmpty ? Text((data['name']??'U')[0]) : null,
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedFriendUids.add(friendUid);
                              } else {
                                _selectedFriendUids.remove(friendUid);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}