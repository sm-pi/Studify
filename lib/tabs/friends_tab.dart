// lib/tabs/friends_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/chat_screen.dart';
import 'package:studify/screens/friend_requests_screen.dart'; // <--- UPDATED IMPORT
import 'package:studify/screens/user_profile_screen.dart';
import 'package:studify/services/friend_service.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final FriendService _friendService = FriendService();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        centerTitle: true,
        actions: [
          // TOP RIGHT ICON: Goes to Requests & Search Page
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const FriendRequestsScreen()
              ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CIRCULAR HEADER: Suggestions
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 5),
              child: Text("People You May Know", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 5),
              child: Text("Department Suggestions", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            _buildCircularSuggestions(),

            const Divider(thickness: 1),

            // 2. MY FRIENDS LIST
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Text("My Friends", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            _buildMyFriendsList(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 1: My Friends (Vertical List) ---
  Widget _buildMyFriendsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var myData = snapshot.data!.data() as Map<String, dynamic>;
        List friendUids = myData['friend_uids'] ?? [];

        if (friendUids.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("No friends yet. Add people using the icon above!"),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friendUids.length,
          itemBuilder: (context, index) {
            String friendUid = friendUids[index];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (userData['profilePicUrl'] ?? '').isNotEmpty
                          ? NetworkImage(userData['profilePicUrl'])
                          : null,
                      child: (userData['profilePicUrl'] ?? '').isEmpty ? Text((userData['name']??'U')[0]) : null,
                    ),
                    title: Text(userData['name'] ?? 'Unknown'),
                    subtitle: Text(userData['department'] ?? 'Student'),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble, color: Colors.indigo),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(friendUid: friendUid, friendName: userData['name'])
                        ));
                      },
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => UserProfileScreen(targetUid: friendUid, userName: userData['name'])
                      ));
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- WIDGET 2: Circular Suggestions (Horizontal) ---
  Widget _buildCircularSuggestions() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _friendService.getSuggestedFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No new suggestions.", style: TextStyle(color: Colors.grey)),
          );
        }

        return Container(
          height: 140,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data![index];
              var data = doc.data() as Map<String, dynamic>;
              String uid = doc.id;

              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => UserProfileScreen(targetUid: uid, userName: data['name'])
                        ));
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.indigo.shade100,
                        backgroundImage: (data['profilePicUrl'] ?? '').isNotEmpty
                            ? NetworkImage(data['profilePicUrl'])
                            : null,
                        child: (data['profilePicUrl'] ?? '').isEmpty ? Text((data['name']??'U')[0]) : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (data['name'] ?? 'User').split(" ")[0],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 30,
                      child: IconButton(
                        icon: const Icon(Icons.person_add_alt_1, size: 20, color: Colors.indigo),
                        onPressed: () async {
                          await _friendService.sendFriendRequest(uid);
                          setState(() {}); // Refresh to hide
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent!")));
                        },
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}