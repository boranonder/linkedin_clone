class JobApplicationModel {
  final String id;
  final String jobId;
  final String userId;
  final String? resumePath;
  final String? coverLetter;
  final String status; // "pending", "accepted", "rejected"
  final String createdAt;
  final String updatedAt;
  
  // Join fields
  final String? jobTitle;
  final String? company;
  final String? applicantName;
  final String? applicantImage;
  final String? userEmail;

  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.userId,
    this.resumePath,
    this.coverLetter,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.jobTitle,
    this.company,
    this.applicantName,
    this.applicantImage,
    this.userEmail,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'userId': userId,
      'resumePath': resumePath,
      'coverLetter': coverLetter,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create model from JSON
  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'],
      jobId: json['jobId'],
      userId: json['userId'],
      resumePath: json['resumePath'],
      coverLetter: json['coverLetter'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      jobTitle: json['jobTitle'],
      company: json['company'],
      applicantName: json['applicantName'],
      applicantImage: json['applicantImage'],
      userEmail: json['userEmail'],
    );
  }

  // Create a copy of the model with updated fields
  JobApplicationModel copyWith({
    String? id,
    String? jobId,
    String? userId,
    String? resumePath,
    String? coverLetter,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? jobTitle,
    String? company,
    String? applicantName,
    String? applicantImage,
    String? userEmail,
  }) {
    return JobApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      resumePath: resumePath ?? this.resumePath,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      applicantName: applicantName ?? this.applicantName,
      applicantImage: applicantImage ?? this.applicantImage,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  // Get status text
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      case 'reviewed':
        return 'İncelendi';
      default:
        return 'Beklemede';
    }
  }

  // Get status color
  int get statusColor {
    switch (status) {
      case 'pending':
        return 0xFFFFA000; // Turuncu
      case 'accepted':
        return 0xFF4CAF50; // Yeşil
      case 'rejected':
        return 0xFFF44336; // Kırmızı
      case 'reviewed':
        return 0xFF2196F3; // Mavi
      default:
        return 0xFFFFA000; // Turuncu
    }
  }
} 