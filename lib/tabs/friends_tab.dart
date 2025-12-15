// lib/tabs/friends_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/chat_screen.dart';
import 'package:studify/screens/friend_requests_screen.dart';
import 'package:studify/screens/user_profile_screen.dart';
import 'package:studify/services/friend_service.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends & Network"),
        centerTitle: true,
        actions: [
          // Go to Friend Requests
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const FriendRequestsScreen()
              ));
            },
          )
        ],
        // --- SEARCH BAR ADDED HERE ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for anyone...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      // --- DYNAMIC BODY SWITCHING ---
      body: _searchText.isNotEmpty
          ? _buildSearchResults() // Show Search Results
          : _buildDefaultView(),  // Show Suggestions + My Friends
    );
  }

  // --- VIEW 1: DEFAULT (Suggestions + Friends) ---
  Widget _buildDefaultView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CIRCULAR HEADER: Suggestions (Department Based)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 5),
            child: Text("People You May Know", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 5),
            child: Text("Suggestions from your Department", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
    );
  }

  // --- VIEW 2: SEARCH RESULTS ---
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      // Simple search: get all users (for prototypes) or use logic to filter
      // For production with many users, use Algolia/ElasticSearch.
      // Here we grab users and filter locally for simplicity.
      stream: FirebaseFirestore.instance.collection('users').limit(50).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var allDocs = snapshot.data!.docs;
        // Filter locally by name
        var filteredDocs = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? '').toLowerCase();
          return name.contains(_searchText.toLowerCase()) && doc.id != currentUid;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("No user found."));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var data = filteredDocs[index].data() as Map<String, dynamic>;
            String uid = filteredDocs[index].id;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (data['profilePicUrl'] ?? '').isNotEmpty
                    ? NetworkImage(data['profilePicUrl'])
                    : null,
                child: (data['profilePicUrl'] ?? '').isEmpty ? Text((data['name']??'U')[0]) : null,
              ),
              title: Text(data['name'] ?? 'Unknown'),
              subtitle: Text(data['department'] ?? 'Student'),
              trailing: IconButton(
                icon: const Icon(Icons.person_add, color: Colors.indigo),
                onPressed: () async {
                  await _friendService.sendFriendRequest(uid);
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent!")));
                },
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => UserProfileScreen(targetUid: uid, userName: data['name'])
                ));
              },
            );
          },
        );
      },
    );
  }

  // --- COMPONENT: My Friends List ---
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
            child: Text("No friends yet. Search above to add people!"),
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

  // --- COMPONENT: Circular Suggestions (Logic updated to force Department check) ---
  Widget _buildCircularSuggestions() {
    return FutureBuilder<DocumentSnapshot>(
      // 1. Get MY data first to know my department
      future: FirebaseFirestore.instance.collection('users').doc(currentUid).get(),
      builder: (context, mySnap) {
        if (!mySnap.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

        var myData = mySnap.data!.data() as Map<String, dynamic>;
        String myDept = myData['department'] ?? '';
        List myFriends = myData['friend_uids'] ?? [];

        // 2. Query users with SAME department
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where('department', isEqualTo: myDept)
              .limit(20)
              .get(),
          builder: (context, suggestionsSnap) {
            if (suggestionsSnap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }

            var docs = suggestionsSnap.data?.docs ?? [];

            // 3. Filter out myself and existing friends
            var validSuggestions = docs.where((doc) {
              String uid = doc.id;
              return uid != currentUid && !myFriends.contains(uid);
            }).toList();

            if (validSuggestions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No new suggestions in your department.", style: TextStyle(color: Colors.grey)),
              );
            }

            return Container(
              height: 140,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: validSuggestions.length,
                itemBuilder: (context, index) {
                  var doc = validSuggestions[index];
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
                              setState(() {});
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
      },
    );
  }
}