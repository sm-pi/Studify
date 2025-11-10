// lib/screens/create_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:studify/services/post_service.dart';
import 'package:studify/services/storage_service.dart';
import 'package:studify/widgets/custom_text_field.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService(); // For uploading

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;

  // --- NEW STATE FOR ATTACHMENTS ---
  File? _pickedFile;
  String? _pickedFileName;
  String? _pickedFileType;
  // -----------------------------------

  Future<void> _pickAttachment(bool pickImage) async {
    Map<String, dynamic>? result =
    await _storageService.pickPostAttachment(pickImage);

    if (result != null) {
      setState(() {
        _pickedFile = result['file'];
        _pickedFileName = result['fileName'];
        _pickedFileType = result['fileType'];
      });
    }
  }

  void _clearAttachment() {
    setState(() {
      _pickedFile = null;
      _pickedFileName = null;
      _pickedFileType = null;
    });
  }

  void _submitPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? attachmentUrl;

      // 1. Upload file if one is picked
      if (_pickedFile != null) {
        attachmentUrl = await _storageService.uploadFile(_pickedFile!);
      }

      // 2. Create the post in Firestore
      await _postService.createPost(
        title: _titleController.text.trim(),
        textContent: _postController.text.trim(),
        attachmentUrl: attachmentUrl,
        attachmentFileName: _pickedFileName,
        attachmentType: _pickedFileType,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Error creating post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text("Post"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- NEW TITLE FIELD ---
            CustomTextField(
              controller: _titleController,
              hintText: "Post Title",
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 16),

            // --- TEXT CONTENT FIELD ---
            CustomTextField(
              controller: _postController,
              hintText: "What's on your mind? (Optional)",
              maxLines: 8,
            ),
            const SizedBox(height: 16),

            // --- NEW ATTACHMENT BUTTONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickAttachment(true), // Pick Image
                  icon: const Icon(Icons.image),
                  label: const Text("Image"),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickAttachment(false), // Pick PDF
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("PDF"),
                ),
              ],
            ),

            // --- NEW: SHOWS THE PICKED FILE ---
            if (_pickedFileName != null)
              Chip(
                label: Text(_pickedFileName!),
                avatar: Icon(
                  _pickedFileType == 'image' ? Icons.image : Icons.picture_as_pdf,
                ),
                onDeleted: _clearAttachment,
              ),
          ],
        ),
      ),
    );
  }
}