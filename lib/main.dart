import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Chat App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

// ========== models/message_model.dart ==========
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
      senderId: json['senderId'],
      text: json['text'],
      imageUrl: json['imageUrl'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}
