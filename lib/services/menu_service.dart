// lib/services/menu_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/storage_service.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Add Announcement (Image optional)
  Future<void> addAnnouncement({
    required String title,
    required String content,
    File? imageFile,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _storageService.uploadFile(imageFile, 'image');
    }

    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Admin';

    DateTime now = DateTime.now();
    String dateStr = "${now.day}/${now.month}/${now.year}";

    await _db.collection('announcements').add({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'authorUid': user.uid,
      'authorName': userName,
      'date': dateStr,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(String docId) async {
    await _db.collection('announcements').doc(docId).delete();
  }
}