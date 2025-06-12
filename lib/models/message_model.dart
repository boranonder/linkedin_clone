class Message {
  final int id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? senderName;
  final String? senderImageUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.senderName,
    this.senderImageUrl,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['is_read'] == 1,
      senderName: map['sender_name'],
      senderImageUrl: map['sender_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }
}

class Conversation {
  final String userId;
  final String userName;
  final String? userImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.userId,
    required this.userName,
    this.userImage,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      userId: map['user_id'],
      userName: map['user_name'],
      userImage: map['user_image'],
      lastMessage: map['last_message'],
      lastMessageTime: DateTime.parse(map['last_message_time']),
      unreadCount: map['unread_count'] ?? 0,
    );
  }
} 