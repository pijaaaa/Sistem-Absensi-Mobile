// GENERATED CODE - DO NOT MODIFY
// Run `flutterfire configure` to regenerate.
// Template — replace placeholder values with your Firebase project credentials.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError(
        'DefaultFirebaseOptions is not supported for this platform.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzGX7dPFLvfvou_DyDwNaXmchCTT7F7M8',
    appId: '1:424349277679:android:c46e92c663bde194216a1a',
    messagingSenderId: '424349277679',
    projectId: 'absensi-mobile-36605',
    storageBucket: 'absensi-mobile-36605.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'absensi-mobile',
    storageBucket: 'absensi-mobile.appspot.com',
    iosBundleId: 'com.example.absensi',
  );
}
