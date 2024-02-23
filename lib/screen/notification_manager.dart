import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationManager {
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  static Future<void> getFirebaseMessagingToken(String userId) async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((token) {
      if (token != null) {
        storeTokenInFirestore(userId, token);
        log('Push Token: $token');
      }
    });
  }

  static Future<void> storeTokenInFirestore(String userId, String token) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userId)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userId = userSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'pushToken': token});
        log('Push Token stored in Firestore successfully');
      } else {
        log('User not found in Firestore');
      }
    } catch (e) {
      log('\nstoreTokenInFirestore Error: $e');
    }
  }

  static Future<void> sendPushNotification(
      String recipient, String pushToken, String msg, String imageUrl) async {
    try {
      final body = {
        "to": pushToken,
        "notification": {
          "title": recipient, // Change to your app's name
          "body": msg,
          "android_channel_id": "chats",
          "image": imageUrl,
        },
      };

      var res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              'key=AAAAcdpB7tc:APA91bHAsiRzow3mXY9pVDeqhTkfBF31rwpZ2MAp_xPXVYVeQlk4bOTCZLrIDyYO_sEwFQCbHDe6j_dBEbUY8zBaoncGZxzYAcVDeofheoPp7k5ExgRcAJ-J-V6qTjrSZHI2RCbO3kZr', // Replace with your FCM server key
        },
        body: jsonEncode(body),
      );

      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotification Error: $e');
    }
  }
}
