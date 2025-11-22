// lib/services/menu_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/database_services.dart';
import 'package:studify/services/storage_service.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // --- ANNOUNCEMENTS ---

  Future<void> createAnnouncement(String title, String content) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Verify user is Faculty
    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc['role'] != 'Faculty Member') {
      throw Exception("Only faculty can post announcements.");
    }

    await _db.collection('announcements').add({
      'title': title,
      'content': content,
      'authorName': userDoc['name'],
      'authorUid': user.uid,
      'date': DateTime.now().toString().substring(0, 10), // e.g. 2025-11-21
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- RESOURCES (PDFs) ---

  Future<void> uploadResource({
    required String title,
    required String courseCode, // e.g. "CSE-101" (Links to Group)
    required File pdfFile,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Verify user is Faculty
    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc['role'] != 'Faculty Member') {
      throw Exception("Only faculty can upload resources.");
    }

    // 1. Upload PDF to Cloudinary
    String pdfUrl = await _storageService.uploadFile(pdfFile);

    // 2. Save metadata to Firestore
    await _db.collection('resources').add({
      'title': title,
      'courseCode': courseCode,
      'url': pdfUrl,
      'type': 'pdf',
      'authorName': userDoc['name'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}