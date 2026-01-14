import 'package:camera/camera.dart';
import 'package:face/screens/home_screen.dart';
import 'package:face/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Flutter Local Notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Background FCM handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _showNotification(message);
}

// Function to show notification
Future<void> _showNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'face_app_channel', // channel id
      'Face App Notifications', // channel name
      channelDescription: 'Notifications for Face App',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }
}

// Function to send FCM token to backend
Future<void> sendTokenToServer(String token) async {
  try {
    await http.post(
      Uri.parse('http://10.238.8.1:8000/register-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );
  } catch (e) {
    debugPrint("Token send error: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Optional: handle notification tap
        debugPrint('Notification tapped with payload: ${details.payload}');
      });

  // Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize cameras
  final List<CameraDescription> cameras = await availableCameras();

  // Firebase Messaging instance
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permission
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Get FCM token and send to backend
  String? fcmToken = await messaging.getToken();
  if (fcmToken != null) await sendTokenToServer(fcmToken);

  // Foreground FCM listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message);
  });

  // Optional: handle notification tap when app is in background or terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification clicked: ${message.data}');
    // You can navigate to a specific screen if needed:
    // navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => SomeScreen()));
  });

  // Check login status
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(cameras: cameras, isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final bool isLoggedIn;

  const MyApp({super.key, required this.cameras, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Face ID Scanner',
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
