// File generated with real Firebase credentials for uninotes-ai-89d4a.

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDFJ-WZsBGCYKRcJDZEg72a4Gbo6h8ywDw',
    appId: '1:694593027388:web:bd9b8eaa3518656c9ab239',
    messagingSenderId: '694593027388',
    projectId: 'uninotes-ai-89d4a',
    authDomain: 'uninotes-ai-89d4a.firebaseapp.com',
    storageBucket: 'uninotes-ai-89d4a.firebasestorage.app',
    measurementId: 'G-GPDCYJLG2Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFJ-WZsBGCYKRcJDZEg72a4Gbo6h8ywDw',
    appId: '1:694593027388:android:bd9b8eaa3518656c9ab239',
    messagingSenderId: '694593027388',
    projectId: 'uninotes-ai-89d4a',
    storageBucket: 'uninotes-ai-89d4a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDFJ-WZsBGCYKRcJDZEg72a4Gbo6h8ywDw',
    appId: '1:694593027388:ios:bd9b8eaa3518656c9ab239',
    messagingSenderId: '694593027388',
    projectId: 'uninotes-ai-89d4a',
    storageBucket: 'uninotes-ai-89d4a.firebasestorage.app',
    iosBundleId: 'com.uninotesai.uninotesAi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDFJ-WZsBGCYKRcJDZEg72a4Gbo6h8ywDw',
    appId: '1:694593027388:ios:bd9b8eaa3518656c9ab239',
    messagingSenderId: '694593027388',
    projectId: 'uninotes-ai-89d4a',
    storageBucket: 'uninotes-ai-89d4a.firebasestorage.app',
    iosBundleId: 'com.uninotesai.uninotesAi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDFJ-WZsBGCYKRcJDZEg72a4Gbo6h8ywDw',
    appId: '1:694593027388:web:bd9b8eaa3518656c9ab239',
    messagingSenderId: '694593027388',
    projectId: 'uninotes-ai-89d4a',
    authDomain: 'uninotes-ai-89d4a.firebaseapp.com',
    storageBucket: 'uninotes-ai-89d4a.firebasestorage.app',
  );
}
