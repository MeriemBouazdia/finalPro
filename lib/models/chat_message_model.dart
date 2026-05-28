import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String sender; // "user" or "bot"
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  /// Convert ChatMessage to a Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create ChatMessage from Firebase document snapshot
  factory ChatMessage.fromFirestore(String docId, Map<String, dynamic> data) {
    return ChatMessage(
      id: docId,
      text: data['text'] as String? ?? '',
      sender: data['sender'] as String? ?? 'bot',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create ChatMessage from a Map (for manual construction)
  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      text: data['text'] as String? ?? '',
      sender: data['sender'] as String? ?? 'bot',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] is DateTime
              ? data['timestamp'] as DateTime
              : DateTime.now()),
    );
  }

  @override
  String toString() =>
      'ChatMessage(id: $id, sender: $sender, timestamp: $timestamp)';
}
