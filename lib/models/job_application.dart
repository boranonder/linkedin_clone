class JobApplication {
  final int id;
  final int jobId;
  final String userId;
  final String coverLetter;
  final String status; // 'pending', 'reviewed', 'accepted', 'rejected'
  final DateTime appliedAt;
  
  // İsteğe bağlı alanlar - UI görüntüleme için
  final String? jobTitle;
  final String? companyName;
  final String? applicantName;
  final String? applicantImage;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.coverLetter,
    required this.status,
    required this.appliedAt,
    this.jobTitle,
    this.companyName,
    this.applicantName,
    this.applicantImage,
  });

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'],
      jobId: map['job_id'],
      userId: map['user_id'],
      coverLetter: map['cover_letter'],
      status: map['status'],
      appliedAt: DateTime.parse(map['applied_at']),
      jobTitle: map['job_title'],
      companyName: map['company_name'],
      applicantName: map['applicant_name'],
      applicantImage: map['applicant_image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'user_id': userId,
      'cover_letter': coverLetter,
      'status': status,
      'applied_at': appliedAt.toIso8601String(),
    };
  }
} 