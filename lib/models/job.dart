class Job {
  final int id;
  final String title;
  final String description;
  final String company;
  final String location;
  final bool isRemote;
  final String employmentType;
  final double salary;
  final String postedByUserId;
  final String postedByUserName;
  final String postedByUserImage;
  final DateTime createdAt;
  final bool isActive;
  final int applicationCount;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    required this.location,
    required this.isRemote,
    required this.employmentType,
    required this.salary,
    required this.postedByUserId,
    required this.postedByUserName,
    required this.postedByUserImage,
    required this.createdAt,
    required this.isActive,
    this.applicationCount = 0,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      company: map['company'],
      location: map['location'],
      isRemote: map['is_remote'] == 1,
      employmentType: map['employment_type'],
      salary: map['salary'].toDouble(),
      postedByUserId: map['posted_by_user_id'],
      postedByUserName: map['posted_by_user_name'] ?? '',
      postedByUserImage: map['posted_by_user_image'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      isActive: map['is_active'] == 1,
      applicationCount: map['application_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'is_remote': isRemote ? 1 : 0,
      'employment_type': employmentType,
      'salary': salary,
      'posted_by_user_id': postedByUserId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }
} 