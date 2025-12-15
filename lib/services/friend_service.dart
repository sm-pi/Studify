// lib/services/friend_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. CORE ACTIONS (Send, Accept, Reject) ---

  Future<void> sendFriendRequest(String targetUid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // A. Add to target's inbox
    await _db.collection('users').doc(targetUid).collection('friend_requests').doc(currentUser.uid).set({
      'fromUid': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // B. Add to my sent list (so UI shows "Requested")
    await _db.collection('users').doc(currentUser.uid).update({
      'sent_requests_uids': FieldValue.arrayUnion([targetUid])
    });

    // C. Notification
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

  Future<void> acceptFriendRequest(String senderUid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // A. Add to friends arrays
    await _db.collection('users').doc(currentUser.uid).update({'friend_uids': FieldValue.arrayUnion([senderUid])});
    await _db.collection('users').doc(senderUid).update({'friend_uids': FieldValue.arrayUnion([currentUser.uid])});

    // B. Clean up requests
    await _db.collection('users').doc(currentUser.uid).collection('friend_requests').doc(senderUid).delete();
    await _db.collection('users').doc(senderUid).update({'sent_requests_uids': FieldValue.arrayRemove([currentUser.uid])});

    // C. Notification
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

  Future<void> rejectFriendRequest(String senderUid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db.collection('users').doc(currentUser.uid).collection('friend_requests').doc(senderUid).delete();
    await _db.collection('users').doc(senderUid).update({'sent_requests_uids': FieldValue.arrayRemove([currentUser.uid])});
  }

  // --- 2. DATA FETCHING ---

  // Get Suggested Friends (Strictly Same Dept)
  Future<List<DocumentSnapshot>> getSuggestedFriends() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    DocumentSnapshot myDoc = await _db.collection('users').doc(currentUser.uid).get();
    Map<String, dynamic> myData = myDoc.data() as Map<String, dynamic>;

    String myDept = myData['department'] ?? '';
    List myFriends = myData['friend_uids'] ?? [];
    List sentRequests = myData['sent_requests_uids'] ?? [];

    QuerySnapshot query;
    if (myDept.isNotEmpty) {
      query = await _db.collection('users').where('department', isEqualTo: myDept).limit(30).get();
    } else {
      query = await _db.collection('users').limit(30).get();
    }

    return query.docs.where((doc) {
      String uid = doc.id;
      if (uid == currentUser.uid) return false;
      if (myFriends.contains(uid)) return false;
      if (sentRequests.contains(uid)) return false;
      return true;
    }).toList();
  }

  // Search Users (Global Search by Name)
  Future<List<DocumentSnapshot>> searchUsers(String queryText) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null || queryText.isEmpty) return [];

    DocumentSnapshot myDoc = await _db.collection('users').doc(currentUser.uid).get();
    Map<String, dynamic> myData = myDoc.data() as Map<String, dynamic>;
    List myFriends = myData['friend_uids'] ?? [];
    List sentRequests = myData['sent_requests_uids'] ?? [];

    // Prefix Search: "Joh" -> "John", "Johnny"
    QuerySnapshot query = await _db
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: queryText)
        .where('name', isLessThan: '$queryText\uf8ff')
        .limit(20)
        .get();

    return query.docs.where((doc) {
      String uid = doc.id;
      if (uid == currentUser.uid) return false;
      if (myFriends.contains(uid)) return false;
      // We DO show sent requests in search so user can see they are "Pending"
      // But we exclude friends because you can't add them again
      if (myFriends.contains(uid)) return false;
      return true;
    }).toList();
  }

  // Helper to get Sent Requests ID list (to update UI buttons)
  Future<List> getSentRequestsIds() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];
    DocumentSnapshot myDoc = await _db.collection('users').doc(currentUser.uid).get();
    return (myDoc.data() as Map<String, dynamic>)['sent_requests_uids'] ?? [];
  }
}