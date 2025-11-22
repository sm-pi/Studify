// lib/services/chat_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:studify/services/storage_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // --- ENCRYPTION SETUP ---
  // 1. The Key (32 chars)
  final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  // 2. The IV (16 chars) - Fixed
  final _iv = encrypt.IV.fromUtf8('my16byteivkey123');

  late final encrypt.Encrypter _encrypter;

  ChatService() {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String getChatRoomId(String user1, String user2) {
    return user1.compareTo(user2) > 0 ? "${user1}_$user2" : "${user2}_$user1";
  }

  Future<void> sendMessage({
    required String receiverUid,
    required String messageText,
    File? file,
    String? fileType,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String chatRoomId = getChatRoomId(currentUser.uid, receiverUid);
    String? attachmentUrl;

    if (file != null) {
      attachmentUrl = await _storageService.uploadFile(file);
    }

    String encryptedText = "";
    if (messageText.isNotEmpty) {
      encryptedText = _encrypter.encrypt(messageText, iv: _iv).base64;
    }

    await _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderUid': currentUser.uid,
      'receiverUid': receiverUid,
      'text': encryptedText,
      'attachmentUrl': attachmentUrl,
      'attachmentType': fileType,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // Starts as unread
    });

    String previewMsg = file != null ? "[Sent a File]" : "Sent a message";
    await _db.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': previewMsg,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'users': [currentUser.uid, receiverUid],
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessages(String receiverUid) {
    final String currentUserUid = _auth.currentUser!.uid;
    final String chatRoomId = getChatRoomId(currentUserUid, receiverUid);

    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  String decryptMessage(String encryptedText) {
    if (encryptedText.isEmpty) return "";
    try {
      return _encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedText), iv: _iv);
    } catch (e) {
      return encryptedText;
    }
  }

  // --- RED DOT LOGIC: Get Unread Count ---
  Stream<int> getUnreadCountStream(String friendUid) {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    String chatRoomId = getChatRoomId(currentUser.uid, friendUid);

    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderUid', isEqualTo: friendUid)
        .where('receiverUid', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- RED DOT LOGIC: Clear the Dot ---
  Future<void> markMessagesAsRead(String friendUid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String chatRoomId = getChatRoomId(currentUser.uid, friendUid);

    QuerySnapshot unreadMessages = await _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderUid', isEqualTo: friendUid)
        .where('receiverUid', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _db.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}