// lib/services/database_services.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
  FirebaseFirestore.instance.collection('users');

  /// Creates a profile document for a new user
  Future<void> createUserProfile({required String name, required String email}) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'uid': uid,
      'bio': '',
      'profilePicUrl': '',
      'friend_uids': [],
      'role': null,
      'department': '',
      'intake': '',
      'designation': '',
      'profileCompleted': false, // <-- THIS IS THE FIX. Add this line.
    });
  }

  /// Updates an existing user's profile data
  Future<void> updateUserProfile(Map<String, dynamic> dataToUpdate) async {
    return await userCollection.doc(uid).update(dataToUpdate);
  }
}