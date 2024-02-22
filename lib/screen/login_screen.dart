import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chatvibe/screen/home_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // Add a sign-out button if needed
              // ElevatedButton(
              //   onPressed: _signOut,
              //   child: Text('Sign out'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Unused sign-out method
  // Future<void> _signOut() async {
  //   await FirebaseAuth.instance.signOut();
  //   await GoogleSignIn().signOut();
  // }

  Future<void> _handleGoogleButton(BuildContext context) async {
    try {
      UserCredential userCredential = await _signInWithGoogle();
      if (userCredential.user != null) {
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        // Handle sign in failure
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Handle sign in failure
    }
  }

  Future<UserCredential> _signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
