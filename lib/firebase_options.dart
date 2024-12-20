// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtmeRalNVGLccnTnOpS_LqVYb-n-jw6oQ',
    appId: '1:488993058519:android:08a7bf2bb7a4f2c5a9ca92',
    messagingSenderId: '488993058519',
    projectId: 'messaging-app-d5e25',
    storageBucket: 'messaging-app-d5e25.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvejE6Sh2XJiv83Lj__Tb5N2-nw2SVXfQ',
    appId: '1:488993058519:ios:e3692ea2e4a558a4a9ca92',
    messagingSenderId: '488993058519',
    projectId: 'messaging-app-d5e25',
    storageBucket: 'messaging-app-d5e25.appspot.com',
    androidClientId: '488993058519-t6bcr1im1s6bh45qf5vniutrtvjlgjgo.apps.googleusercontent.com',
    iosClientId: '488993058519-vnngqu3uorkggsrt9h0on9fbsm192l7d.apps.googleusercontent.com',
    iosBundleId: 'com.example.chatvibe',
  );
}
