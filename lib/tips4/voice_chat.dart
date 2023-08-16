// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:breathing_collection/breathing_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_30_tips/tips3/image.dart';
import 'package:flutter_30_tips/tips4/audioController.dart';
import 'package:flutter_30_tips/tips4/controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:voice_message_package/voice_message_package.dart';
import '../home.dart';
import '../tips2/chatController.dart';

class VoiceChat extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> data;
  const VoiceChat({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  _VoiceChatState createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> {
  TextEditingController messageController = TextEditingController();

  late ChatProvider chatProvider;
  bool temp = false;
  bool audio = false;
  int _limit = 20;
  int _limitIncrement = 20;
  List<QueryDocumentSnapshot> listMessage = [];

  Stream<QuerySnapshot>? chatMessageStream;
  final ScrollController _scrollController = ScrollController();
  String groupChatId = "";
  bool isShowSticker = false;
  final FocusNode focusNode = FocusNode();
  String currentUserId = "";

  AudioController audioController = Get.put(AudioController());
  AudioPlayer audioPlayer = AudioPlayer();
  String audioURL = "";
  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      recordFilePath = await getFilePath();
      RecordMp3.instance.start(recordFilePath, (type) {
        setState(() {});
      });
    } else {}
    setState(() {});
  }

  void stopRecord() async {
    bool stop = RecordMp3.instance.stop();
    audioController.end.value = DateTime.now();
    audioController.calcDuration();
    var ap = AudioPlayer();
    await ap.play(AssetSource("Notification.mp3"));
    ap.onPlayerComplete.listen((a) {});
    if (stop) {
      audioController.isRecording.value = false;
      audioController.isSending.value = true;
      await uploadAudio();
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath =
        "${storageDirectory.path}/record${DateTime.now().microsecondsSinceEpoch}.acc";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return "$sdPath/test_${i++}.mp3";
  }

  bool issendmsg = false;

  uploadAudio() async {
    setState(() {
      issendmsg = true;
    });
    UploadTask uploadTask = chatProvider.uploadAudio(File(recordFilePath),
        "audio/${DateTime.now().millisecondsSinceEpoch.toString()}");
    try {
      TaskSnapshot snapshot = await uploadTask;
      audioURL = await snapshot.ref.getDownloadURL();
      String strVal = audioURL.toString();
      setState(() {
        audioController.isSending.value = false;
        onSendMessage(strVal, TypeMessage.audio,
            duration: audioController.total);
      });
    } on FirebaseException catch (e) {
      setState(() {
        audioController.isSending.value = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
    setState(() {
      issendmsg = false;
    });
  }

  late String recordFilePath;

  void readLocal() async {
    var a = await FirebaseFirestore.instance.collection('chat').get();
    setState(() {
      currentUserId = widget.data.id == "AwCh9AOfdnMgK8gJZnOL"
          ? a.docs[0].id
          : a.docs[1].id;
    });
    String peerId =
        widget.data.id != "AwCh9AOfdnMgK8gJZnOL" ? a.docs[0].id : a.docs[1].id;
    if (currentUserId.compareTo(peerId) > 0) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }
    chatProvider.updateDataFirestore(
      'chat',
      currentUserId,
      {'chattingWith': peerId},
    );
  }

  void onSendMessage(String content, int type, {String? duration = ""}) {
    if (content.trim().isNotEmpty) {
      messageController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.data.id.toString(),
          duration: duration!);
      _scrollController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send', backgroundColor: Colors.grey);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    chatProvider = Get.put(ChatProvider(
        firebaseFirestore: FirebaseFirestore.instance,
        firebaseStorage: FirebaseStorage.instance));
    focusNode.addListener(onFocusChange);
    _scrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void _showBottomSheet(BuildContext contex) {
    showModalBottomSheet(
      isScrollControlled: true, // تحديد أن النافذة قابلة للتمرير
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      context: context,
      builder: (BuildContext context) {
        return GetBuilder<ChatController>(
            init: ChatController(),
            builder: (contt) {
              return Container(
                height: 150,
                // ignore: sort_child_properties_last
                child: Column(
                  children: [
                    GetBuilder<ChatController>(
                        init: ChatController(),
                        builder: (contt) {
                          return Column(
                            children: [
                              GestureDetector(
                                // onLongPress: () async {
                                //   var audioPlayer = AudioPlayer();
                                //   await audioPlayer.play(AssetSource("Notification.mp3"));
                                //   audioPlayer.onPlayerComplete.listen((a) {
                                //     audioController.start.value = DateTime.now();
                                //     startRecord();
                                //     audioController.isRecording.value = true;
                                //   });

                                //   setState(() {});
                                // },
                                onTap: () async {
                                  if (contt.isPressed == false) {
                                    await audioPlayer
                                        .play(AssetSource("Notification.mp3"));
                                    audioPlayer.onPlayerComplete.listen((a) {
                                      startRecord();

                                      audioController.start.value =
                                          DateTime.now();
                                      audioController.isRecording.value = true;
                                    });
                                    contt.isPressed = true;
                                    contt.startTimer();
                                  } else {
                                    stopRecord();

                                    contt.isPressed = false;
                                    contt.stopTimer();
                                  }
                                },
                                onLongPress: () async {
                                  await audioPlayer
                                      .play(AssetSource("Notification.mp3"));
                                  audioPlayer.onPlayerComplete.listen((a) {
                                    startRecord();

                                    audioController.start.value =
                                        DateTime.now();
                                    audioController.isRecording.value = true;
                                  });
                                  contt.isPressed = true;
                                  contt.startTimer();
                                },
                                onLongPressEnd: (_) {
                                  stopRecord();

                                  contt.isPressed = false;
                                  contt.stopTimer();
                                },
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: BreathingGlowingButton(
                                                height: 100.0,
                                                width: 100.0,
                                                buttonBackgroundColor:
                                                    Color(0xFF373A49)
                                                        .withOpacity(0.5),
                                                glowColor: contt.isPressed
                                                    ? Color(0xFF777AF9)
                                                    : Colors.transparent,
                                                icon: Icons.mic,
                                                iconColor: Colors.white,
                                                onTap: () {
                                                  // do something
                                                },
                                              ),
                                            ),
                                            Center(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 60),
                                                child: Text(
                                                  '${contt.formatTime(contt.counter)}',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      onLongPress: () async {
                                        // Simulating some task

                                        var audioPlayer = AudioPlayer();
                                        await audioPlayer.play(
                                            AssetSource("Notification.mp3"));
                                        audioPlayer.onPlayerComplete
                                            .listen((a) {
                                          startRecord();
                                          audioController.start.value =
                                              DateTime.now();
                                          audioController.isRecording.value =
                                              true;
                                        });
                                        contt.isPressed = true;
                                        contt.startTimer();
                                        setState(() {});
                                      },
                                      // onTap: () => _showBottomSheet(context),
                                      onLongPressEnd: (details) {
                                        stopRecord();
                                        contt.stopTimer();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                  ],
                ),
                padding: EdgeInsets.all(20),
              );
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar(widget.data['name']),
      body: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              buildListMessage(),
              issendmsg
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Image.asset(
                        "assets/typing.gif",
                        height: 40,
                      ),
                    )
                  : Container(),
              Obx(
                () => buildInput(),
              )
            ],
          ),
          // buildLoading(),
        ],
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: audioController.isSending.value
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SizedBox.shrink(),
    );
  }

  _incomingMSG(String a) {
    return Align(
      alignment: (Alignment.topLeft),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: mainColor.withOpacity(0.18)),
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
        child: Text(
          a,
          style: TextStyle(fontSize: 12, color: Color(0xff8A8A8A)),
        ),
      ),
    );
  }

  File? imageFile;
  bool isLoading = false;
  String imageUrl = "";
  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  Future uploadFile() async {
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!,
        "image/${DateTime.now().millisecondsSinceEpoch.toString()}");
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  Widget buildInput() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(
            color: mainColor.withOpacity(0.25),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        //height: 50,
        child: TextField(
          onSubmitted: (value) {
            onSendMessage(messageController.text, TypeMessage.text);
          },
          controller: messageController,
          focusNode: focusNode,
          decoration: InputDecoration(
              prefixIcon: Container(
                width: 80,
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      child: Icon(Icons.photo, color: mainColor),
                      onTap: () {
                        getImage();
                      },
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      child: Icon(
                        Icons.mic,
                        color: mainColor,
                      ),
                      // onLongPress: () async {
                      //   var audioPlayer = AudioPlayer();
                      //   await audioPlayer.play(AssetSource("Notification.mp3"));
                      //   audioPlayer.onPlayerComplete.listen((a) {
                      //     audioController.start.value = DateTime.now();
                      //     startRecord();
                      //     audioController.isRecording.value = true;
                      //   });

                      //   setState(() {});
                      // },
                      onTap: () => _showBottomSheet(context),
                      // onLongPressEnd: (details) {
                      //   stopRecord();
                      // },
                    ),
                    SizedBox(
                      width: 10,
                    ),
                  ],
                ),
              ),
              suffixIcon: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  child: Icon(Icons.send, color: mainColor),
                  onTap: () =>
                      onSendMessage(messageController.text, TypeMessage.text),
                ),
              ),
              hintText: audioController.isRecording.value
                  ? "Recording audio..."
                  : "Your message...",
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              hintStyle: TextStyle(color: Color(0xff8A8A8A), fontSize: 15),
              border: InputBorder.none),
        ),
      ),
    );
  }

  _outgoingMSG(String a) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: mainColor,
        ),
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
        child: Text(
          a,
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatStream(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage = snapshot.data!.docs;
                  if (listMessage.isNotEmpty) {
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 40),
                      itemBuilder: (context, index) =>
                          buildItem(index, snapshot),
                      itemCount: snapshot.data?.docs.length,
                      reverse: true,
                      controller: _scrollController,
                    );
                  } else {
                    return Center(
                        child: Text(
                      "No message here yet...",
                      style: TextStyle(color: Colors.black),
                    ));
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _audio({
    required String message,
    required bool isCurrentUser,
    required int index,
    required String time,
    required String duration,
  }) {
    Duration parseDurationString(String durationString) {
      List<String> parts = durationString.split(":");
      if (parts.length == 3) {
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        int seconds = int.tryParse(parts[2]) ?? 0;
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }

      return Duration.zero;
    }

    return VoiceMessage(
      contactCircleColor: isCurrentUser ? Colors.white : mainColor,
      showDuration: false,
      audioSrc: message, noiseCount: 12,
      played: true, // To show played badge or not.
      me: false, // Set message side.
      contactBgColor: Color.fromARGB(31, 255, 255, 255),

      contactFgColor: Color.fromARGB(0, 8, 0, 0),
      contactPlayIconBgColor: Colors.transparent,
      meFgColor: Color.fromARGB(31, 255, 255, 255),
      meBgColor: Colors.black54, mePlayIconColor: Colors.amber,
      onPlay: () {
        // print(audioController.isRecordPlaying);

        // audioController.onPressedPlayButton(index, message);
      }, // Do something when voice played.
    );
  }

  Widget buildItem(int index, AsyncSnapshot<QuerySnapshot<Object?>> document) {
    if (document != null) {
      int s = index - 1 < 1 ? index : index - 1;
      MessageChat messageChat2 =
          MessageChat.fromDocument(document.data!.docs[s]);
      MessageChat messageChat =
          MessageChat.fromDocument(document.data!.docs[index]);
      DateTime messageTimestamp =
          DateTime(2023, 8, 16, 13, 3, 12); // Example timestamp

      DateTime now = messageChat2.timestamp.toDate();
      Duration difference = now.difference(messageChat.timestamp.toDate());
      print(difference);
      String formattedDateTime;

      if (difference.inMinutes >= 0.5) {
        formattedDateTime =
            "${messageTimestamp.year}-${messageTimestamp.month}-${messageTimestamp.day} ${messageTimestamp.hour}:${messageTimestamp.minute}:${messageTimestamp.second}";
      } else {
        formattedDateTime = "";
      }
      if (messageChat.idFrom == currentUserId) {
        // Right (my message)
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              formattedDateTime == ""
                  ? Container()
                  : Text(
                      formattedDateTime.toString(),
                      style: TextStyle(color: Colors.black12),
                    ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Text
                  if (messageChat.type == TypeMessage.text)
                    _outgoingMSG(messageChat.content),
                  // Image
                  if (messageChat.type == TypeMessage.image)
                    Container(
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20 : 10,
                          right: 10),
                      child: ImageContainer(
                        messageChat: messageChat,
                      ),
                    ),
                  if (messageChat.type == TypeMessage.audio)
                    _audio(
                        message: messageChat.content,
                        isCurrentUser: messageChat.idFrom == currentUserId,
                        index: index,
                        time: messageChat.timestamp.toString(),
                        duration: messageChat.duration.toString())
                ],
              ),
            ],
          ),
        );
      } else {
        // Left (peer message)
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: <Widget>[
                  isLastMessageLeft(index)
                      ? Material(
                          borderRadius: BorderRadius.all(
                            Radius.circular(18),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Container(color: mainColor),
                        )
                      : Container(width: 35),
                  if (messageChat.type == TypeMessage.text)
                    _incomingMSG(messageChat.content),
                  if (messageChat.type == TypeMessage.image)
                    ImageContainer(messageChat: messageChat),
                  if (messageChat.type == TypeMessage.audio)
                    _audio(
                        message: messageChat.content,
                        isCurrentUser: messageChat.idFrom == currentUserId,
                        index: index,
                        time: messageChat.timestamp.toString(),
                        duration: messageChat.duration.toString())
                ],
              ),

              // Time
              // isLastMessageLeft(index)
              //     ? Container(
              //         margin: EdgeInsets.only(left: 50, top: 5, bottom: 5),
              //         child: Text(
              //           DateFormat('dd MMM kk:mm').format(
              //               DateTime.fromMillisecondsSinceEpoch(
              //                   int.parse(messageChat.timestamp.toString()))),
              //           style: TextStyle(
              //               color: Colors.grey,
              //               fontSize: 12,
              //               fontStyle: FontStyle.italic),
              //         ),
              //       )
              //     : SizedBox.shrink()
            ],
          ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 && listMessage[index - 1].get("idFrom") == currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 && listMessage[index - 1].get("idFrom") != currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }
}
