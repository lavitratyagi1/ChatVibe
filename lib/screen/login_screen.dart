import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatvibe/screen/home_screen.dart';
import 'package:chatvibe/screen/setup_page.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('ChatVibe'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _handleGoogleButton(context);
                  },
                  icon: Image.asset(
                    'lib/screen/images/google_logo.png', // Replace with Google logo asset
                    height: 30,
                    width: 30,
                  ),
                  label: Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white, // Google sign-in button color
                    onPrimary: Colors.black, // Text color
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleButton(BuildContext context) async {
    try {
      UserCredential userCredential = await _signInWithGoogle();
      if (userCredential.user != null) {
        bool emailExists = await _checkUserEmailExists(userCredential.user!);
        if (emailExists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SetupPage(user: userCredential.user!)),
          );
        }
      } else {
        // Handle sign in failure
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Handle sign in failure
    }
  }

  Future<bool> _checkUserEmailExists(User user) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot userDoc = await usersCollection.doc(user.uid).get();
    return userDoc.exists;
  }

  Future<UserCredential> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
