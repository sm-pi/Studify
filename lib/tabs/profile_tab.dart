// lib/tabs/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/auth_service.dart';
import 'package:studify/screens/login_screen.dart';
import 'package:studify/screens/edit_profile_screen.dart';

class ProfileTab extends StatelessWidget {
  ProfileTab({super.key});

  final User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("No user logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  // FIX 1: Removed 'const' here
                    builder: (context) => EditProfileScreen()
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    // FIX 2: Removed 'const' here (just in case)
                      builder: (context) => LoginScreen()
                  ),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("User profile not found."));

          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
          String role = userData['role'] ?? 'Not set';
          String profilePicUrl = userData['profilePicUrl'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.indigo.shade100,
                      backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
                      child: profilePicUrl.isEmpty
                          ? Text((userData['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['name'] ?? 'No Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(userData['email'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),

                _buildInfoCard("About Me", (userData['bio'] ?? '').isEmpty ? "Please update your bio." : userData['bio']),

                if (role == 'Student')
                  _buildStudentCard(userData)
                else if (role == 'Faculty Member')
                  _buildFacultyCard(userData)
                else
                  _buildCompleteProfileCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> userData) {
    String department = userData['department'] ?? 'Not set';
    String intake = userData['intake'] ?? 'Not set';
    return _buildInfoCard("Student Info", "Department: $department\nIntake: $intake");
  }

  Widget _buildFacultyCard(Map<String, dynamic> userData) {
    String department = userData['department'] ?? 'Not set';
    String designation = userData['designation'] ?? 'Not set';
    return _buildInfoCard("Faculty Info", "Department: $department\nDesignation: $designation");
  }

  Widget _buildCompleteProfileCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.indigo, size: 30),
            SizedBox(height: 10),
            Text("Please complete your profile", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
      ),
    );
  }
}