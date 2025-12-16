// lib/tabs/groups_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/create_group_screen.dart';
import 'package:studify/screens/group_chat_screen.dart';
import 'package:studify/screens/request_club_screen.dart';
import 'package:studify/services/group_service.dart';
import 'package:studify/widgets/avatar_from_profile.dart';

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
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var userData = userSnap.data!.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'Student';
        String myDept = userData['department'] ?? '';

        if (role == 'Admin') {
          return Scaffold(
            appBar: AppBar(title: const Text("Club Requests"), centerTitle: true),
            body: _buildAdminRequestsList(),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text("My Groups"), centerTitle: true),
          body: _buildUserGroupsList(myDept),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            icon: Icon(role == 'Faculty Member' ? Icons.add : Icons.forward_to_inbox),
            label: Text(role == 'Faculty Member' ? "Create Group" : "Request Club"),
            onPressed: () {
              if (role == 'Faculty Member') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestClubScreen()));
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildUserGroupsList(String myDept) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: currentUid)
          .orderBy('lastTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text("No groups yet.", style: TextStyle(color: Colors.grey)),
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

            String groupName = data['groupName'] ?? data['name'] ?? 'Unnamed Group';
            String adminId = data['adminId'] ?? '';
            String recentMsg = data['recentMessage'] ?? 'No messages yet';
            String iconUrl = data['iconUrl'] ?? ''; // <--- NEW: GET ICON URL
            List<dynamic> members = data['members'] ?? [];

            bool iAmAdmin = (currentUid == adminId);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              elevation: 2,
              child: ListTile(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => GroupChatScreen(
                        groupId: doc.id,
                        groupName: groupName,
                        adminId: adminId,
                      )
                  ));
                },
                // --- SHOW GROUP ICON ---
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo,
                  backgroundImage: iconUrl.isNotEmpty ? NetworkImage(iconUrl) : null,
                  child: iconUrl.isEmpty
                      ? Text(groupName.isNotEmpty ? groupName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
                title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(recentMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'members') _showMembersDialog(context, members);
                    else if (value == 'add_member') _showAddMemberDialog(context, doc.id, myDept, members);
                    else if (value == 'delete') _confirmDeleteGroup(context, doc.id, groupName);
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(value: 'members', child: Row(children: [Icon(Icons.people, color: Colors.grey), SizedBox(width: 8), Text("View Members")])),
                      if (iAmAdmin) const PopupMenuItem(value: 'add_member', child: Row(children: [Icon(Icons.person_add, color: Colors.indigo), SizedBox(width: 8), Text("Add Member")])),
                      if (iAmAdmin) const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Delete Group", style: TextStyle(color: Colors.red))])),
                    ];
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- REUSED HELPER DIALOGS (Same as before, simplified for brevity) ---
  void _showAddMemberDialog(BuildContext context, String groupId, String myDept, List existingMembers) {
    TextEditingController searchController = TextEditingController();
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Add Member"),
          content: SizedBox(width: double.maxFinite, height: 400, child: Column(children: [
            TextField(controller: searchController, decoration: const InputDecoration(labelText: "Search Name", prefixIcon: Icon(Icons.search)), onChanged: (val) => setState((){})),
            const SizedBox(height: 10),
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('department', isEqualTo: myDept).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                String query = searchController.text.trim().toLowerCase();
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return (data['name']??'').toLowerCase().contains(query) && !existingMembers.contains(doc.id);
                }).toList();
                if (filteredDocs.isEmpty) return const Center(child: Text("No users found"));
                return ListView.builder(itemCount: filteredDocs.length, itemBuilder: (context, index) {
                  var data = filteredDocs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: AvatarFromProfile(uid: filteredDocs[index].id, fallbackLabel: data['name']??'U'),
                    title: Text(data['name']??'Unknown'),
                    trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.indigo), onPressed: () async {
                      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({'members': FieldValue.arrayUnion([filteredDocs[index].id])});
                      if(context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${data['name']} added!"))); }
                    }),
                  );
                });
              },
            )),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
        );
      });
    });
  }

  void _showMembersDialog(BuildContext context, List<dynamic> memberUids) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(title: Text("Members (${memberUids.length})"), content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(
        shrinkWrap: true, itemCount: memberUids.length, itemBuilder: (context, index) {
        String uid = memberUids[index];
        return FutureBuilder<DocumentSnapshot>(future: FirebaseFirestore.instance.collection('users').doc(uid).get(), builder: (context, snapshot) {
          if (!snapshot.hasData) return const ListTile(title: Text("Loading..."));
          var user = snapshot.data!.data() as Map<String, dynamic>?;
          return ListTile(
            leading: AvatarFromProfile(uid: uid, fallbackLabel: user?['name']??'?'),
            title: Text(user?['name'] ?? 'Unknown'),
            subtitle: uid == currentUid ? const Text("(You)", style: TextStyle(color: Colors.indigo)) : null,
          );
        });
      },
      )), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))]);
    });
  }

  void _confirmDeleteGroup(BuildContext context, String groupId, String groupName) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Delete Group?"), content: Text("Delete '$groupName'?"), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {
        await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
        if (context.mounted) Navigator.pop(context);
      }, child: const Text("Delete", style: TextStyle(color: Colors.white))),
    ]));
  }

  Widget _buildAdminRequestsList() {
    return StreamBuilder<QuerySnapshot>(stream: _groupService.getClubRequests(), builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No requests."));
      return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
        var doc = snapshot.data!.docs[index];
        var data = doc.data() as Map<String, dynamic>;
        return Card(child: ListTile(title: Text(data['groupName']), subtitle: Text("By: ${data['requesterName']}"), trailing: ElevatedButton(onPressed: () => _groupService.approveClubRequest(doc.id, data['groupName'], data['requesterUid']), child: const Text("Approve"))));
      });
    });
  }
}