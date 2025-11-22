// lib/tabs/friends_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/chat_screen.dart';
import 'package:studify/screens/find_friends_screen.dart';
import 'package:studify/screens/friend_requests_screen.dart';
import 'package:studify/services/friend_service.dart';
import 'package:studify/services/chat_service.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendRequestsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindFriendsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuggestionsSection(),
            const Divider(thickness: 1, height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Your Friends", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ),
            _buildFriendsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _friendService.getSuggestedFriends(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text("People You May Know", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var userDoc = snapshot.data![index];
                  var userData = userDoc.data() as Map<String, dynamic>;
                  String uid = userDoc.id;

                  return Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: (userData['profilePicUrl'] ?? '').isNotEmpty ? NetworkImage(userData['profilePicUrl']) : null,
                            child: (userData['profilePicUrl'] ?? '').isEmpty ? Text((userData['name'] ?? 'U')[0]) : null,
                          ),
                          const SizedBox(height: 8),
                          Text(userData['name'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 30), padding: EdgeInsets.zero, backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                            onPressed: () async {
                              await _friendService.sendFriendRequest(uid);
                              setState(() => snapshot.data!.removeAt(index));
                            },
                            child: const Text("Add", style: TextStyle(fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        List friendUids = userData['friend_uids'] ?? [];

        if (friendUids.isEmpty) return const Padding(padding: EdgeInsets.all(30.0), child: Center(child: Text("No friends yet.")));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friendUids.length,
          itemBuilder: (context, index) {
            String friendUid = friendUids[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
              builder: (context, friendSnap) {
                if (!friendSnap.hasData) return const SizedBox.shrink();
                var friendData = friendSnap.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (friendData['profilePicUrl'] ?? '').isNotEmpty ? NetworkImage(friendData['profilePicUrl']) : null,
                    child: (friendData['profilePicUrl'] ?? '').isEmpty ? Text((friendData['name'] ?? 'U')[0]) : null,
                  ),
                  title: Text(friendData['name'] ?? 'Unknown'),
                  subtitle: Text(friendData['department'] ?? ''),

                  // --- RED DOT LOGIC ---
                  trailing: StreamBuilder<int>(
                      stream: _chatService.getUnreadCountStream(friendUid),
                      builder: (context, countSnap) {
                        int unreadCount = countSnap.data ?? 0;

                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.indigo),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(friendUid: friendUid, friendName: friendData['name'] ?? 'Friend')));
                              },
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                  child: Text("$unreadCount", style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                                ),
                              ),
                          ],
                        );
                      }
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}