// lib/screens/friend_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/user_profile_screen.dart';
import 'package:studify/services/friend_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  String _searchText = "";
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoadingSearch = false;

  void _onSearchChanged(String val) async {
    setState(() {
      _searchText = val.trim();
    });

    if (_searchText.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoadingSearch = true);
    var results = await _friendService.searchUsers(_searchText);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find & Manage Friends")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. INCOMING REQUESTS
            _buildIncomingRequests(),

            const Divider(thickness: 10, color: Colors.black12),

            // 2. SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search name to add friends...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // 3. SEARCH RESULTS OR SUGGESTIONS
            _searchText.isNotEmpty
                ? _buildSearchResults()
                : _buildVerticalSuggestions(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 1: Incoming Requests ---
  Widget _buildIncomingRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).collection('friend_requests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Hide if empty
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text("Friend Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                String senderUid = snapshot.data!.docs[index].id;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(senderUid).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox();
                    var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (userData['profilePicUrl'] ?? '').isNotEmpty ? NetworkImage(userData['profilePicUrl']) : null,
                        child: (userData['profilePicUrl'] ?? '').isEmpty ? Text((userData['name']??'U')[0]) : null,
                      ),
                      title: Text(userData['name'] ?? 'Unknown'),
                      subtitle: const Text("Sent you a request"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                            onPressed: () => _friendService.acceptFriendRequest(senderUid),
                            child: const Text("Accept"),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => _friendService.rejectFriendRequest(senderUid),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET 2: Search Results ---
  Widget _buildSearchResults() {
    if (_isLoadingSearch) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No users found.")));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var doc = _searchResults[index];
        return _buildUserTile(doc, isSearchResult: true);
      },
    );
  }

  // --- WIDGET 3: Vertical Suggestions (When not searching) ---
  Widget _buildVerticalSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8),
          child: Text("People You May Know", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        FutureBuilder<List<DocumentSnapshot>>(
          future: _friendService.getSuggestedFriends(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("No new suggestions."));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return _buildUserTile(snapshot.data![index]);
              },
            );
          },
        ),
      ],
    );
  }

  // Helper to build a user row
  Widget _buildUserTile(DocumentSnapshot doc, {bool isSearchResult = false}) {
    var data = doc.data() as Map<String, dynamic>;
    String uid = doc.id;

    // Check if I already sent a request (UI optimization)
    return FutureBuilder<List>(
      future: _friendService.getSentRequestsIds(),
      builder: (context, snapshot) {
        bool alreadySent = false;
        if (snapshot.hasData) {
          alreadySent = snapshot.data!.contains(uid);
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (data['profilePicUrl'] ?? '').isNotEmpty ? NetworkImage(data['profilePicUrl']) : null,
            child: (data['profilePicUrl'] ?? '').isEmpty ? Text((data['name']??'U')[0]) : null,
          ),
          title: Text(data['name'] ?? 'Unknown'),
          subtitle: Text(data['department'] ?? 'Student'),
          trailing: alreadySent
              ? TextButton(onPressed: null, child: Text("Pending", style: TextStyle(color: Colors.grey)))
              : ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo, side: const BorderSide(color: Colors.indigo)),
            onPressed: () async {
              await _friendService.sendFriendRequest(uid);
              setState(() {
                if (!isSearchResult) {
                  // If it's a suggestion, hide it after adding
                }
              });
            },
            child: const Text("Add"),
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(targetUid: uid, userName: data['name'])));
          },
        );
      },
    );
  }
}