import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    // handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final n = message.notification;
      if (n != null) {
        await _local.show(
          n.hashCode,
          n.title,
          n.body,
          const NotificationDetails(
            android: AndroidNotificationDetails('todo_channel', 'Todo Reminders', importance: Importance.max, priority: Priority.high),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    // on token refresh -> update profile.fcm_token if logged in
    _fcm.onTokenRefresh.listen((token) async {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null && token != null) {
        await client.from('profiles').upsert({
          'id': user.id,
          'fcm_token': token,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });
    final token = await _fcm.getToken();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null && token != null) {
      await client.from('profiles').upsert({
        'id': user.id,
        'fcm_token': token,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    if (Platform.isAndroid) {
      await _fcm.setAutoInitEnabled(true);
    }
  }

  static Future<String?> getToken() => _fcm.getToken();
}
