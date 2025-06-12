import 'dart:io';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final String createdAt;
  final List<String> likes;
  final String userName;
  final String? userProfileImage;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.likes,
    required this.userName,
    this.userProfileImage,
  });

  File? get image => imageUrl != null ? File(imageUrl!) : null;

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'likes': likes,
      'userName': userName,
      'userProfileImage': userProfileImage,
    };
  }

  // Create model from JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'],
      likes: List<String>.from(json['likes'] ?? []),
      userName: json['userName'] ?? 'Kullanıcı',
      userProfileImage: json['userProfileImage'],
    );
  }

  // Create a copy of the model with updated fields
  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    String? createdAt,
    List<String>? likes,
    String? userName,
    String? userProfileImage,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
    );
  }
} 