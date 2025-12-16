import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/screens/create_post_screen.dart';
import 'package:studify/screens/comment_screen.dart';
import 'package:studify/screens/view_pdf_screen.dart'; // <--- Vital Import
import 'package:studify/services/post_service.dart';
import 'package:studify/widgets/avatar_from_profile.dart';

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

// --- POST CARD ---

class PostCard extends StatelessWidget {
  final String postId;
  final String author;
  final String authorUid;
  final String time;
  final String title;
  final String text;
  final List likes;
  final int comments;
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
    this.attachmentUrl,
    this.attachmentFileName,
    this.attachmentType,
    super.key,
  });

  // --- PDF VIEWER NAVIGATION ---
  void _openPDFViewer(BuildContext context, String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewPdfScreen( // Using your existing widget
          pdfUrl: url,
          title: fileName,
        ),
      ),
    );
  }

  // --- IMAGE VIEWER ---
  void _openImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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
              ) ??
                  false;

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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(children: [
              AvatarFromProfile(
                uid: authorUid,
                radius: 20,
                fallbackLabel: author,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (authorUid == currentUserId)
                IconButton(
                  onPressed: () => _showDeleteMenu(context),
                  icon: const Icon(Icons.more_vert),
                ),
            ]),
            const SizedBox(height: 10),

            // --- TITLE ---
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),

            // --- CONTENT ---
            if (text.isNotEmpty)
              Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),

            // --- ATTACHMENT ---
            if (attachmentType != null && attachmentUrl != null)
              _buildAttachment(context),

            const SizedBox(height: 12),
            const Divider(),

            // --- FOOTER ---
            Row(
              children: [
                IconButton(
                  onPressed: () => _postService.toggleLike(postId, likes),
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 20,
                    color: isLiked ? Colors.indigo : Colors.grey[700],
                  ),
                ),
                Text("${likes.length}"),
                const SizedBox(width: 15),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentScreen(postId: postId),
                      ),
                    );
                  },
                  icon: Icon(Icons.comment_outlined, size: 20, color: Colors.grey[700]),
                ),
                Text("$comments"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    // 1. IMAGE DISPLAY
    if (attachmentType == 'image') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: GestureDetector(
          onTap: () => _openImageViewer(context, attachmentUrl!),
          child: Hero(
            tag: attachmentUrl!,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                attachmentUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    // 2. PDF DISPLAY (Uses your Syncfusion screen)
    if (attachmentType == 'pdf') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          onTap: () => _openPDFViewer(context, attachmentUrl!, attachmentFileName ?? 'Document'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.red[50],
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachmentFileName ?? 'Document.pdf',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Tap to view PDF",
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      )
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}