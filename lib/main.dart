import 'package:chatvibe/screen/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:chatvibe/firebase_options.dart';
import 'package:chatvibe/screen/login_screen.dart';
import 'package:chatvibe/screen/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());

  // Get the Firebase messaging token
  final FirebaseAuth _auth = FirebaseAuth.instance;
  _auth.authStateChanges().listen((User? user) {
    if (user != null) {
      NotificationManager.getFirebaseMessagingToken(user.email!);
    }
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle notifications received when the app is in the background or terminated
  print('Handling background message: ${message.notification?.title}');
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatVibe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            // Check if the user is logged in
            final user = snapshot.data;
            print('User: $user'); // Add this line to check the user value

            if (user != null) {
              return HomeScreen(); // User is logged in
            } else {
              return LoginScreen(); // User is not logged in
            }
          }
        },
      ),
    );
  }
}
