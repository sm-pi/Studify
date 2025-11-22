// lib/screens/friend_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/friend_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FriendService _friendService = FriendService();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to MY friend_requests subcollection
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('friend_requests')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No pending requests",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          var requestDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requestDocs.length,
            itemBuilder: (context, index) {
              // The ID of the document IS the uid of the person who sent the request
              String senderUid = requestDocs[index].id;

              // Fetch their profile details to show name/pic
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(senderUid).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String name = userData['name'] ?? 'Unknown';
                  String dept = userData['department'] ?? '';
                  String pic = userData['profilePicUrl'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                        child: pic.isEmpty ? Text(name[0]) : null,
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(dept),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // REJECT BUTTON
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await _friendService.rejectFriendRequest(senderUid);
                            },
                          ),
                          const SizedBox(width: 8),
                          // ACCEPT BUTTON
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () async {
                              await _friendService.acceptFriendRequest(senderUid);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("You are now friends with $name!")),
                                );
                              }
                            },
                            child: const Text("Accept"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}