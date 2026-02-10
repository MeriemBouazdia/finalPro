import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:app/consts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser currentUser = ChatUser(id: '1', firstName: 'User');
  final ChatUser gptUser = ChatUser(id: '2', firstName: 'GPT');

  List<ChatMessage> messages = [];
  List<ChatUser> typingUsers = [];

  @override
  void initState() {
    super.initState();
    /* OpenAI.apiKey = OPENAI_API_KEY;*/
    // Add welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        messages.add(
          ChatMessage(
            user: gptUser,
            createdAt: DateTime.now(),
            text: "Hello! I'm your AI assistant. How can I help you today?",
          ),
        );
      });
    });
  }

  void onSend(ChatMessage message) {
    setState(() {
      messages.insert(0, message);
      typingUsers.add(gptUser); // Show typing indicator
    });

    getChatResponse(message);
  }

  Future<void> getChatResponse(ChatMessage message) async {
    try {
      // Construire l'historique de conversation
      final conversationMessages = messages.reversed.map((m) {
        return OpenAIChatCompletionChoiceMessageModel(
          role: m.user.id == currentUser.id
              ? OpenAIChatMessageRole.user
              : OpenAIChatMessageRole.assistant,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(m.text),
          ],
        );
      }).toList();

      // UNE SEULE requête à OpenAI
      final response = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: conversationMessages,
        maxTokens: 500,
        temperature: 0.7,
      );

      final String reply =
          response.choices.first.message.content?.first.text ??
          "I apologize, but I couldn't generate a response. Please try again.";

      final ChatMessage gptMessage = ChatMessage(
        user: gptUser,
        createdAt: DateTime.now(),
        text: reply,
      );

      setState(() {
        typingUsers.remove(gptUser); // ← Retirer l'indicateur de frappe
        messages.insert(0, gptMessage);
      });
    } catch (e) {
      setState(() {
        typingUsers.remove(gptUser);
        messages.insert(
          0,
          ChatMessage(
            user: gptUser,
            createdAt: DateTime.now(),
            text:
                'Sorry, an error occurred: ${e.toString()}', // ← Message d'erreur réel
          ),
        );
      });
    }
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
        onSend: onSend,
        messages: messages,
        typingUsers: typingUsers,
        messageOptions: MessageOptions(
          currentUserContainerColor: const Color.fromARGB(255, 0, 100, 0),
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
                    ? Colors.grey.shade300
                    : const Color.fromRGBO(0, 166, 126, 1),
                child: Icon(
                  user.id == currentUser.id ? Icons.person : Icons.smart_toy,
                  color: user.id == currentUser.id
                      ? const Color.fromARGB(255, 0, 100, 0)
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
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
          ),
          sendButtonBuilder: (onSend) {
            return IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Color.fromARGB(255, 0, 100, 0),
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
