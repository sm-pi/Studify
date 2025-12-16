import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/storage_service.dart';

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
    // If a file is already selected, clear it first to avoid confusion
    if (_selectedFile != null) {
      setState(() {
        _selectedFile = null;
        _fileName = null;
        _fileType = null;
      });
    }

    var result = await _storageService.pickPostAttachment(isImage);
    if (result != null) {
      setState(() {
        _selectedFile = result['file'];
        _fileName = result['fileName'];
        _fileType = result['fileType'];
      });
    }
  }

  // --- 2. REMOVE FILE ---
  void _removeAttachment() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileType = null;
    });
  }

  // --- 3. UPLOAD & POST ---
  Future<void> _createPost() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title and Text are required")));
      return;
    }

    setState(() => _isUploading = true);

    String? attachmentUrl;

    // Upload File if selected
    if (_selectedFile != null && _fileType != null) {
      attachmentUrl = await _storageService.uploadFile(_selectedFile!, _fileType!);
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String authorName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

      await FirebaseFirestore.instance.collection('posts').add({
        'authorUid': user.uid,
        'authorName': authorName,
        'title': _titleController.text.trim(),
        'textContent': _textController.text.trim(),
        'attachmentUrl': attachmentUrl,
        'attachmentType': _fileType,
        'attachmentFileName': _fileName, // <--- SAVED FILENAME HERE
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'commentCount': 0, // Initialize count
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
              // Title Input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Text Content Input
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "What's on your mind?",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Attachment Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _pickFile(true),
                    icon: const Icon(Icons.image),
                    label: const Text("Add Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _pickFile(false),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Add PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- ATTACHMENT PREVIEW SECTION ---
              if (_selectedFile != null) ...[
                const Text("Attachment Preview:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _fileType == 'image'
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedFile!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                          : ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                        title: Text(_fileName ?? "Document.pdf"),
                        subtitle: const Text("PDF Document"),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    ),
                    // Remove Button (X)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: _removeAttachment,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Post Button
              if (_isUploading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("POST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}