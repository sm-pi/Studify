import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/add_announcement_screen.dart';
import 'package:studify/screens/view_pdf_screen.dart';
import 'package:studify/services/menu_service.dart'; // <--- IMPORT SERVICE

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final MenuService _menuService = MenuService(); // <--- Init Service

  // --- HELPERS: Open Viewers ---
  void _openPDF(BuildContext context, String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewPdfScreen(pdfUrl: url, title: fileName),
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: Image.network(url)),
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC: Delete Announcement (Admin Only) ---
  Future<void> _confirmDeleteAnnouncement(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Announcement"),
        content: const Text("Are you sure you want to remove this announcement permanently?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _menuService.deleteAnnouncement(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement deleted")),
        );
      }
    }
  }

  // --- LOGIC: Clear Notifications ---
  Future<void> _clearAllNotifications() async {
    if (currentUser == null) return;
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Notifications"),
        content: const Text("Delete all notifications?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Clear", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    var collection = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('notifications');
    var snapshots = await collection.get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. NOTIFICATION BAR
            _buildSectionHeader("Notifications", null, showClearButton: true),
            _buildNotificationBar(),

            // 2. ANNOUNCEMENTS (Admins see Add & Delete)
            _buildAnnouncementsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBar() {
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 60,
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12)
            ),
            child: const Text("No new notifications.", style: TextStyle(color: Colors.grey)),
          );
        }

        var docs = snapshot.data!.docs;

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, size: 16, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Notification',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['body'] ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
      builder: (context, userSnapshot) {
        // 1. Determine if User is Admin
        bool isAdmin = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          isAdmin = userData['role'] == 'Admin';
        }

        return Column(
          children: [
            // Header: Show "Add" only if Admin
            _buildSectionHeader("Announcements", isAdmin ? () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAnnouncementScreen()));
            } : null),

            // List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("No announcements yet."));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id; // <--- Get Doc ID
                    String? type = data['attachmentType'];
                    String? url = data['attachmentUrl'];
                    String? name = data['attachmentName'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- HEADER (Title + Delete Button) ---
                            Row(
                              children: [
                                const Icon(Icons.campaign, color: Colors.orange, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['title'] ?? 'Announcement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text("Posted: ${data['date']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                // ADMIN DELETE BUTTON
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _confirmDeleteAnnouncement(docId),
                                  ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Content
                            if (data['content'] != null)
                              Text(data['content'], style: const TextStyle(fontSize: 14)),

                            const SizedBox(height: 10),

                            // --- ATTACHMENT DISPLAY ---
                            // 1. PDF
                            if (type == 'pdf' && url != null)
                              InkWell(
                                onTap: () => _openPDF(context, url, name ?? 'Announcement PDF'),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(name ?? "Attached Document.pdf",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                      const Text("OPEN", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),

                            // 2. IMAGE
                            if (type == 'image' && url != null)
                              GestureDetector(
                                onTap: () => _openImage(context, url),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  height: 150,
                                  width: double.infinity,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(url, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                          ],
                        ),
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

  Widget _buildSectionHeader(String title, VoidCallback? onAddPressed, {bool showClearButton = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          Row(
            children: [
              if (showClearButton)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.grey),
                  onPressed: _clearAllNotifications,
                  tooltip: "Clear All",
                ),
              if (onAddPressed != null)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
                  onPressed: onAddPressed,
                  tooltip: "Add Announcement",
                ),
            ],
          )
        ],
      ),
    );
  }
}