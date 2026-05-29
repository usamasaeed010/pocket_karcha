// Firebase options for pocket-karcha-95124 (from GoogleService-Info.plist / google-services.json)
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAP2fnxQqTeMHTyEUm4gZwdBV0ilSEBnE8',
    appId: '1:367191218212:android:08c4c90c1e06b0af3b20b1',
    messagingSenderId: '367191218212',
    projectId: 'pocket-karcha-new',
    storageBucket: 'pocket-karcha-new.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDHeYIIk0G2aVSpcGE_v9Zx7W4rjO8WzeA',
    appId: '1:367191218212:ios:7018ec29e68085fd3b20b1',
    messagingSenderId: '367191218212',
    projectId: 'pocket-karcha-new',
    storageBucket: 'pocket-karcha-new.firebasestorage.app',
    iosBundleId: 'com.pocket.karcha.expense.manager',
  );

}