// File generated manually based on google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCSNkiBxAA9S-SNzIe3zoIt6Exg5igSGUs',
    authDomain: 'qr-attendance-f689c.firebaseapp.com',
    projectId: 'qr-attendance-f689c',
    storageBucket: 'qr-attendance-f689c.firebasestorage.app',
    messagingSenderId: '371189020840',
    appId: '1:371189020840:web:adec8f6b8d3956aba52a9d',
    measurementId: 'G-WDCGX0KPK6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACEYiBnxSyYov4qb-nX0bHoGxGcW7gaKM',
    appId: '1:371189020840:android:2160242be18a15b9a52a9d',
    messagingSenderId: '371189020840',
    projectId: 'qr-attendance-f689c',
    storageBucket: 'qr-attendance-f689c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBN8871tgqoc1-HemZwhd-6lIY233jJ6aQ',
    appId: '1:371189020840:ios:81c454d0631df644a52a9d',
    messagingSenderId: '371189020840',
    projectId: 'qr-attendance-f689c',
    storageBucket: 'qr-attendance-f689c.firebasestorage.app',
  );
}
