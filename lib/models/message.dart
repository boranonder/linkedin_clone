class Message {
  final int id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  
  // UI için ek alanlar (opsiyonel)
  final String? senderName;
  final String? senderImage;
  final String? receiverName;
  final String? receiverImage;
  
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.senderName,
    this.senderImage,
    this.receiverName,
    this.receiverImage,
  });
  
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['is_read'] == 1,
      senderName: map['sender_name'] as String?,
      senderImage: map['sender_image'] as String?,
      receiverName: map['receiver_name'] as String?,
      receiverImage: map['receiver_image'] as String?,
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