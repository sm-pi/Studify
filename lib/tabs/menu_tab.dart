// lib/tabs/menu_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/add_announcement_screen.dart';
import 'package:studify/screens/upload_resource_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuTab extends StatelessWidget {
  MenuTab({super.key});

  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  // --- NEW: Logic to Clear Notifications ---
  Future<void> _clearAllNotifications(BuildContext context) async {
    if (currentUser == null) return;

    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Notifications"),
        content: const Text("Are you sure you want to delete all notifications?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Delete documents in a batch
    var collection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('notifications');

    var snapshots = await collection.get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notifications cleared")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Notifications Section
            _buildSectionHeader(
                context,
                "Notifications",
                null,
                showClearButton: true // <-- Enable Clear Button
            ),
            _buildNotificationList(),

            // 2. Announcements Section
            _buildFirestoreSection(
              context: context,
              title: "Announcements",
              collection: "announcements",
              icon: Icons.campaign,
              isResource: false,
            ),

            // 3. Resources Section
            _buildFirestoreSection(
              context: context,
              title: "Resources",
              collection: "resources",
              icon: Icons.description,
              isResource: true,
            ),
          ],
        ),
      ),
    );
  }

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "No new notifications.",
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
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
                  child: Icon(Icons.notifications, size: 16, color: Colors.white),
                ),
                title: Text(data['title'] ?? 'Notification', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(data['body'] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: data['isRead'] == false
                    ? const Icon(Icons.circle, color: Colors.red, size: 10)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFirestoreSection({
    required BuildContext context,
    required String title,
    required String collection,
    required IconData icon,
    required bool isResource,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isFaculty = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          isFaculty = userData['role'] == 'Faculty Member';
        }

        return Column(
          children: [
            _buildSectionHeader(
                context,
                title,
                isFaculty
                    ? () {
                  if (isResource) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadResourceScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAnnouncementScreen()));
                  }
                }
                    : null
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(collection).orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text("No $title yet."));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    if (isResource) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf, color: Colors.red[700]),
                          title: Text(data['title'] ?? 'Untitled'),
                          subtitle: Text("${data['courseCode']} • by ${data['authorName']}"),
                          trailing: const Icon(Icons.download),
                          onTap: () => _launchUrl(data['url']),
                        ),
                      );
                    } else {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: Colors.indigo[50],
                        child: ListTile(
                          leading: Icon(icon, color: Colors.indigo),
                          title: Text(data['title'] ?? 'Announcement'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text("Posted by ${data['authorName']} on ${data['date']}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // --- UPDATED HEADER: Accepts 'showClearButton' ---
  Widget _buildSectionHeader(
      BuildContext context,
      String title,
      VoidCallback? onAddPressed,
      {bool showClearButton = false} // Optional Parameter
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          Row(
            children: [
              // CLEAR BUTTON (Visible only if showClearButton is true)
              if (showClearButton)
                TextButton(
                  onPressed: () => _clearAllNotifications(context),
                  child: const Text("Clear All", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              // ADD BUTTON
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