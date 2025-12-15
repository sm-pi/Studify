// lib/screens/request_club_screen.dart

import 'package:flutter/material.dart';
import 'package:studify/services/group_service.dart';

class RequestClubScreen extends StatefulWidget {
  const RequestClubScreen({super.key});

  @override
  State<RequestClubScreen> createState() => _RequestClubScreenState();
}

class _RequestClubScreenState extends State<RequestClubScreen> {
  final _groupNameController = TextEditingController();
  final _descController = TextEditingController();
  final GroupService _groupService = GroupService();
  bool _isLoading = false;

  void _submitRequest() async {
    if (_groupNameController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    // Send request to Admin
    await _groupService.requestClubCreation(
        _groupNameController.text.trim(),
        _descController.text.trim()
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent to Admin!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Club")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Propose a new Club or Study Group to the Admin. If approved, you will become the group admin.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Club / Group Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Purpose / Description",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SUBMIT REQUEST"),
            ),
          ],
        ),
      ),
    );
  }
}