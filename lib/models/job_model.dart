class JobModel {
  final String id;
  final String userId;
  final String title;
  final String company;
  final String location;
  final String description;
  final String requirements;
  final String? salary;
  final String jobType;
  final String createdAt;
  final bool isActive;
  
  // Ekstra bilgiler
  final String? userName;
  final String? userImage;

  JobModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.requirements,
    this.salary,
    required this.jobType,
    required this.createdAt,
    required this.isActive,
    this.userName,
    this.userImage,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'requirements': requirements,
      'salary': salary,
      'jobType': jobType,
      'createdAt': createdAt,
      'isActive': isActive ? 1 : 0,
      'userName': userName,
      'userImage': userImage,
    };
  }

  // Create model from JSON
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      company: json['company'],
      location: json['location'],
      description: json['description'],
      requirements: json['requirements'],
      salary: json['salary'],
      jobType: json['jobType'],
      createdAt: json['createdAt'],
      isActive: json['isActive'] == 1,
      userName: json['userName'],
      userImage: json['userImage'],
    );
  }

  // Create a copy of the model with updated fields
  JobModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? company,
    String? location,
    String? description,
    String? requirements,
    String? salary,
    String? jobType,
    String? createdAt,
    bool? isActive,
    String? userName,
    String? userImage,
  }) {
    return JobModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      salary: salary ?? this.salary,
      jobType: jobType ?? this.jobType,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
    );
  }
} 