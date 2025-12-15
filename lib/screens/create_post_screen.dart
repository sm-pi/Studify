// lib/screens/create_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/storage_service.dart'; // Ensure this is imported

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final StorageService _storageService = StorageService();

  File? _selectedFile;
  String? _fileName;
  String? _fileType; // 'image' or 'pdf'
  bool _isUploading = false;

  // --- 1. PICK FILE ---
  Future<void> _pickFile(bool isImage) async {
    var result = await _storageService.pickPostAttachment(isImage);
    if (result != null) {
      setState(() {
        _selectedFile = result['file'];
        _fileName = result['fileName'];
        _fileType = result['fileType']; // Store the type ('image' or 'pdf')
      });
    }
  }

  // --- 2. UPLOAD & POST ---
  Future<void> _createPost() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title and Text are required")));
      return;
    }

    setState(() => _isUploading = true);

    String? attachmentUrl;

    // Fix: Pass both file AND fileType to the uploader
    if (_selectedFile != null && _fileType != null) {
      attachmentUrl = await _storageService.uploadFile(_selectedFile!, _fileType!);
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get user name to save with post (optional but good for performance)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String authorName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

      await FirebaseFirestore.instance.collection('posts').add({
        'authorUid': user.uid,
        'authorName': authorName,
        'title': _titleController.text.trim(),
        'textContent': _textController.text.trim(),
        'attachmentUrl': attachmentUrl,
        'attachmentType': _fileType, // Save type to DB so Feed knows how to display it
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
      });
    }

    setState(() => _isUploading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: "What's on your mind?", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Attachment Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickFile(true), // Pick Image
                    icon: const Icon(Icons.image),
                    label: const Text("Image"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _pickFile(false), // Pick PDF
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF"),
                  ),
                ],
              ),

              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Attached: $_fileName ($_fileType)", style: const TextStyle(color: Colors.green)),
                ),

              const SizedBox(height: 24),

              if (_isUploading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("POST"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}