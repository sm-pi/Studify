// lib/services/friend_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a Friend Request
  Future<void> sendFriendRequest(String targetUid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 1. Add to target user's "friend_requests" subcollection
    await _db.collection('users').doc(targetUid).collection('friend_requests').doc(currentUser.uid).set({
      'fromUid': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // 2. Add to MY "sent_requests_uids" list (So I see "Requested" on the button)
    await _db.collection('users').doc(currentUser.uid).update({
      'sent_requests_uids': FieldValue.arrayUnion([targetUid])
    });

    // 3. Create a Notification for the target user
    DocumentSnapshot myDoc = await _db.collection('users').doc(currentUser.uid).get();
    String myName = (myDoc.data() as Map<String, dynamic>)['name'] ?? 'Someone';

    await _db.collection('users').doc(targetUid).collection('notifications').add({
      'title': 'New Friend Request',
      'body': '$myName sent you a friend request.',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'friend_request',
      'senderUid': currentUser.uid,
    });
  }

  /// Accept a Friend Request
  Future<void> acceptFriendRequest(String senderUid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 1. Add sender to my 'friend_uids' list
    await _db.collection('users').doc(currentUser.uid).update({
      'friend_uids': FieldValue.arrayUnion([senderUid])
    });

    // 2. Add me to sender's 'friend_uids' list
    await _db.collection('users').doc(senderUid).update({
      'friend_uids': FieldValue.arrayUnion([currentUser.uid])
    });

    // 3. Delete the request from MY requests list
    await _db.collection('users').doc(currentUser.uid).collection('friend_requests').doc(senderUid).delete();

    // 4. Remove from Sender's "sent_requests_uids"
    await _db.collection('users').doc(senderUid).update({
      'sent_requests_uids': FieldValue.arrayRemove([currentUser.uid])
    });

    // 5. Send a notification back to the sender
    DocumentSnapshot myDoc = await _db.collection('users').doc(currentUser.uid).get();
    String myName = (myDoc.data() as Map<String, dynamic>)['name'] ?? 'Someone';

    await _db.collection('users').doc(senderUid).collection('notifications').add({
      'title': 'Request Accepted',
      'body': '$myName is now your friend!',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'friend_accept',
      'senderUid': currentUser.uid,
    });
  }

  /// Reject a Friend Request
  Future<void> rejectFriendRequest(String senderUid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Delete the request
    await _db.collection('users').doc(currentUser.uid).collection('friend_requests').doc(senderUid).delete();
  }

  /// --- THIS WAS THE MISSING FUNCTION ---
  /// Get Suggested Friends (Same Department, Not Friends yet)
  Future<List<DocumentSnapshot>> getSuggestedFriends() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    // 1. Get My Details (to find my department and existing friends)
    DocumentSnapshot myDoc = await _db.collection('users').doc(currentUser.uid).get();
    if (!myDoc.exists) return [];

    Map<String, dynamic> myData = myDoc.data() as Map<String, dynamic>;

    String myDept = myData['department'] ?? '';
    List myFriends = myData['friend_uids'] ?? [];
    List sentRequests = myData['sent_requests_uids'] ?? [];

    if (myDept.isEmpty) return [];

    // 2. Query Users in the same Department
    QuerySnapshot query = await _db
        .collection('users')
        .where('department', isEqualTo: myDept)
        .limit(20)
        .get();

    // 3. Filter the list
    List<DocumentSnapshot> suggestions = query.docs.where((doc) {
      String uid = doc.id;
      // Exclude myself
      if (uid == currentUser.uid) return false;
      // Exclude existing friends
      if (myFriends.contains(uid)) return false;
      // Exclude people I already requested
      if (sentRequests.contains(uid)) return false;

      return true;
    }).toList();

    return suggestions;
  }
}