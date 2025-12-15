// lib/screens/create_group_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// We don't need GroupService for creation anymore to ensure exact field naming
// import 'package:studify/services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  List<String> _selectedFriendUids = [];
  bool _isLoading = false;

  void _createGroup() async {
    String groupName = _nameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a group name")));
      return;
    }
    // Commented out: You might want to allow creating a group with just yourself initially?
    // if (_selectedFriendUids.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least 1 student")));
    //   return;
    // }

    setState(() => _isLoading = true);

    try {
      // --- FIX STARTS HERE ---
      // We write directly to Firestore to ensure the key is named 'adminId'
      // This matches exactly what your GroupChatScreen is looking for.

      // 1. Create the list of members (Selected friends + YOU)
      List<String> allMembers = [..._selectedFriendUids, currentUid];

      // 2. Add to Firestore
      await FirebaseFirestore.instance.collection('groups').add({
        'groupName': groupName,
        'adminId': currentUid,        // <--- CRITICAL FIX: Named exactly 'adminId'
        'members': allMembers,        // You are included as a member automatically
        'recentMessage': 'Group created',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'createdBy': 'Faculty',       // Optional: helps if you want to filter later
      });
      // --- FIX ENDS HERE ---

      if (mounted) {
        Navigator.pop(context); // Close screen on success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Group")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createGroup,
        backgroundColor: Colors.indigo, // Changed to indigo for better visibility
        label: _isLoading ? const Text("Creating...") : const Text("Create Group", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.check, color: Colors.white),
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