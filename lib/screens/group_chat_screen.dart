// lib/screens/group_chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String adminId; // The UID of the person who created the group

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.adminId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  bool _isUploading = false;

  // --- THE GOLDEN RULE: Are you the creator of this group? ---
  bool get _isAdmin => currentUid == widget.adminId;

  // Replace with your actual Cloudinary credentials
  final cloudinary = CloudinaryPublic('dpwh49fxd', 'z1rvuhsd', cache: false);

  // --- 1. UPLOAD LOGIC (ADMIN ONLY) ---
  Future<String?> _uploadFile(File file, String folder) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Auto,
          folder: "group_files/${widget.groupId}/$folder",
        ),
      );
      return response.secureUrl;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      return null;
    }
  }

  void _pickAndSend(String type) async {
    if (!_isAdmin) return; // Safety check

    setState(() => _isUploading = true);
    String? url;

    try {
      if (type == 'image') {
        final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image != null) url = await _uploadFile(File(image.path), 'images');
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
        if (result != null) url = await _uploadFile(File(result.files.single.path!), 'pdfs');
      }

      if (url != null && mounted) {
        _sendMessage(msg: "Sent a ${type == 'image' ? 'photo' : 'PDF'}", type: type, fileUrl: url);
      }
    } catch (e) {
      print(e);
    }

    if (mounted) setState(() => _isUploading = false);
  }

  // --- 2. SEND MESSAGE (ADMIN ONLY) ---
  void _sendMessage({required String msg, String type = 'text', String? fileUrl}) async {
    if (msg.trim().isEmpty && fileUrl == null) return;

    Map<String, dynamic> chatData = {
      'senderId': currentUid,
      'senderName': FirebaseAuth.instance.currentUser!.displayName ?? 'Admin',
      'message': msg,
      'type': type,
      'fileUrl': fileUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add(chatData);

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'recentMessage': type == 'text' ? msg : 'Sent a file',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- 3. DOWNLOAD LOGIC (EVERYONE) ---
  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Permission Check
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) await Permission.storage.request();
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading...")));

      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory(); // Saves to Android/data/com.yourapp/files/
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        String savePath = "${dir.path}/$fileName";
        await Dio().download(url, savePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Saved to: $savePath"), backgroundColor: Colors.green, duration: const Duration(seconds: 4)),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Download Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName),
            Text(
              _isAdmin ? "You are the Admin" : "Member View",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        // ACTIONS REMOVED: No add member button here anymore
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildMessageTile(docs[index]),
                );
              },
            ),
          ),

          if (_isUploading) const LinearProgressIndicator(),

          // CONTROL BAR: Admin gets Inputs, Members get "Read Only" text
          _isAdmin ? _buildAdminInputArea() : _buildReadOnlyMessage(),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildAdminInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: () {
                showModalBottomSheet(context: context, builder: (_) {
                  return Wrap(
                    children: [
                      ListTile(leading: const Icon(Icons.image), title: const Text('Image'), onTap: () { Navigator.pop(context); _pickAndSend('image'); }),
                      ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('PDF Document'), onTap: () { Navigator.pop(context); _pickAndSend('pdf'); }),
                    ],
                  );
                });
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Post an update...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.indigo,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(msg: _messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[200],
      width: double.infinity,
      child: const Text(
        "Only the Group Admin can post here.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildMessageTile(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMe = data['senderId'] == currentUid;
    String type = data['type'] ?? 'text';
    String? fileUrl = data['fileUrl'];

    // Unique filename for downloading
    String fileName = "file_${doc.id}.${type == 'image' ? 'jpg' : 'pdf'}";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.indigo[100] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              Text(data['senderName'] ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.indigo)),
              const SizedBox(height: 4),
            ],

            if (type == 'text')
              Text(data['message'], style: const TextStyle(fontSize: 15)),

            if (type == 'image' && fileUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(fileUrl))),
                    child: Image.network(fileUrl, height: 150, width: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () => _downloadFile(fileUrl, fileName),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 4),
                        Text("Download Image", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

            if (type == 'pdf' && fileUrl != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Document (PDF)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          InkWell(
                            onTap: () => _downloadFile(fileUrl, fileName),
                            child: const Text("Tap to Download", style: TextStyle(color: Colors.blue, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}