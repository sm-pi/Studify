import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Ensure file_picker is in pubspec.yaml
import 'package:studify/services/menu_service.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final MenuService _menuService = MenuService();

  File? _selectedFile;
  String? _fileType; // 'image' or 'pdf'
  bool _isUploading = false;

  // Generic Picker (Images or PDFs)
  Future<void> _pickFile(FileType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: type == FileType.custom ? ['pdf'] : null,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType = type == FileType.image ? 'image' : 'pdf';
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Colors.indigo),
            title: const Text("Attach Image"),
            onTap: () {
              Navigator.pop(context);
              _pickFile(FileType.image);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text("Attach PDF"),
            onTap: () {
              Navigator.pop(context);
              _pickFile(FileType.custom); // Custom triggers PDF only via extension above
            },
          ),
        ],
      ),
    );
  }

  Future<void> _postAnnouncement() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Title and Content are required")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _menuService.addAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        file: _selectedFile,
        fileType: _fileType,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to post announcement")));
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
                decoration: const InputDecoration(
                    labelText: "Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: "Content", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Attachment Area
              if (_selectedFile == null)
                OutlinedButton.icon(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Attach File (Image or PDF)"),
                )
              else
                Card(
                  color: Colors.grey[100],
                  child: ListTile(
                    leading: Icon(
                      _fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                      color: _fileType == 'pdf' ? Colors.red : Colors.indigo,
                    ),
                    title: Text(_selectedFile!.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                          _fileType = null;
                        });
                      },
                    ),
                  ),
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