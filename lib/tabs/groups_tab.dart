// lib/tabs/groups_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/create_group_screen.dart'; // Faculty Create Screen
import 'package:studify/screens/group_chat_screen.dart';   // Chat Interface
import 'package:studify/screens/request_club_screen.dart'; // Student Request Screen
import 'package:studify/services/group_service.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final GroupService _groupService = GroupService();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // 1. Listen to User Role
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());

        var userData = userSnap.data!.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'Student';

        // --- ADMIN VIEW: Club Requests Inbox ---
        if (role == 'Admin') {
          return Scaffold(
            appBar: AppBar(title: const Text("Club Requests"), centerTitle: true),
            body: _buildAdminRequestsList(),
          );
        }

        // --- USER VIEW (Student/Faculty): My Groups ---
        return Scaffold(
          appBar: AppBar(title: const Text("My Groups"), centerTitle: true),
          body: _buildUserGroupsList(),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.white,
            icon: Icon(role == 'Faculty Member' ? Icons.add : Icons.forward_to_inbox),
            label: Text(role == 'Faculty Member' ? "Create Group" : "Request Club"),
            onPressed: () {
              if (role == 'Faculty Member') {
                // Faculty -> Create Directly
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
              } else {
                // Student -> Request Form
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestClubScreen()));
              }
            },
          ),
        );
      },
    );
  }

  // --- WIDGET: List of Groups (For Users) ---
  Widget _buildUserGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupService.getUserGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text("You haven't joined any groups yet.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String groupId = snapshot.data!.docs[index].id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: const Icon(Icons.groups, color: Colors.indigo),
                ),
                title: Text(data['name'] ?? 'Group', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "${data['recentSender']}: ${data['recentMessage']}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => GroupChatScreen(groupId: groupId, groupName: data['name'] ?? 'Group')
                  ));
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET: Admin Request Inbox ---
  Widget _buildAdminRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupService.getClubRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text("No pending club requests.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String reqId = doc.id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    title: Text(data['groupName'] ?? 'Club Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Requested by: ${data['requesterName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Reason: ${data['description']}"),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  ButtonBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _groupService.rejectClubRequest(reqId),
                        child: const Text("Reject", style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _groupService.approveClubRequest(reqId, data['groupName'], data['requesterUid']),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Approve & Create"),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}