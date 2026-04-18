import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'widget/theme_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Interpreter? interpreter; // ✅ Nullable instead of late
  bool _isModelLoaded = false; // ✅ Track loading state

  final types.User _currentUser = types.User(id: '1', firstName: 'User');
  final types.User _botUser = types.User(id: '2', firstName: 'Bot');

  final List<types.TextMessage> _messages = [];
  bool _isBotTyping = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> loadModel() async {
    try {
      final loaded =
          await Interpreter.fromAsset('assets/models/crop_recommendation_model.tflite');
      setState(() {
        interpreter = loaded;
        _isModelLoaded = true; // ✅ Mark ready only after successful load
      });
    } catch (e) {
      // Show error in chat if model fails to load
      setState(() {
        _messages.insert(
          0,
          types.TextMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            author: _botUser,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: 'Failed to load model: $e',
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.insert(
          0,
          types.TextMessage(
            id: 'init',
            author: _botUser,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: "Hello! I'm your assistant 🌱",
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    interpreter?.close(); // ✅ Safe null-aware close
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String text) {
    // ✅ Guard: do nothing if model isn't loaded yet
    if (!_isModelLoaded || interpreter == null) {
      setState(() {
        _messages.insert(
          0,
          types.TextMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            author: _botUser,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: 'Model is still loading, please wait a moment...',
          ),
        );
      });
      return;
    }

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

    _runModel();
  }

  void _runModel() {
    try {
      List<double> input = [90, 40, 40, 25, 60, 6.5, 200];

      var output = List.generate(1, (_) => List.filled(1, 0.0));

      interpreter!.run([input], output); 

      int index = output[0][0].toInt();

      List<String> crops = [
        "Rice 🌾",
        "Maize 🌽",
        "Chickpea 🌱",
        "Kidney Beans 🫘",
        "Pigeon Peas 🌿",
      ];

      String reply =
          (index >= 0 && index < crops.length) ? crops[index] : "Unknown crop";

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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message.text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFF336A29),
        title: const Text("ChatBot"),
        // ✅ Show a loading indicator in the AppBar while model loads
        actions: [
          if (!_isModelLoaded)
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Optional banner while model is loading
          if (!_isModelLoaded)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const Text(
                '⏳ Loading model, please wait...',
                style: TextStyle(color: Colors.orange, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.author.id == _currentUser.id;
                return _buildMessageBubble(msg, isMe, isDarkMode);
              },
            ),
          ),
          // ✅ Typing indicator
          if (_isBotTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bot is typing...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Ask something...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _handleSendMessage(value);
                        _messageController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    // ✅ Grey out button while model is loading
                    color:
                        _isModelLoaded ? const Color(0xFF336A29) : Colors.grey,
                  ),
                  // ✅ Disable button until model is ready
                  onPressed: _isModelLoaded
                      ? () {
                          if (_messageController.text.isNotEmpty) {
                            _handleSendMessage(_messageController.text);
                            _messageController.clear();
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
