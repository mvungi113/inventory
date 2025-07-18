// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD2hzPibaeqwr82YUq0s346GnM2g04LnNQ',
    appId: '1:220194288969:web:cb04ace5b24e5a5f659698',
    messagingSenderId: '220194288969',
    projectId: 'inventory2025-a63c1',
    authDomain: 'inventory2025-a63c1.firebaseapp.com',
    storageBucket: 'inventory2025-a63c1.firebasestorage.app',
    measurementId: 'G-EXJTLWJ65J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjBRDSa1whXXdd49MX6hugNU31vvnaz_w',
    appId: '1:220194288969:android:71c768cf28851ad8659698',
    messagingSenderId: '220194288969',
    projectId: 'inventory2025-a63c1',
    storageBucket: 'inventory2025-a63c1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxnvbMZNSZ-ZfXC8e5SMDIm4Ljs-GuhZI',
    appId: '1:220194288969:ios:592100f4eb32c50e659698',
    messagingSenderId: '220194288969',
    projectId: 'inventory2025-a63c1',
    storageBucket: 'inventory2025-a63c1.firebasestorage.app',
    iosBundleId: 'com.example.inventory',
  );
}
