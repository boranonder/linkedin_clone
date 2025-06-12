class UserModel {
  final String id;
  final String fullName;
  final String email;
  String bio;
  String profileImage;
  final String createdAt;
  String location;
  List<Map<String, dynamic>> education;
  List<Map<String, dynamic>> experience;
  List<String> skills;
  bool isAdmin;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.bio = '',
    this.profileImage = '',
    required this.createdAt,
    this.location = '',
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.isAdmin = false,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'profileImage': profileImage,
      'createdAt': createdAt,
      'location': location,
      'education': education,
      'experience': experience,
      'skills': skills,
      'isAdmin': isAdmin,
    };
  }

  // Create model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      bio: json['bio'] ?? '',
      profileImage: json['profileImage'] ?? '',
      createdAt: json['createdAt'],
      location: json['location'] ?? '',
      education: json['education'] != null 
          ? List<Map<String, dynamic>>.from(json['education'])
          : [],
      experience: json['experience'] != null 
          ? List<Map<String, dynamic>>.from(json['experience'])
          : [],
      skills: json['skills'] != null 
          ? List<String>.from(json['skills'])
          : [],
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  // Create a copy of the model with updated fields
  UserModel copyWith({
    String? fullName,
    String? email,
    String? bio,
    String? profileImage,
    String? location,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<String>? skills,
    bool? isAdmin,
  }) {
    return UserModel(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      createdAt: this.createdAt,
      location: location ?? this.location,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
} 