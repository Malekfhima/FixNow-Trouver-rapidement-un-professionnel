import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.read = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read,
    };
  }
}

class Chat {
  final String id;
  final String clientId;
  final String proId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const Chat({
    required this.id,
    required this.clientId,
    required this.proId,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      proId: data['proId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'proId': proId,
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    };
  }
}
