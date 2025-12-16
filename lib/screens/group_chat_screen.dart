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
import 'package:studify/widgets/avatar_from_profile.dart';
import 'package:studify/screens/group_info_screen.dart'; // <--- IMPORT THIS

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String adminId;

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

  bool get _isAdmin => currentUid == widget.adminId;

  final cloudinary = CloudinaryPublic('dpwh49fxd', 'z1rvuhsd', cache: false);

  // --- UPLOAD LOGIC ---
  Future<String?> _uploadFile(File file, String folder) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Auto, folder: "group_files/${widget.groupId}/$folder"),
      );
      return response.secureUrl;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      return null;
    }
  }

  void _pickAndSend(String type) async {
    if (!_isAdmin) return;
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
    } catch (e) { print(e); }
    if (mounted) setState(() => _isUploading = false);
  }

  // --- SEND MESSAGE ---
  void _sendMessage({required String msg, String type = 'text', String? fileUrl}) async {
    if (msg.trim().isEmpty && fileUrl == null) return;
    User? user = FirebaseAuth.instance.currentUser;
    String senderName = user?.displayName ?? 'Admin';

    Map<String, dynamic> chatData = {
      'senderId': currentUid,
      'senderName': senderName,
      'message': msg,
      'type': type,
      'fileUrl': fileUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
    _messageController.clear();
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('messages').add(chatData);
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'recentMessage': type == 'text' ? msg : 'Sent a file',
      'recentSender': senderName,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) await Permission.storage.request();
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading...")));
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      if (dir != null) {
        String savePath = "${dir.path}/$fileName";
        await Dio().download(url, savePath);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to: $savePath"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Download Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            // --- NAVIGATE TO GROUP INFO SCREEN ---
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => GroupInfoScreen(
                    groupId: widget.groupId,
                    currentUserId: currentUid
                )
            ));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.groupName), // This will update if you edit it in info screen!
              Row(
                children: [
                  Text(_isAdmin ? "You are Admin" : "Tap for Info", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 14, color: Colors.white70)
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No messages yet."));
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) => _buildMessageTile(snapshot.data!.docs[index]),
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(),
          _isAdmin ? _buildAdminInputArea() : _buildReadOnlyMessage(),
        ],
      ),
    );
  }

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
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () => _sendMessage(msg: _messageController.text)),
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
      child: const Text("Only the Group Admin can post here.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildMessageTile(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMe = data['senderId'] == currentUid;
    String type = data['type'] ?? 'text';
    String fileUrl = data['fileUrl'] ?? '';
    String fileName = "file_${doc.id}.${type == 'image' ? 'jpg' : 'pdf'}";
    String senderId = data['senderId'] ?? '';
    String senderName = data['senderName'] ?? 'Admin';

    Widget userAvatar = AvatarFromProfile(uid: senderId, radius: 16, fallbackLabel: senderName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[userAvatar, const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
              decoration: BoxDecoration(
                color: isMe ? Colors.indigo[100] : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero, bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe) Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.indigo)),
                  if (type == 'text') Text(data['message'] ?? '', style: const TextStyle(fontSize: 15)),
                  if (type == 'image') GestureDetector(
                    onTap: () { if (fileUrl.isNotEmpty) showDialog(context: context, builder: (_) => Dialog(child: Image.network(fileUrl))); },
                    child: fileUrl.isNotEmpty ? Image.network(fileUrl, height: 150, width: 200, fit: BoxFit.cover) : const Icon(Icons.broken_image),
                  ),
                  if (type == 'pdf') InkWell(
                    onTap: () => _downloadFile(fileUrl, fileName),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: const Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text("PDF Document", style: TextStyle(fontSize: 12))]),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (isMe) ...[const SizedBox(width: 8), userAvatar],
        ],
      ),
    );
  }

  Widget _buildBrokenImagePlaceholder() => Container(height: 150, width: 200, color: Colors.grey[400], child: const Icon(Icons.broken_image, color: Colors.white));
}