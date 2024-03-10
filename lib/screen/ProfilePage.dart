import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = '';
  String _userPhotoURL = '';
  String _userBio = '';
  bool _isEditing = false;
  final _userNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _bioFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchUserData(widget.userId);
  }

  Future<void> _fetchUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['displayName'];
          _userPhotoURL = userDoc['photoURL'];
          _userBio =
              userDoc['bio'] ?? ''; // Set bio to empty string if it's null
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'displayName': _userNameController.text,
        'bio': _bioController.text,
      });
      setState(() {
        _userName = _userNameController.text;
        _userBio = _bioController.text;
        _isEditing = false;
      });
    } catch (e) {
      print('Error saving changes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _userNameController.text = _userName;
                  _bioController.text = _userBio;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isEditing)
                  CircleAvatar(
                    backgroundImage: _userPhotoURL.isNotEmpty
                        ? NetworkImage(_userPhotoURL)
                        : null,
                    radius: 70,
                  ),
                SizedBox(height: 20),
                if (!_isEditing)
                  Text(
                    _userName.isNotEmpty ? _userName : 'Loading...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                SizedBox(height: 20),
                if (!_isEditing)
                  Text(
                    _userBio.isNotEmpty ? _userBio : 'No bio available',
                    style: TextStyle(fontSize: 16),
                  ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _userNameController,
                          decoration: InputDecoration(labelText: 'Username'),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _bioController,
                          decoration: InputDecoration(labelText: 'Bio'),
                          maxLines: 2,
                          maxLength: 100,
                          focusNode: _bioFocusNode,
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 20),
                if (!_isEditing)
                  ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: Text('Sign Out'),
                        leading: Icon(Icons.logout),
                        onTap: _signOut,
                      ),
                      // Add more ListTiles here for additional buttons
                    ],
                  ),
                if (_isEditing)
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: Text('Save Changes'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _bioController.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }
}
