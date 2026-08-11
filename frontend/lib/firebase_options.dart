import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

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
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLHGWRlLSqucM7wVUN3ZbU8GCytJOKLG4',
    appId: '1:908209924593:android:0e7c541fa9efca03ea7c50', // placeholder or standard
    messagingSenderId: '908209924593',
    projectId: 'life-partner-again-c112c',
    storageBucket: 'life-partner-again-c112c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBLHGWRlLSqucM7wVUN3ZbU8GCytJOKLG4',
    appId: '1:908209924593:ios:f791081eefd228bfea7c50',
    messagingSenderId: '908209924593',
    projectId: 'life-partner-again-c112c',
    storageBucket: 'life-partner-again-c112c.firebasestorage.app',
    iosBundleId: 'com.premiumglobalcorp.lifepartneragain',
  );
}
