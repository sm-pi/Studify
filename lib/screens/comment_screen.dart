import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studify/services/post_service.dart';
import 'package:studify/widgets/custom_text_field.dart';
import 'package:studify/widgets/avatar_from_profile.dart'; // Import widget

class CommentScreen extends StatefulWidget {
  final String postId;
  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  void _postComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isPosting = true);

    try {
      await _postService.addComment(widget.postId, _commentController.text.trim());
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post comment: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),
      ),
      body: Column(
        children: [
          // --- 1. Stream of Comments ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet."));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    String authorUid = comment['authorUid'] ?? '';
                    String authorName = comment['authorName'] ?? 'Anonymous';

                    return ListTile(
                      // Use the new widget here
                      leading: AvatarFromProfile(
                        uid: authorUid,
                        fallbackLabel: authorName,
                        radius: 18,
                      ),
                      title: Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(comment['text'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          // --- 2. Add Comment Input ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _commentController,
                    hintText: "Add a comment...",
                  ),
                ),
                IconButton(
                  icon: _isPosting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2,))
                      : const Icon(Icons.send),
                  onPressed: _isPosting ? null : _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}