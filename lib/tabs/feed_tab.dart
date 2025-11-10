// lib/tabs/feed_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/create_post_screen.dart';
import 'package:studify/screens/comment_screen.dart';
import 'package:studify/services/post_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading posts."));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No posts yet. Be the first!"));
            }

            final posts = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;

                final Timestamp? t = post['timestamp'] as Timestamp?;
                final String time = t != null
                    ? t.toDate().toString().substring(0, 16)
                    : 'Just now';

                return PostCard(
                  postId: postId,
                  author: post['authorName'] ?? 'Unknown',
                  authorUid: post['authorUid'] ?? '',
                  time: time,
                  title: post['title'] ?? 'No Title',
                  text: post['textContent'] ?? '',
                  likes: post['likes'] ?? [],
                  comments: post['commentCount'] ?? 0,
                  authorProfilePicUrl: post['authorProfilePicUrl'] ?? '',
                  attachmentUrl: post['attachmentUrl'],
                  attachmentFileName: post['attachmentFileName'],
                  attachmentType: post['attachmentType'],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- UPDATED POSTCARD WIDGET ---

class PostCard extends StatelessWidget {
  final String postId;
  final String author;
  final String authorUid;
  final String time;
  final String title;
  final String text;
  final List likes;
  final int comments;
  final String authorProfilePicUrl;
  final String? attachmentUrl;
  final String? attachmentFileName;
  final String? attachmentType;

  final PostService _postService = PostService();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  PostCard({
    required this.postId,
    required this.author,
    required this.authorUid,
    required this.time,
    required this.title,
    required this.text,
    required this.likes,
    required this.comments,
    required this.authorProfilePicUrl,
    this.attachmentUrl,
    this.attachmentFileName,
    this.attachmentType,
    super.key,
  });

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _showDeleteMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red[700]),
            title: Text("Delete Post", style: TextStyle(color: Colors.red[700])),
            onTap: () async {
              Navigator.of(ctx).pop();
              bool confirm = await showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text("Delete Post"),
                  content: const Text("Are you sure you want to delete this post?"),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                    ),
                    TextButton(
                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                    ),
                  ],
                ),
              ) ?? false;

              if (confirm) {
                await _postService.deletePost(postId);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text("Cancel"),
            onTap: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiked = likes.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Row(children: [
              CircleAvatar(
                backgroundImage: authorProfilePicUrl.isNotEmpty
                    ? NetworkImage(authorProfilePicUrl)
                    : null,
                child: authorProfilePicUrl.isEmpty ? Text(author[0]) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(time,
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ]),
              ),
              if (authorUid == currentUserId)
                IconButton(
                  onPressed: () => _showDeleteMenu(context),
                  icon: const Icon(Icons.more_vert),
                ),
            ]),
            const SizedBox(height: 10),

            // Post Title
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),

            // Post Text Content
            if (text.isNotEmpty) Text(text),

            // Attachment Display
            if (attachmentType != null)
              _buildAttachment(),

            const SizedBox(height: 12),

            // --- Footer ---
            Row(
              children: [
                // Like Button
                IconButton(
                  onPressed: () => _postService.toggleLike(postId, likes),
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 20,
                    color: isLiked ? Colors.indigo : Colors.grey[700],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                Text("${likes.length}"),
                const SizedBox(width: 18),
                // Comment Button
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentScreen(postId: postId),
                      ),
                    );
                  },
                  icon: Icon(Icons.comment_outlined, size: 20, color: Colors.grey[700]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                Text("$comments"),
                const Spacer(),
                // --- SHARE BUTTON REMOVED ---
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Attachment helper
  Widget _buildAttachment() {
    if (attachmentType == 'image' && attachmentUrl != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            attachmentUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (attachmentType == 'pdf' && attachmentFileName != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          onTap: () => _launchUrl(attachmentUrl!),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    attachmentFileName!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.open_in_new),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}