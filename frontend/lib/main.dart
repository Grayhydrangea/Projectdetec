// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ ของ FlutterFire CLI

// Firebase Messaging (สำหรับ background handler)
import 'package:firebase_messaging/firebase_messaging.dart';

// บริการแจ้งเตือน/บันทึก token และ heads‑up ตอน foreground
import 'services/push_service.dart';

// === pages ===
import 'sign_in_page.dart';       // class SignInPage (const)
import 'sign_up_page.dart';       // class SignUpPage (const)
import 'home.dart';               // class HomePage(uid: ...)
import 'profile.dart';            // class ProfilePage(uid: ...)
import 'history_page.dart';       // class ParkingListPage(uid: ...)
import 'report.dart';             // class BalancePage (const)
import 'setting_page.dart';       // class SettingsPage (const)
import 'edit_profile_page.dart';  // class EditProfilePage (const)
import 'notifications.dart';      // class NotificationsPage (const)

/// ต้องเป็น top-level function สำหรับ background push
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ถ้าต้องทำงานเพิ่ม ให้ init Firebase ที่นี่ (ส่วนใหญ่ Android จะโชว์ system notif ให้เอง)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ ลงทะเบียน background handler ของ FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // helper: รองรับทั้ง arguments เป็น String ('uid') หรือ Map({'uid': '...'})
  String? _extractUid(dynamic a) {
    if (a is String && a.isNotEmpty) return a;
    if (a is Map && a['uid'] is String && (a['uid'] as String).isNotEmpty) {
      return a['uid'] as String;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UP Parking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // ✅ หน้าเริ่มต้น
      initialRoute: '/login',

      // ✅ หน้าที่ "ไม่ต้องรับ arguments"
      routes: {
        '/login'        : (_) => const SignInPage(),
        '/signup'       : (_) => const SignUpPage(),
        '/settings'     : (_) => const SettingsPage(),
        '/edit_profile' : (_) => const EditProfilePage(),
        '/balance'      : (_) => const BalancePage(),
        '/notifications': (_) => const NotificationsPage(),
      },

      // ✅ หน้าที่ "ต้อง/อาจรับ uid"
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/home': {
            final uid = _extractUid(args);
            if (uid != null) {
              // ⬇️ เรียก PushService.init(uid) ทันทีที่เข้าบ้าน
              return MaterialPageRoute(builder: (_) {
                // ไม่เป็นอันตรายหากถูกเรียกซ้ำ (ภายใน service กันไว้แล้ว)
                PushService.instance.init(uid);
                return HomePage(uid: uid);
              });
            }
            // ถ้าไม่มี uid ให้ย้อนกลับไปหน้า login
            return MaterialPageRoute(builder: (_) => const SignInPage());
          }

          case '/profile': {
            final uid = _extractUid(args);
            return MaterialPageRoute(builder: (_) => ProfilePage(uid: uid));
          }

          case '/parking_list': {
            final uid = _extractUid(args);
            return MaterialPageRoute(builder: (_) => ParkingListPage(uid: uid));
          }
        }

        // ไม่รู้จัก route -> ส่งไปหน้า login
        return MaterialPageRoute(builder: (_) => const SignInPage());
      },
    );
  }
}
