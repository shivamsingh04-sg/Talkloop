import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Activate App Check (for development, use debug; for production, use playIntegrity or deviceCheck)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Change to playIntegrity in release
    appleProvider: AppleProvider.debug,     // Change to deviceCheck in release
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talkloop Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// =======================
// ✅ Message Model
// =======================
class MessageModel {
  final String senderId;
  final String text;
  final String imageUrl;
  final DateTime timestamp;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'imageUrl': imageUrl,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
