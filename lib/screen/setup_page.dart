import 'package:chatvibe/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetupPage extends StatefulWidget {
  final User user;

  SetupPage({required this.user});

  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome to ChatVibe!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Please choose a username to get started:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Enter your username',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _submitUsername(context);
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitUsername(BuildContext context) async {
    String username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      // Check if the username is available
      bool isUsernameAvailable = await _checkUsernameUnique(username);
      if (isUsernameAvailable) {
        // Store user data in Firestore
        await _storeUserDataInFirestore(widget.user, username);

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        // Username is not available, show error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Username is already taken. Please choose a different one.'),
        ));
      }
    }
  }

  Future<bool> _checkUsernameUnique(String username) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    QuerySnapshot querySnapshot =
        await usersCollection.where('displayName', isEqualTo: username).get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> _storeUserDataInFirestore(User user, String username) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final now = DateTime.now();

    try {
      await usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': username,
        'photoURL': user.photoURL,
        'createdAt': now,
      });
      print('User data stored in Firestore successfully');
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
