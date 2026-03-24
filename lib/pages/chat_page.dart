import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'widget/theme_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser currentUser = ChatUser(id: '1', firstName: 'User');
  final ChatUser botUser = ChatUser(id: '2', firstName: 'Bot');

  List<ChatMessage> messages = [];
  List<ChatUser> typingUsers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        messages.add(ChatMessage(
          user: botUser,
          createdAt: DateTime.now(),
          text: "Hello! I'm your assistant. How can I help you today?",
        ));
      });
    });
  }

  void onSend(ChatMessage message) {
    setState(() {
      messages.insert(0, message);
      typingUsers.add(botUser);
    });
    getChatResponse(message);
  }

  Future<void> getChatResponse(ChatMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/chat'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message.text}),
      );

      String reply;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['response'];
      } else {
        reply = 'Error: ${response.statusCode}';
      }

      final ChatMessage botMessage = ChatMessage(
        user: botUser,
        createdAt: DateTime.now(),
        text: reply,
      );

      setState(() {
        typingUsers.remove(botUser);
        messages.insert(0, botMessage);
      });
    } catch (e) {
      setState(() {
        typingUsers.remove(botUser);
        messages.insert(
          0,
          ChatMessage(
            user: botUser,
            createdAt: DateTime.now(),
            text: 'Error: $e',
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFF336A29),
        title: const Text(
          'ChatBot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: DashChat(
        currentUser: currentUser,
        onSend: onSend,
        messages: messages,
        typingUsers: typingUsers,
        messageOptions: MessageOptions(
          currentUserContainerColor: const Color(0xFF336A29),
          containerColor: const Color.fromRGBO(0, 166, 126, 1),
          textColor: Colors.white,
          showTime: true,
          showOtherUsersAvatar: true,
          showCurrentUserAvatar: true,
          avatarBuilder: (user, onPress, onLongPress) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: user.id == currentUser.id
                    ? (isDarkMode ? Colors.grey[800] : Colors.grey.shade300)
                    : const Color.fromRGBO(0, 166, 126, 1),
                child: Icon(
                  user.id == currentUser.id ? Icons.person : Icons.smart_toy,
                  color: user.id == currentUser.id
                      ? (isDarkMode ? Colors.white : const Color(0xFF336A29))
                      : Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        ),
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: 'Ask me anything...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
            ),
            filled: true,
            fillColor:
                isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          sendButtonBuilder: (onSend) {
            return IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Color(0xFF336A29),
                size: 28,
              ),
              onPressed: onSend,
            );
          },
        ),
      ),
    );
  }
}
