// lib/screens/upload_resource_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:studify/services/menu_service.dart';
import 'package:studify/services/storage_service.dart'; // reusing the picker
import 'package:studify/widgets/custom_text_field.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final MenuService _menuService = MenuService();
  final StorageService _storageService = StorageService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();

  File? _selectedPdf;
  String? _pdfName;
  bool _isLoading = false;

  Future<void> _pickPdf() async {
    // Reusing your existing storage service helper, or calling picker directly
    // Since we want PDF ONLY:
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedPdf = File(result.files.single.path!);
          _pdfName = result.files.single.name;
        });
      }
    } catch (e) {
      print("Picker error: $e");
    }
  }

  void _upload() async {
    if (_selectedPdf == null || _titleController.text.isEmpty || _courseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields and pick a PDF.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _menuService.uploadResource(
        title: _titleController.text.trim(),
        courseCode: _courseController.text.trim(),
        pdfFile: _selectedPdf!,
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
      appBar: AppBar(title: const Text("Upload Resource")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(hintText: "Resource Title (e.g. Lecture 1 Slides)", controller: _titleController),
            const SizedBox(height: 16),
            CustomTextField(hintText: "Course Code (e.g. CSE-303)", controller: _courseController),
            const SizedBox(height: 16),

            // PDF Picker Button
            OutlinedButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label: Text(_pdfName ?? "Select PDF File"),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Upload Resource"),
            )
          ],
        ),
      ),
    );
  }
}