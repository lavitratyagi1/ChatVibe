import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatvibe/screen/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _displayNameController = TextEditingController();
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Submit'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a display name.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if the display name already exists
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isEqualTo: displayName)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Display name already exists. Please choose another one.';
        });
        return;
      }

      // Update display name for current user
      await _auth.currentUser?.updateDisplayName(displayName);

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'displayName': displayName,
        'email': _user!.email,
        'uid': _user!.uid,
        'name': _user!.displayName,
        'photoURL': _user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }
}
