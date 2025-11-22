// lib/screens/chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:studify/services/chat_service.dart';
import 'package:studify/widgets/custom_text_field.dart';

class ChatScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;

  const ChatScreen({super.key, required this.friendUid, required this.friendName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isUploading = false;

  // --- THIS IS THE MISSING PIECE ---
  @override
  void initState() {
    super.initState();
    // When this screen opens, tell database to remove the Red Dot
    _chatService.markMessagesAsRead(widget.friendUid);
  }
  // -------------------------------

  // --- SEND TEXT ---
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String text = _messageController.text.trim();
    _messageController.clear();
    await _chatService.sendMessage(receiverUid: widget.friendUid, messageText: text);
  }

  // --- PICK AND SEND FILE ---
  Future<void> _pickAndSendFile(FileType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: type == FileType.custom ? ['pdf'] : null,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      File file = File(result.files.single.path!);
      String fileType = type == FileType.image ? 'image' : 'pdf';

      try {
        await _chatService.sendMessage(
            receiverUid: widget.friendUid,
            messageText: "", // No text, just file
            file: file,
            fileType: fileType
        );
      } catch (e) {
        print("Upload failed: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentUid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          // --- MESSAGES LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.friendUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Say Hi! 👋"));
                }
                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderUid'] == currentUid;

                    // 1. DECRYPT TEXT
                    String encryptedContent = data['text'] ?? '';
                    String visibleText = _chatService.decryptMessage(encryptedContent);

                    // 2. GET ATTACHMENT INFO
                    String? attachmentUrl = data['attachmentUrl'];
                    String? attachmentType = data['attachmentType'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // A. SHOW IMAGE
                            if (attachmentType == 'image' && attachmentUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(attachmentUrl, width: 150, fit: BoxFit.cover),
                                ),
                              ),

                            // B. SHOW PDF BUTTON
                            if (attachmentType == 'pdf' && attachmentUrl != null)
                              GestureDetector(
                                onTap: () => _launchUrl(attachmentUrl),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text("View PDF", style: TextStyle(color: Colors.black, fontSize: 12))
                                    ],
                                  ),
                                ),
                              ),

                            // C. SHOW TEXT
                            if (visibleText.isNotEmpty)
                              Text(visibleText, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- INPUT AREA ---
          if (_isUploading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Attachment Button
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.indigo),
                  onPressed: () {
                    showModalBottomSheet(context: context, builder: (context) => Wrap(
                      children: [
                        ListTile(
                            leading: const Icon(Icons.image), title: const Text("Image"),
                            onTap: () { Navigator.pop(context); _pickAndSendFile(FileType.image); }
                        ),
                        ListTile(
                            leading: const Icon(Icons.picture_as_pdf), title: const Text("PDF"),
                            onTap: () { Navigator.pop(context); _pickAndSendFile(FileType.custom); }
                        ),
                      ],
                    ));
                  },
                ),
                Expanded(child: CustomTextField(controller: _messageController, hintText: "Type a message...")),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}