import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options Firebase générées pour le projet maasga-83b35.
/// Utilisées dans [Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)].
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions non configuré pour cette plateforme.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAzIwEbdi7Ss-BvS1UoapV0fZrt9SEDiEk',
    authDomain: 'maasga-83b35.firebaseapp.com',
    projectId: 'maasga-83b35',
    storageBucket: 'maasga-83b35.firebasestorage.app',
    messagingSenderId: '80812184966',
    appId: '1:80812184966:web:94181111ef9627c5700807',
    measurementId: 'G-9ELXHNC71F',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDw4-pBAmN-KgHR6Jv_qqp5foRjhxxAtxo',
    appId: '1:80812184966:android:ffcb58557687d9db700807',
    messagingSenderId: '80812184966',
    projectId: 'maasga-83b35',
    storageBucket: 'maasga-83b35.firebasestorage.app',
  );

  // iOS : à compléter si tu déploies sur iOS (ajouter GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDw4-pBAmN-KgHR6Jv_qqp5foRjhxxAtxo',
    appId: '1:80812184966:ios:ffcb58557687d9db700807',
    messagingSenderId: '80812184966',
    projectId: 'maasga-83b35',
    storageBucket: 'maasga-83b35.firebasestorage.app',
    iosBundleId: 'com.maasga.app',
  );
}
