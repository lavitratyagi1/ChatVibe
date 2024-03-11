import 'dart:async';
import 'dart:io';

import 'package:chatvibe/screen/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ChatPage extends StatefulWidget {
  final String userId;
  final String recipientId;
  final String? chatDocumentId;

  ChatPage({
    required this.userId,
    required this.recipientId,
    this.chatDocumentId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late CollectionReference _messagesCollection;
  final TextEditingController _messageController = TextEditingController();

  String _recipientName = '';
  String _senderName = '';
// ignore: unused_field
  String _userImage = '';

  List<Map<String, dynamic>> _messages = [];
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _messageStreamSubscription;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _messagesCollection = FirebaseFirestore.instance.collection('Messages');
    _loadRecipientName();
    _loadSenderName();
    if (widget.chatDocumentId != null) {
      _loadPreviousMessages();
    }

    // Initialize local notifications
    _initializeLocalNotifications();
  }

  Future<void> _loadRecipientName() async {
    var recipientDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.recipientId)
        .get();
    setState(() {
      _recipientName = recipientDoc['displayName'] ?? '';
    });
  }

  Future<void> _loadSenderName() async {
    DocumentSnapshot senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    _senderName = senderDoc['displayName'] ?? '';
    _userImage = senderDoc['photoURL'] ?? '';
  }

  Future<void> _loadPreviousMessages() async {
    final messagesCollection = FirebaseFirestore.instance
        .collection('Messages')
        .doc(widget.chatDocumentId)
        .collection('messages');

    final subscription = messagesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      setState(() {
        _messages = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      });
    });

    _messageStreamSubscription = subscription;
  }

  Future<void> _sendMessage() async {
    String messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty) {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return;
      }

      var messageTimestamp = DateTime.now();
      var messagesCollection =
          _messagesCollection.doc(widget.chatDocumentId).collection('messages');

      await messagesCollection.add({
        'senderId': widget.userId,
        'messageContent': messageContent,
        'timestamp': messageTimestamp,
      });

      var chatDoc = _messagesCollection.doc(widget.chatDocumentId);

      await chatDoc.update({
        'latestMessage': messageContent,
        'latestMessageTimestamp': DateTime.now(),
      });

      // Update the state before clearing the controller
      setState(() {
        _messageController.clear();
      });

      // Clear the message controller

      String recipientPushToken = await _getRecipientPushToken();
      if (recipientPushToken.isNotEmpty) {
        String message = messageContent;
        await NotificationManager.sendPushNotification(
            _senderName, recipientPushToken, message);
      }
    }
  }

  Future<void> _pickImageOrVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String mediaUrl = await _uploadMedia(file);
      if (mediaUrl.isNotEmpty) {
        _sendMessageWithMedia(mediaUrl);
      }
    }
  }

  Future<String> _uploadMedia(File file) async {
    String filePath =
        'chat/${widget.chatDocumentId}/${DateTime.now().millisecondsSinceEpoch}';
    firebase_storage.UploadTask task =
        firebase_storage.FirebaseStorage.instance.ref(filePath).putFile(file);

    try {
      firebase_storage.TaskSnapshot snapshot = await task.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading media: $e');
      return '';
    }
  }

  Future<void> _sendMessageWithMedia(String mediaUrl) async {
    var messageTimestamp = DateTime.now();
    var messagesCollection =
        _messagesCollection.doc(widget.chatDocumentId).collection('messages');

    await messagesCollection.add({
      'senderId': widget.userId,
      'mediaUrl': mediaUrl,
      'timestamp': messageTimestamp,
      'messageContent': "",
    });

    var chatDoc = _messagesCollection.doc(widget.chatDocumentId);

    await chatDoc.update({
      'latestMessage': "Photo",
      'latestMessageTimestamp': DateTime.now(),
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var message = _messages[index];
                return Align(
                  alignment: message['senderId'] == widget.userId
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: message['senderId'] == widget.userId ? 64.0 : 16.0,
                      right: message['senderId'] == widget.userId ? 16.0 : 64.0,
                      top: 4.0,
                      bottom: 4.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (message['mediaUrl'] != null) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                child: Image.network(
                                  message['mediaUrl'],
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          );
                        }
                      },
                      child: Container(
                        constraints: BoxConstraints(minWidth: 70),
                        decoration: BoxDecoration(
                          color: message['senderId'] == widget.userId
                              ? Colors.blue[200]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (message['messageContent'] != null)
                              Text(
                                message['messageContent'],
                                style: TextStyle(fontSize: 16.0),
                              ),
                            if (message['mediaUrl'] != null)
                              Image.network(
                                message['mediaUrl'],
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            SizedBox(height: 4.0),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style:
                                  TextStyle(fontSize: 12.0, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                    onPressed: _pickImageOrVideo, icon: Icon(Icons.photo)),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageStreamSubscription.cancel();
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (timestamp is DateTime) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '';
    }
  }

  void _initializeLocalNotifications() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<String> _getRecipientPushToken() async {
    try {
      var recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientId)
          .get();
      return recipientDoc['pushToken'] ?? '';
    } catch (e) {
      print('Error fetching recipient push token: $e');
      return '';
    }
  }
}
