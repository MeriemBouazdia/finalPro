import 'package:app/pages/ChatPage.dart';
import 'package:flutter/material.dart';
// make sure this file exists

void main() {
  runApp(const GreenhouseApp());
}

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greenhouse App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}
