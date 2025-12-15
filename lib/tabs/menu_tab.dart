// lib/tabs/menu_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/add_announcement_screen.dart';
// Removed: upload_resource_screen.dart
// Removed: view_pdf_screen.dart

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- CLEAR NOTIFICATIONS LOGIC ---
  Future<void> _clearAllNotifications() async {
    if (currentUser == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Clear Notifications"),
            content: const Text(
                "Are you sure you want to delete all notifications?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                      "Clear All", style: TextStyle(color: Colors.red))),
            ],
          ),
    ) ?? false;

    if (!confirm) return;

    var collection = FirebaseFirestore.instance.collection('users').doc(
        currentUser!.uid).collection('notifications');
    var snapshots = await collection.get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifications cleared")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Notifications Section
            _buildSectionHeader(
                "Notifications",
                null,
                showClearButton: true
            ),
            _buildNotificationList(),

            // 2. Announcements Section (ADMIN ONLY ADD BUTTON)
            _buildAnnouncementsSection(),

            // --- RESOURCES SECTION REMOVED ---

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- NEW: Announcements Logic with Admin Check ---
  Widget _buildAnnouncementsSection() {
    return StreamBuilder<DocumentSnapshot>(
      // 1. Check User Role (Admin?)
      stream: FirebaseFirestore.instance.collection('users').doc(
          currentUser!.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isAdmin = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          // Check if the role matches exactly 'Admin'
          isAdmin = userData['role'] == 'Admin';
        }

        return Column(
          children: [
            // Header: Show "Add" button ONLY if Admin
            _buildSectionHeader(
                "Announcements",
                isAdmin
                    ? () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AddAnnouncementScreen()));
                }
                    : null
            ),

            // The List of Announcements (Visible to everyone)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No announcements yet."));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      color: Colors.indigo[50],
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                                Icons.campaign, color: Colors.indigo),
                            title: Text(data['title'] ?? 'Announcement'),
                            subtitle: Text(
                                "Posted by ${data['authorName']} on ${data['date'] ??
                                    ''}", style: TextStyle(
                                fontSize: 12, color: Colors.grey[700])),
                          ),
                          if (data['content'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(data['content'],
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            ),
                          if (data['imageUrl'] != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    data['imageUrl'], height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover),
                              ),
                            ),
                          const SizedBox(height: 8),
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

  // --- Notification List Builder ---
  Widget _buildNotificationList() {
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No new notifications.", style: TextStyle(
                color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 1,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  radius: 16,
                  child: Icon(
                      Icons.notifications, size: 16, color: Colors.white),
                ),
                title: Text(data['title'] ?? 'Notification',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(
                    data['body'] ?? '', style: const TextStyle(fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAddPressed,
      {bool showClearButton = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          Row(
            children: [
              if (showClearButton)
                TextButton(
                  onPressed: _clearAllNotifications,
                  child: const Text("Clear All",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              if (onAddPressed != null)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.indigo),
                  onPressed: onAddPressed,
                ),
            ],
          )
        ],
      ),
    );
  }
}