import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/storage_service.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Updated: Handles generic file attachment (Image OR PDF)
  Future<void> addAnnouncement({
    required String title,
    required String content,
    File? file,
    String? fileType, // 'image' or 'pdf'
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String? attachmentUrl;
    String? attachmentName;

    if (file != null && fileType != null) {
      // Upload file based on type
      attachmentUrl = await _storageService.uploadFile(file, fileType);
      attachmentName = file.path.split('/').last;
    }

    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Admin';

    DateTime now = DateTime.now();
    String dateStr = "${now.day}/${now.month}/${now.year}";

    await _db.collection('announcements').add({
      'title': title,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'attachmentType': fileType, // 'image' or 'pdf'
      'attachmentName': attachmentName,
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