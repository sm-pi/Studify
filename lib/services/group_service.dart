// lib/services/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. CORE GROUP ACTIONS ---

  // Create a Group (Used by Faculty directly, or by Admin when approving)
  Future<void> createGroup(String groupName, List<String> memberUids, {String? ownerUid}) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // If ownerUid is provided (Admin approving a student), use it.
    // Otherwise, the creator (Faculty) is the admin.
    String groupAdmin = ownerUid ?? currentUser.uid;

    // Ensure the owner is in the member list
    if (!memberUids.contains(groupAdmin)) {
      memberUids.add(groupAdmin);
    }

    await _db.collection('groups').add({
      'groupName': groupName,       // CHANGED from 'name' to 'groupName'
      'adminId': groupAdmin,        // CHANGED from 'adminUid' to 'adminId'
      'members': memberUids,
      'recentMessage': 'Group created',
      'recentSender': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'iconUrl': '',
    });
  }

  // Send a message in a group
  Future<void> sendGroupMessage(String groupId, String message) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();
    String myName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'User';

    // Add to subcollection
    await _db.collection('groups').doc(groupId).collection('messages').add({
      'message': message,          // CHANGED from 'text' to 'message' (if your chat screen uses 'message')
      'senderId': currentUser.uid, // CHANGED from 'senderUid' to 'senderId' (to match chat screen)
      'senderName': myName,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    // Update main group document for list view
    await _db.collection('groups').doc(groupId).update({
      'recentMessage': message,
      'recentSender': myName,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- 2. STUDENT REQUESTS & ADMIN APPROVAL ---

  // Student: Request a new Club
  Future<void> requestClubCreation(String groupName, String description) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();
    String myName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Student';

    await _db.collection('group_requests').add({
      'groupName': groupName,
      'description': description,
      'requesterUid': currentUser.uid,
      'requesterName': myName,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Admin: Get all pending requests
  Stream<QuerySnapshot> getClubRequests() {
    return _db.collection('group_requests').orderBy('timestamp', descending: true).snapshots();
  }

  // Admin: Approve Request -> Creates Group -> Deletes Request
  Future<void> approveClubRequest(String requestId, String groupName, String requesterUid) async {
    // 1. Create the group (Set the requester as the owner)
    // NOTE: This calls the updated createGroup function above, so it will correctly save 'adminId'
    await createGroup(groupName, [requesterUid], ownerUid: requesterUid);

    // 2. Delete the request
    await _db.collection('group_requests').doc(requestId).delete();

    // 3. Notify the student
    await _db.collection('users').doc(requesterUid).collection('notifications').add({
      'title': 'Club Approved!',
      'body': 'Your group "$groupName" has been created.',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Admin: Reject Request
  Future<void> rejectClubRequest(String requestId) async {
    await _db.collection('group_requests').doc(requestId).delete();
  }

  // --- 3. DATA FETCHING ---

  // Get groups I belong to
  Stream<QuerySnapshot> getUserGroups() {
    String uid = _auth.currentUser!.uid;
    return _db
        .collection('groups')
        .where('members', arrayContains: uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  // Get messages for a specific group
  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}