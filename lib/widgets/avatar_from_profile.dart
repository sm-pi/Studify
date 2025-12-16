import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarFromProfile extends StatelessWidget {
  final String uid;
  final double radius;
  final String fallbackLabel; // Usually the user's name

  const AvatarFromProfile({
    super.key,
    required this.uid,
    this.radius = 20,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    // If no UID is provided, show fallback immediately
    if (uid.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Text(
          fallbackLabel.isNotEmpty ? fallbackLabel[0].toUpperCase() : '?',
          style: TextStyle(fontSize: radius, color: Colors.black54),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        // Default / Loading State
        String? profilePicUrl;
        String displayName = fallbackLabel;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          profilePicUrl = data['profilePicUrl'];
          // We can also fetch the latest name if we want, but fallbackLabel is usually fine
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.indigo.shade100,
          backgroundImage: (profilePicUrl != null && profilePicUrl.isNotEmpty)
              ? NetworkImage(profilePicUrl)
              : null,
          child: (profilePicUrl == null || profilePicUrl.isEmpty)
              ? Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: radius,
              color: Colors.indigo,
            ),
          )
              : null,
        );
      },
    );
  }
}