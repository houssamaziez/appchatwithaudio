import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

class ChatProvider extends GetxController {
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider(
      {required this.firebaseFirestore, required this.firebaseStorage});

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  UploadTask uploadAudio(var audioFile, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(audioFile);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath,
      Map<String, dynamic> dataNeedUpdate) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(docPath)
        .update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return firebaseFirestore
        .collection('messages')
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  void sendMessage(String content, int type, String groupChatId,
      String currentUserId, String peerId, List<String> listid,
      {String duration = ""}) {
    DateTime now = DateTime.now();

    DocumentReference documentReference = firebaseFirestore
        .collection('messages')
        .doc(
            "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}");

    MessageChat messageChat = MessageChat(
        idFrom: currentUserId,
        idTo: peerId,
        listid: listid,
        timestamp: Timestamp.now(),
        content: content,
        type: type,
        duration: duration);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        messageChat.toJson(),
      );
    });
  }
}

class TypeMessage {
  static const text = 0;
  static const image = 1;
  static const audio = 3;
}

class MessageChat {
  String idFrom;
  String idTo;
  Timestamp timestamp;
  String content;
  int type;
  String? duration;
  List<String> listid;

  MessageChat(
      {required this.idFrom,
      required this.idTo,
      required this.listid,
      required this.timestamp,
      required this.content,
      required this.type,
      this.duration});

  Map<String, dynamic> toJson() {
    return {
      "idFrom": idFrom,
      "idTo": idTo,
      "timestamp": timestamp,
      "content": content,
      "type": type,
      "duration": duration
    };
  }

  factory MessageChat.fromDocument(DocumentSnapshot doc) {
    String idFrom = doc.get('idFrom');
    String idTo = doc.get('idTo');
    Timestamp timestamp = doc.get('timestamp');
    String content = doc.get('content');
    int type = doc.get('type');
    List<String> listid = doc.get('listid');
    String duration = doc.get('duration');
    return MessageChat(
        idFrom: idFrom,
        idTo: idTo,
        listid: listid,
        duration: duration,
        timestamp: timestamp,
        content: content,
        type: type);
  }
}
