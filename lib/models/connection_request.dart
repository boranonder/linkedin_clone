class ConnectionRequest {
  final int id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final DateTime createdAt;
  final String userName;
  final String? userImage;
  final String? headline;

  ConnectionRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.userName,
    this.userImage,
    this.headline,
  });

  factory ConnectionRequest.fromMap(Map<String, dynamic> map) {
    return ConnectionRequest(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      userName: map['user_name'],
      userImage: map['user_image'],
      headline: map['headline'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_image': userImage,
      'headline': headline,
    };
  }
} 