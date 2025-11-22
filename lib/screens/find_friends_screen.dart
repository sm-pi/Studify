// lib/screens/find_friends_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/friend_service.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final FriendService _friendService = FriendService();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Friends")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          // --- FIX START: SAFER WAY TO FIND MY DOC ---
          // Instead of firstWhere with orElse, we filter the list
          var myDocs = docs.where((d) => d.id == currentUid).toList();

          // Prepare empty lists by default
          List myFriends = [];
          List mySentRequests = [];

          // If we found my document, read the real data
          if (myDocs.isNotEmpty) {
            Map<String, dynamic> myData = myDocs.first.data() as Map<String, dynamic>;
            myFriends = myData['friend_uids'] ?? [];
            mySentRequests = myData['sent_requests_uids'] ?? [];
          }
          // --- FIX END ---

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var user = docs[index].data() as Map<String, dynamic>;
              String uid = docs[index].id;

              // Don't show myself
              if (uid == currentUid) return const SizedBox.shrink();

              // Check status
              bool isFriend = myFriends.contains(uid);
              bool isRequested = mySentRequests.contains(uid);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (user['profilePicUrl'] ?? '').isNotEmpty
                      ? NetworkImage(user['profilePicUrl'])
                      : null,
                  child: (user['profilePicUrl'] ?? '').isEmpty
                      ? Text((user['name'] ?? 'U')[0])
                      : null,
                ),
                title: Text(user['name'] ?? 'Unknown'),
                subtitle: Text(user['department'] ?? 'Student'),

                // Show the correct button based on status
                trailing: isFriend
                    ? const Icon(Icons.check, color: Colors.green) // Already Friends
                    : isRequested
                    ? TextButton( // Already Requested
                  onPressed: null,
                  child: Text("Requested", style: TextStyle(color: Colors.grey[600])),
                )
                    : ElevatedButton( // Can Add
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await _friendService.sendFriendRequest(uid);
                  },
                  child: const Text("Add"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}