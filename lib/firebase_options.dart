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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // 🌐 Cấu hình dành cho WEB
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBCnDQ8LhJguDnr5sIuMpiS08-AR_LWbWU',
    appId: '1:59206708671:web:dùng_app_id_web_ở_firebase_console', // 👈 Lấy App ID Web từ Firebase Console
    messagingSenderId: '59206708671',
    projectId: 'foodgo-6715e',
    authDomain: 'foodgo-6715e.firebaseapp.com',
    storageBucket: 'foodgo-6715e.firebasestorage.app',
  );

  // 🤖 Cấu hình dành cho ANDROID
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCnDQ8LhJguDnr5sIuMpiS08-AR_LWbWU',
    appId: '1:59206708671:android:9d412d406122d0bbfb450a',
    messagingSenderId: '59206708671',
    projectId: 'foodgo-6715e',
    storageBucket: 'foodgo-6715e.firebasestorage.app',
  );

  // 🍎 Cấu hình dành cho iOS (nếu chưa dùng thì dùng tạm cấu hình android hoặc bỏ qua)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBCnDQ8LhJguDnr5sIuMpiS08-AR_LWbWU',
    appId: '1:59206708671:ios:9d412d406122d0bbfb450a',
    messagingSenderId: '59206708671',
    projectId: 'foodgo-6715e',
    storageBucket: 'foodgo-6715e.firebasestorage.app',
    iosBundleId: 'com.example.foodgo',
  );
}