import 'package:flutter/material.dart';

class FeedTab extends StatelessWidget {
  final List<Map<String, dynamic>> samplePosts;

  const FeedTab({required this.samplePosts, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: samplePosts.length,
          itemBuilder: (context, index) {
            final post = samplePosts[index];
            return PostCard(
                author: post['author'],
                time: post['time'],
                text: post['text'],
                likes: post['likes'],
                comments: post['comments']);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Create post tapped")));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String author;
  final String time;
  final String text;
  final int likes;
  final int comments;

  const PostCard({
    required this.author,
    required this.time,
    required this.text,
    required this.likes,
    required this.comments,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(child: Text(author[0])),
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
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ]),
            const SizedBox(height: 10),
            Text(text),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text("$likes"),
                const SizedBox(width: 18),
                Icon(Icons.comment, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text("$comments"),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              ],
            )
          ],
        ),
      ),
    );
  }
}