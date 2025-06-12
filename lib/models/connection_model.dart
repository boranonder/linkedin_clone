class ConnectionModel {
  final String id;
  final String userId;
  final String connectedUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final String createdAt;
  final String? userName;
  final String? userEmail;
  final String? userHeadline;
  final String? userImageUrl;
  final int? unreadCount; // For messaging feature

  ConnectionModel({
    required this.id,
    required this.userId,
    required this.connectedUserId,
    required this.status,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.userHeadline,
    this.userImageUrl,
    this.unreadCount,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'],
      userId: json['userId'],
      connectedUserId: json['connectedUserId'],
      status: json['status'],
      createdAt: json['createdAt'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userHeadline: json['userHeadline'],
      userImageUrl: json['userImageUrl'],
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'connectedUserId': connectedUserId,
      'status': status,
      'createdAt': createdAt,
      'userName': userName,
      'userEmail': userEmail,
      'userHeadline': userHeadline,
      'userImageUrl': userImageUrl,
      'unreadCount': unreadCount,
    };
  }
} 