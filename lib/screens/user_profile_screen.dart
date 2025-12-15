// lib/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/chat_screen.dart'; // Import ChatScreen to message them

class UserProfileScreen extends StatelessWidget {
  final String targetUid;
  final String userName; // Passed for the AppBar title immediately

  const UserProfileScreen({
    super.key,
    required this.targetUid,
    this.userName = "Profile"
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isMe = currentUid == targetUid;

    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(targetUid).snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error/No Data State
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          // 3. Data Loaded
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'Student';
          String picUrl = data['profilePicUrl'] ?? '';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER SECTION (Color + Image) ---
                Container(
                  color: Colors.indigo,
                  padding: const EdgeInsets.only(bottom: 30, top: 10),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: picUrl.isNotEmpty ? NetworkImage(picUrl) : null,
                          child: picUrl.isEmpty
                              ? Text((data['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 40))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        data['name'] ?? 'No Name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- ACTION BUTTONS ---
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // Go to Chat
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ChatScreen(
                                friendUid: targetUid,
                                friendName: data['name'] ?? 'User'
                            ))
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text("Send Message"),
                    ),
                  ),

                // --- INFO CARDS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Bio
                      if ((data['bio'] ?? '').isNotEmpty)
                        _buildInfoCard(Icons.info, "About", data['bio']),

                      // Department
                      _buildInfoCard(Icons.school, "Department", data['department'] ?? 'Not set'),

                      // Role Specific Details
                      if (role == 'Student' && (data['intake'] ?? '').isNotEmpty)
                        _buildInfoCard(Icons.calendar_today, "Intake", "Batch ${data['intake']}"),

                      if (role == 'Faculty Member' && (data['designation'] ?? '').isNotEmpty)
                        _buildInfoCard(Icons.work, "Designation", data['designation']),

                      // Email
                      _buildInfoCard(Icons.email, "Email", data['email'] ?? 'Hidden'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    );
  }
}