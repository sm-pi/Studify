// lib/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/database_services.dart';

class PostService {
  final CollectionReference postCollection =
  FirebaseFirestore.instance.collection('posts');
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// --- Create Post (Unchanged) ---
  Future<void> createPost({
    required String title,
    required String textContent,
    String? attachmentUrl,
    String? attachmentFileName,
    String? attachmentType,
  }) async {
    if (currentUser == null) {
      throw Exception("No user logged in to create a post.");
    }

    DocumentSnapshot userDoc =
    await DatabaseService(uid: currentUser!.uid).userCollection.doc(currentUser!.uid).get();

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    await postCollection.add({
      'authorUid': currentUser!.uid,
      'authorName': userData['name'] ?? 'Anonymous User',
      'authorProfilePicUrl': userData['profilePicUrl'] ?? '',
      'title': title,
      'textContent': textContent,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [], // Starts empty
      'commentCount': 0, // Starts at 0
      'attachmentUrl': attachmentUrl,
      'attachmentFileName': attachmentFileName,
      'attachmentType': attachmentType,
    });
  }

  /// --- NEW: Toggle Like on a Post ---
  Future<void> toggleLike(String postId, List likes) async {
    if (currentUser == null) return;

    // Check if the user has already liked the post
    bool isLiked = likes.contains(currentUser!.uid);

    if (isLiked) {
      // User has liked, so remove their like
      await postCollection.doc(postId).update({
        'likes': FieldValue.arrayRemove([currentUser!.uid])
      });
    } else {
      // User has not liked, so add their like
      await postCollection.doc(postId).update({
        'likes': FieldValue.arrayUnion([currentUser!.uid])
      });
    }
  }

  /// --- NEW: Add a Comment ---
  Future<void> addComment(String postId, String commentText) async {
    if (currentUser == null) return;

    // Get user data to embed in the comment
    DocumentSnapshot userDoc =
    await DatabaseService(uid: currentUser!.uid).userCollection.doc(currentUser!.uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    // 1. Add the comment to the 'comments' subcollection
    await postCollection.doc(postId).collection('comments').add({
      'text': commentText,
      'authorUid': currentUser!.uid,
      'authorName': userData['name'] ?? 'Anonymous',
      'authorProfilePicUrl': userData['profilePicUrl'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Atomically increment the 'commentCount' on the parent post
    await postCollection.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  /// --- NEW: Delete a Post ---
  Future<void> deletePost(String postId) async {
    // TODO: Add logic to delete the file from Cloudinary (this is complex)
    // For now, we just delete the post document
    await postCollection.doc(postId).delete();

  }
}