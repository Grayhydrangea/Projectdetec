// lib/services/push_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _messaging = FirebaseMessaging.instance;
  final _fln = FlutterLocalNotificationsPlugin();

  /// Android channel ต้องตรงกับ AndroidManifest meta-data
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'ใช้สำหรับแจ้งเตือนสำคัญ (heads-up)',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert'), // raw/alert.mp3
  );

  bool _inited = false;

  /// เรียกครั้งเดียวหลัง login (รู้ uid แล้ว)
  Future<void> init(String uid) async {
    if (_inited) return;
    _inited = true;

    // 1) ขอ permission (iOS และ Android 13+)
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    // 2) ตั้งค่าให้แจ้งโชว์ใน foreground (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // 3) สร้าง Android notification channel
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _fln.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        // TODO: handle tap on notification (ถ้าต้องการนำทาง)
      },
    );
    await _fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4) รับ token & บันทึกเข้า users/{uid}
    await _saveToken(uid);
    FirebaseMessaging.instance.onTokenRefresh.listen((t) => _saveToken(uid, t));

    // 5) โชว์ heads-up เมื่อแอป foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      final title = msg.notification?.title ?? msg.data['title'] ?? 'การแจ้งเตือน';
      final body  = msg.notification?.body  ?? msg.data['body']  ?? '';

      // แสดง local notification (heads-up)
      await _fln.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('alert'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, presentSound: true, presentBadge: true,
          ),
        ),
        payload: msg.data.isNotEmpty ? msg.data.toString() : null,
      );
    });
  }

  Future<void> _saveToken(String uid, [String? token]) async {
    token ??= await _messaging.getToken();
    if (token == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    await ref.set({
      'fcmToken': token, // เผื่อ backend เก่าที่อ่านแบบเดิม
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// ต้องเป็น top-level function สำหรับ background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ปกติ Android จะโชว์ system notification ให้เองเมื่อมี notification payload
  // ถ้าต้องทำงานเพิ่มให้ init Firebase ที่นี่ (ถ้าใช้)
}
