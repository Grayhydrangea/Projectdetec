import 'package:flutter/material.dart';
import 'package:frontend/history_page.dart';
import 'package:frontend/home.dart';
import 'package:frontend/setting_page.dart';
import 'package:frontend/sign_in_page.dart';
import 'package:frontend/sign_up_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      home: SignInPage(), // เริ่มต้นที่หน้า Sign In
      routes: {
        '/home': (context) {
          // Extract uid from route arguments
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return HomePage(uid: args);
          } else {
            // Handle missing uid by redirecting to SignInPage
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/signin');
            });
            return Container(); // Placeholder to avoid null return
          }
        },
        '/settings': (context) => SettingsPage(),
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/history': (context) => HistoryPage(),
      },
    );
  }
}