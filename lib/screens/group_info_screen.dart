// lib/screens/group_info_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:studify/widgets/avatar_from_profile.dart'; // Ensure this exists

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  // Cloudinary for Group Icons
  final cloudinary = CloudinaryPublic('dpwh49fxd', 'z1rvuhsd', cache: false);
  bool _isUploading = false;

  // --- 1. UPLOAD GROUP ICON ---
  Future<void> _pickAndUploadGroupIcon() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
          folder: "group_icons/${widget.groupId}",
        ),
      );

      // Update Firestore
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'iconUrl': response.secureUrl,
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group icon updated!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- 2. EDIT NAME & BIO ---
  void _showEditDialog(String currentName, String currentBio) {
    TextEditingController nameCtrl = TextEditingController(text: currentName);
    TextEditingController bioCtrl = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Group Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Group Name")),
            TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: "Group Bio (Description)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
                'groupName': nameCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- 3. REMOVE MEMBER ---
  void _removeMember(String memberUid, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Are you sure you want to remove $memberName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
                'members': FieldValue.arrayRemove([memberUid])
              });
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Group Info")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var groupData = snapshot.data!.data() as Map<String, dynamic>;
          String groupName = groupData['groupName'] ?? 'Group';
          String iconUrl = groupData['iconUrl'] ?? '';
          String bio = groupData['bio'] ?? 'No description available.';
          String adminId = groupData['adminId'] ?? '';
          List members = groupData['members'] ?? [];

          bool isAdmin = (widget.currentUserId == adminId);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- A. GROUP ICON ---
                GestureDetector(
                  onTap: isAdmin ? _pickAndUploadGroupIcon : null,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.indigo,
                        backgroundImage: iconUrl.isNotEmpty ? NetworkImage(iconUrl) : null,
                        child: iconUrl.isEmpty
                            ? Text(groupName[0].toUpperCase(), style: const TextStyle(fontSize: 50, color: Colors.white))
                            : null,
                      ),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.indigo, size: 20),
                        ),
                    ],
                  ),
                ),
                if (_isUploading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),

                const SizedBox(height: 15),

                // --- B. NAME & BIO ---
                Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),

                if (isAdmin)
                  TextButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Info"),
                    onPressed: () => _showEditDialog(groupName, bio),
                  ),

                const Divider(thickness: 10, color: Colors.black12),

                // --- C. MEMBERS LIST ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Members (${members.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    String uid = members[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox();
                        var user = userSnap.data!.data() as Map<String, dynamic>;
                        String name = user['name'] ?? 'Unknown';

                        bool isThisUserAdmin = (uid == adminId);

                        return ListTile(
                          leading: AvatarFromProfile(uid: uid, fallbackLabel: name),
                          title: Text(name),
                          subtitle: isThisUserAdmin
                              ? const Text("Admin", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))
                              : Text(user['department'] ?? ''),
                          trailing: (isAdmin && !isThisUserAdmin)
                              ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeMember(uid, name),
                          )
                              : null,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }
}