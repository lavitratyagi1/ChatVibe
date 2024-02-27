import 'dart:async';

import 'package:chatvibe/screen/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  String _userImage = '';

  List<Map<String, dynamic>> _messages = [];
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _messageStreamSubscription; // Corrected type
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

    // Listen for updates to the messages collection in real-time
    final subscription = messagesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      setState(() {
        _messages = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _messages.sort((a, b) => b['timestamp']
            .compareTo(a['timestamp']));
      });
    });

    // Cancel the subscription when the widget is disposed
    // to prevent memory leaks
    _messageStreamSubscription = subscription;
  }

  Future<void> _sendMessage() async {
    String messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty) {
      // Check for internet connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Device is offline, handle accordingly
        return;
      }

      var messageTimestamp = DateTime.now();
      var messagesCollection =
          _messagesCollection.doc(widget.chatDocumentId).collection('messages');

      // Store the message in Firestore
      DocumentReference messageRef = await messagesCollection.add({
        'senderId': widget.userId,
        'messageContent': messageContent,
        'timestamp': messageTimestamp,
      });

      setState(() {
        _messages.insert(
          0,
          {
            'messageId': messageRef.id,
            'senderId': widget.userId,
            'messageContent': messageContent,
            'timestamp': messageTimestamp,
          },
        );
      });
      String recipientPushToken = await _getRecipientPushToken();
      if (recipientPushToken.isNotEmpty) {
        String message = messageContent; // Customize the message as needed
        await NotificationManager.sendPushNotification(
            _senderName, recipientPushToken, message);
      }

      _messageController.clear();
    }
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
                    child: Container(
                      constraints:
                          BoxConstraints(minWidth: 70), // Set minimum width
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
                          Text(
                            message['messageContent'] ?? '',
                            style: TextStyle(fontSize: 16.0),
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
    _messageStreamSubscription.cancel(); // Cancel subscription
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      // Convert Firestore Timestamp to DateTime
      DateTime dateTime = timestamp.toDate();
      // Format the DateTime as desired
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (timestamp is DateTime) {
      // If it's already a DateTime, format it directly
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
