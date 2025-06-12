import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/job_model.dart';
import '../models/job_application_model.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class JobProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<JobModel> _jobs = [];
  List<JobModel> _myJobs = [];
  List<JobApplicationModel> _jobApplications = [];
  JobModel? _selectedJob;
  bool _isLoading = false;
  String _errorMessage = '';
  
  List<JobModel> get jobs => _jobs;
  List<JobModel> get myJobs => _myJobs;
  List<JobApplicationModel> get jobApplications => _jobApplications;
  JobModel? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  String getCurrentUserId(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }
    return authProvider.user!.id;
  }

  // İş İlanları Metodları

  Future<List<JobModel>> getAllJobs() async {
    try {
      _setLoading(true);
      
      final jobsData = await _databaseService.getAllJobs();
      final jobs = jobsData.map((job) => JobModel.fromJson(job)).toList();
      
      _jobs = jobs;
      _setLoading(false);
      return jobs;
    } catch (e) {
      _setError('İş ilanları yüklenirken hata oluştu: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<JobModel>> searchJobs(String query) async {
    try {
      _setLoading(true);
      
      final jobsData = await _databaseService.searchJobs(query);
      final jobs = jobsData.map((job) => JobModel.fromJson(job)).toList();
      
      _jobs = jobs;
      _setLoading(false);
      return jobs;
    } catch (e) {
      _setError('İş ilanları ararken hata oluştu: ${e.toString()}');
      rethrow;
    }
  }

  Future<JobModel?> getJobById(String jobId) async {
    try {
      final jobData = await _databaseService.getJobById(jobId);
      
      if (jobData == null) {
        return null;
      }
      
      _selectedJob = JobModel.fromJson(jobData);
      return _selectedJob;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<JobModel>> getUserJobs(BuildContext context) async {
    try {
      _setLoading(true);
      
      final userId = getCurrentUserId(context);
      final jobsData = await _databaseService.getUserJobs(userId);
      final jobs = jobsData.map((job) => JobModel.fromJson(job)).toList();
      
      _jobs = jobs;
      _setLoading(false);
      return jobs;
    } catch (e) {
      _setError('Kullanıcı iş ilanları yüklenirken hata oluştu: ${e.toString()}');
      rethrow;
    }
  }

  Future<JobModel> createJob(BuildContext context, {
    required String title,
    required String company,
    required String location,
    required String description,
    required String requirements,
    String? salary,
    required String jobType,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final userId = getCurrentUserId(context);
      
      final jobData = await _databaseService.createJob({
        'userId': userId,
        'title': title,
        'company': company,
        'location': location,
        'description': description,
        'requirements': requirements,
        'salary': salary,
        'jobType': jobType,
      });
      
      final job = JobModel.fromJson(jobData);
      
      _jobs.add(job);
      _selectedJob = job;
      
      _isLoading = false;
      notifyListeners();
      return job;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateJob(JobModel job) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _databaseService.updateJob(job.toJson());
      
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = job;
      }
      
      if (_selectedJob?.id == job.id) {
        _selectedJob = job;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _databaseService.deleteJob(jobId);
      
      _jobs.removeWhere((job) => job.id == jobId);
      if (_selectedJob?.id == jobId) {
        _selectedJob = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // İş Başvuruları Metodları

  Future<List<JobApplicationModel>> getJobApplications(String jobId) async {
    try {
      _setLoading(true);
      
      final applicationsData = await _databaseService.getJobApplications(jobId);
      final applications = applicationsData.map((app) => JobApplicationModel.fromJson(app)).toList();
      
      _jobApplications = applications;
      _setLoading(false);
      return applications;
    } catch (e) {
      _setError('Başvurular yüklenirken hata oluştu: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<JobApplicationModel>> getUserApplications(BuildContext context) async {
    try {
      _setLoading(true);
      
      final userId = getCurrentUserId(context);
      final applicationsData = await _databaseService.getUserApplications(userId);
      final applications = applicationsData.map((app) => JobApplicationModel.fromJson(app)).toList();
      
      _jobApplications = applications;
      _setLoading(false);
      return applications;
    } catch (e) {
      _setError('Kullanıcı başvuruları yüklenirken hata oluştu: ${e.toString()}');
      rethrow;
    }
  }

  Future<JobApplicationModel> applyToJob(BuildContext context, {
    required String jobId,
    required File? resume,
    required String? coverLetter,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final userId = getCurrentUserId(context);
      
      // Zaten başvurulmuş mu kontrol et
      final hasApplied = await _databaseService.hasUserApplied(userId, jobId);
      if (hasApplied) {
        throw Exception('Bu iş ilanına zaten başvurdunuz');
      }
      
      String? resumePath;
      
      // CV dosyasını kaydet
      if (resume != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'cv_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(resume.path)}';
        final savedResume = await resume.copy('${directory.path}/$fileName');
        resumePath = savedResume.path;
      }
      
      final applicationData = await _databaseService.createJobApplication({
        'jobId': jobId,
        'userId': userId,
        'resumePath': resumePath,
        'coverLetter': coverLetter,
      });
      
      final application = JobApplicationModel.fromJson(applicationData);
      
      _jobApplications.add(application);
      
      _isLoading = false;
      notifyListeners();
      return application;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _databaseService.updateJobApplicationStatus(applicationId, status);
      
      final index = _jobApplications.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        _jobApplications[index] = _jobApplications[index].copyWith(status: status);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> hasUserApplied(BuildContext context, String jobId) async {
    try {
      final userId = getCurrentUserId(context);
      return await _databaseService.hasUserApplied(userId, jobId);
    } catch (e) {
      rethrow;
    }
  }

  // Admin için iş başvurusu silme
  Future<void> deleteJobApplication(String applicationId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _databaseService.deleteJobApplication(applicationId);
      
      _jobApplications.removeWhere((app) => app.id == applicationId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void clearSelectedJob() {
    _selectedJob = null;
    notifyListeners();
  }
} 