import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chatvibe/screen/chat_page.dart';
import 'package:chatvibe/screen/home_screen.dart';

class UserSearchPage extends StatefulWidget {
  final String userId;

  UserSearchPage({required this.userId});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by displayName',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text('No results found'),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var user = _searchResults[index].data() as Map<String, dynamic>;
                      var recipientId = _searchResults[index].id; // Assuming this is the recipient's UID
                      var senderId = widget.userId; // Assuming you have the sender's UID stored in widget.userId

                      return GestureDetector(
                        onTap: () async {
                          // Check if a chat document exists between sender and recipient
                          bool chatExists = await _checkExistingChat(recipientId, senderId);

                          if (chatExists) {
                            // If a chat document exists, navigate to the existing chat page
                            String chatDocumentId = await _getExistingChatDocumentId(recipientId, senderId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(userId: senderId, recipientId: recipientId, chatDocumentId: chatDocumentId),
                              ),
                            );
                          } else {
                            // If no chat document exists, create a new document
                            String chatDocumentId = await _createNewMessageDocument(recipientId, senderId);

                            // Navigate to the chat page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(userId: senderId, recipientId: recipientId, chatDocumentId: chatDocumentId),
                              ),
                            );
                          }
                        },
                        child: ListTile(
                          title: Text(user['displayName'] ?? 'Unknown User'), // Assuming 'displayName' is the key for the user's name
                          // Add more UI elements like buttons to add as friend or initiate chat
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _search() async {
    String query = _searchController.text;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isEqualTo: query)
        .limit(1) // Limiting the query to 1 result
        .get();

    setState(() {
      _searchResults = snapshot.docs;
    });
  }

  Future<bool> _checkExistingChat(String recipientId, String senderId) async {
    QuerySnapshot snapshot1 = await FirebaseFirestore.instance
        .collection('Messages')
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: recipientId)
        .get();

    QuerySnapshot snapshot2 = await FirebaseFirestore.instance
        .collection('Messages')
        .where('senderId', isEqualTo: recipientId)
        .where('recipientId', isEqualTo: senderId)
        .get();

    return snapshot1.docs.isNotEmpty || snapshot2.docs.isNotEmpty;
  }

  Future<String> _createNewMessageDocument(String recipientId, String senderId) async {
    var messagesCollection = FirebaseFirestore.instance.collection('Messages');
    var newDocumentRef = await messagesCollection.add({
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': DateTime.now(),
      // You can add more fields as needed
    });

    return newDocumentRef.id;
  }

  Future<String> _getExistingChatDocumentId(String recipientId, String senderId) async {
    QuerySnapshot snapshot1 = await FirebaseFirestore.instance
        .collection('Messages')
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: recipientId)
        .get();

    if (snapshot1.docs.isNotEmpty) {
      return snapshot1.docs.first.id;
    }

    QuerySnapshot snapshot2 = await FirebaseFirestore.instance
        .collection('Messages')
        .where('senderId', isEqualTo: recipientId)
        .where('recipientId', isEqualTo: senderId)
        .get();

    if (snapshot2.docs.isNotEmpty) {
      return snapshot2.docs.first.id;
    }

    return '';
  }
}
