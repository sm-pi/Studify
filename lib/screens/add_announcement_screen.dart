// lib/screens/add_announcement_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:studify/services/menu_service.dart';
import 'package:studify/services/storage_service.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final MenuService _menuService = MenuService();
  final StorageService _storageService = StorageService();

  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    // Pick an image specifically
    var result = await _storageService.pickPostAttachment(true);
    if (result != null) {
      setState(() {
        _selectedImage = result['file'];
      });
    }
  }

  Future<void> _postAnnouncement() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title and Content are required")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _menuService.addAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageFile: _selectedImage,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to post announcement")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Announcement")),
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
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Content", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Image Picker Button
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Attach Image (Optional)"),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Image Attached: ${_selectedImage!.path.split('/').last}", style: const TextStyle(color: Colors.green)),
                ),

              const SizedBox(height: 24),
              if (_isUploading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _postAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("POST ANNOUNCEMENT"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}