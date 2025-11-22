// lib/screens/add_announcement_screen.dart

import 'package:flutter/material.dart';
import 'package:studify/services/menu_service.dart';
import 'package:studify/widgets/custom_text_field.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final MenuService _menuService = MenuService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  void _postAnnouncement() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _menuService.createAnnouncement(
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Announcement")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(hintText: "Title (e.g., Midterm Rescheduled)", controller: _titleController),
            const SizedBox(height: 16),
            CustomTextField(hintText: "Details...", controller: _contentController, maxLines: 5),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _postAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Post Announcement"),
            )
          ],
        ),
      ),
    );
  }
}