import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser currentUser = ChatUser(id: '1', firstName: 'User');

  final ChatUser gptUser = ChatUser(id: '2', firstName: 'GPT');

  List<ChatMessage> messages = [];

  void onSend(ChatMessage message) {
    setState(() {
      messages.insert(0, message);
    });

    // Call GPT response
    getChatResponse(message);
  }

  Future<void> getChatResponse(ChatMessage m) async {
    await Future.delayed(const Duration(seconds: 1));

    ChatMessage gptMessage = ChatMessage(
      user: gptUser,
      createdAt: DateTime.now(),
      text: "Hello! I'm GPT 🤖",
    );

    setState(() {
      messages.insert(0, gptMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 100, 0),
        title: const Text(
          'GPT Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: DashChat(
        currentUser: currentUser,
        onSend: onSend, //correct
        messages: messages,
      ),
    );
  }
}
