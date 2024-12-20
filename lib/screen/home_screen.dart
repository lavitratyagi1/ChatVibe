import 'package:chatvibe/screen/signupScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatvibe/screen/chat_page.dart';
import 'package:chatvibe/screen/login_screen.dart';
import 'package:chatvibe/screen/user_search.dart';
import 'package:connectivity/connectivity.dart';
import 'package:chatvibe/screen/ProfilePage.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, String> _usernames = {};
  Map<String, String> _userPhotoURLs = {};
  Map<String, String> _chatDocumentIds = {};
  Map<String, String> _recentMessages = {};
  Map<String, Timestamp> _recentMessageTimestamps = {}; // New map
  bool _isOnline = true;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _checkConnectivity();
  }

  Future<void> _checkCurrentUser() async {
    _user = _auth.currentUser;
    if (_user == null) {
      // User is not signed in, redirect to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      // User is signed in, check if email exists in Firestore users collection
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _user!.email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        // Email doesn't exist in Firestore users collection, redirect to sign-up page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SignUpScreen()),
        );
      } else {
        // Email exists in Firestore users collection, load data
        await _loadUsernamesAndChatDocumentIds();
      }
    }
  }

  Future<void> _loadUsernamesAndChatDocumentIds() async {
    _user = _auth.currentUser;
    if (_user != null) {
      try {
        QuerySnapshot chatQuery = await FirebaseFirestore.instance
            .collection('Messages')
            .where('senderId', isEqualTo: _user!.uid)
            .get();
        chatQuery.docs.forEach((doc) {
          String recipientId = doc['recipientId'];
          _chatDocumentIds[recipientId] = doc.id;
        });

        QuerySnapshot recipientChatQuery = await FirebaseFirestore.instance
            .collection('Messages')
            .where('recipientId', isEqualTo: _user!.uid)
            .get();
        recipientChatQuery.docs.forEach((doc) {
          String senderId = doc['senderId'];
          _chatDocumentIds[senderId] = doc.id;
        });

        Set<String> userIds = _chatDocumentIds.keys.toSet();
        userIds.addAll(_chatDocumentIds.values.toSet());

        await Future.forEach(userIds, (userId) async {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            _usernames[userId] = userDoc['displayName'];
            _userPhotoURLs[userId] = userDoc['photoURL'];

            DocumentSnapshot chatDoc = await FirebaseFirestore.instance
                .collection('Messages')
                .doc(_chatDocumentIds[userId])
                .get();

            if (chatDoc.exists) {
              String latestMessage = chatDoc['latestMessage'] ?? 'No recent messages';
              _recentMessages[userId] = latestMessage;
              Timestamp latestMessageTimestamp = chatDoc['latestMessageTimestamp']; // New line
              _recentMessageTimestamps[userId] = latestMessageTimestamp; // New line
            }
          }
        });

        // Sort the usernames based on the timestamp of the last message
        _usernames = Map.fromEntries(_usernames.entries.toList()
            ..sort((a, b) => _recentMessageTimestamps[b.key]!
                .compareTo(_recentMessageTimestamps[a.key]!)));
      } catch (e) {
        // Handle errors
        print('Error loading data: $e');
      }
    }
    setState(() {
      _dataLoaded = true;
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: _user!.uid)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage:
                    _user != null ? NetworkImage(_user!.photoURL!) : null,
              ),
            ),
          ),
        ],
      ),
      body: _dataLoaded
          ? _usernames.isNotEmpty
              ? ListView.builder(
                  itemCount: _usernames.length,
                  itemBuilder: (context, index) {
                    String userId = _usernames.keys.elementAt(index);
                    String username = _usernames[userId]!;
                    String photoURL = _userPhotoURLs[userId]!;
                    String recentMessage =
                        _recentMessages[userId] ?? 'No recent messages';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            // ignore: unnecessary_null_comparison
                            photoURL != null ? NetworkImage(photoURL) : null,
                      ),
                      title: Text(username),
                      subtitle: Text(recentMessage),
                      onTap: _isOnline
                          ? () {
                              _openChatPage(userId);
                            }
                          : null,
                    );
                  },
                )
              : Center(
                  child: Text('No chats available'),
                )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserSearchPage(userId: _user!.uid),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  void _openChatPage(String userId) {
    String? chatDocumentId = _chatDocumentIds[userId];
    if (chatDocumentId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userId: _user!.uid,
            recipientId: userId,
            chatDocumentId: chatDocumentId,
          ),
        ),
      );
    }
  }
}
