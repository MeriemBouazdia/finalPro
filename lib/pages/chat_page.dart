import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'widget/theme_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final types.User _currentUser = types.User(id: '1', firstName: 'User');
  final types.User _botUser = types.User(id: '2', firstName: 'Bot');

  final List<types.TextMessage> _messages = [];
  bool _isBotTyping = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.insert(
          0,
          types.TextMessage(
            id: 'init',
            author: _botUser,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: "Hello! I'm your assistant. How can I help you today?",
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String text) {
    final textMessage = types.TextMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: text,
    );

    setState(() {
      _messages.insert(0, textMessage);
      _isBotTyping = true;
    });

    _getChatResponse(textMessage);
  }

  Future<void> _getChatResponse(types.TextMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.6:5000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_input": message.text,
          "sensor_data": {
            "temperature": 25,
            "humidity": 60,
            "light": 20000,
            "soil": 50
          }
        }),
      );

      String reply;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['response'];
      } else {
        reply = 'Error: ${response.statusCode}';
      }

      final botMessage = types.TextMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        author: _botUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        text: reply,
      );

      setState(() {
        _isBotTyping = false;
        _messages.insert(0, botMessage);
      });
    } catch (e) {
      setState(() {
        _isBotTyping = false;
        _messages.insert(
          0,
          types.TextMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            author: _botUser,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: 'Error: $e',
          ),
        );
      });
    }
  }

  Widget _buildAvatar(types.User author, bool isDarkMode) {
    final isUser = author.id == _currentUser.id;
    return CircleAvatar(
      radius: 18,
      backgroundColor: isUser
          ? (isDarkMode ? Colors.grey[800] : Colors.grey.shade300)
          : const Color.fromRGBO(0, 166, 126, 1),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser
            ? (isDarkMode ? Colors.white : const Color(0xFF336A29))
            : Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildMessageBubble(
      types.TextMessage message, bool isMe, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 60 : 16,
        right: isMe ? 16 : 60,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF336A29) : const Color(0xFF00A67E),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft:
              isMe ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight:
              isMe ? const Radius.circular(4) : const Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(message.createdAt ?? 0),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInputArea(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF3C3C3C) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _handleSendMessage(value.trim());
                  _messageController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF336A29),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              onPressed: () {
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  _handleSendMessage(text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 60, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00A67E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDot(delay: 0, isDarkMode: isDarkMode),
          const SizedBox(width: 4),
          _TypingDot(delay: 0.2, isDarkMode: isDarkMode),
          const SizedBox(width: 4),
          _TypingDot(delay: 0.4, isDarkMode: isDarkMode),
        ],
      ),
    );
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isBotTyping && index == _messages.length) {
                  return _buildTypingIndicator(isDarkMode);
                }

                final message = _messages[index];
                final isMe = message.author.id == _currentUser.id;
                return Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe) _buildAvatar(message.author, isDarkMode),
                    _buildMessageBubble(message, isMe, isDarkMode),
                  ],
                );
              },
            ),
          ),
          _buildInputArea(isDarkMode),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final double delay;
  final bool isDarkMode;

  const _TypingDot({required this.delay, required this.isDarkMode});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = (_controller.value + widget.delay) % 1.0;
        final opacity = offset < 0.5 ? offset * 2 : (1.0 - offset) * 2;
        return Opacity(
          opacity: opacity.clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
