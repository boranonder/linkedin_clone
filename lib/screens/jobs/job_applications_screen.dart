import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_model.dart';
import '../../models/job_application_model.dart';

class JobApplicationsScreen extends StatefulWidget {
  final String jobId;

  const JobApplicationsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  JobModel? _job;
  List<JobApplicationModel> _applications = [];
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // Build aşaması tamamlandıktan sonra çalışmasını sağlayalım
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus();
      _loadApplications();
    });
  }
  
  void _checkAdminStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      setState(() {
        _isAdmin = authProvider.user!.isAdmin;
      });
    }
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      
      // İş detaylarını yükle
      final job = await jobProvider.getJobById(widget.jobId);
      
      // Başvuruları yükle
      final applications = await jobProvider.getJobApplications(widget.jobId);
      
      if (mounted) {
        setState(() {
          _job = job;
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başvurular yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String status) async {
    try {
      await Provider.of<JobProvider>(context, listen: false)
          .updateApplicationStatus(applicationId, status);
      
      await _loadApplications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başvuru durumu güncellenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Başvurular'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // İş bilgileri
                if (_job != null)
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _job!.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _job!.company,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _job!.location,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Başvuru sayısı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Toplam ${_applications.length} başvuru',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Başvuru listesi
                Expanded(
                  child: _applications.isEmpty
                      ? const Center(
                          child: Text('Henüz başvuru yapılmamış'),
                        )
                      : ListView.builder(
                          itemCount: _applications.length,
                          itemBuilder: (context, index) {
                            final application = _applications[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundImage: application.applicantImage != null && application.applicantImage!.isNotEmpty
                                      ? FileImage(File(application.applicantImage!))
                                      : null,
                                  child: application.applicantImage == null || application.applicantImage!.isEmpty
                                      ? Text(application.applicantName?[0].toUpperCase() ?? '?')
                                      : null,
                                ),
                                title: Text(
                                  application.applicantName ?? 'İsimsiz Kullanıcı',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (application.userEmail != null)
                                      Text(application.userEmail!),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(application.statusColor).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        application.statusText,
                                        style: TextStyle(
                                          color: Color(application.statusColor),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: _isAdmin ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    // Admin için başvuru silme işlevi
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Başvuruyu Sil'),
                                        content: const Text('Bu başvuruyu silmek istediğinizden emin misiniz?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('İptal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    
                                    if (confirm == true) {
                                      try {
                                        await Provider.of<JobProvider>(context, listen: false)
                                            .deleteJobApplication(application.id);
                                        _loadApplications(); // Listeyi yenile
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Başvuru silindi')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Başvuru silinirken hata: $e')),
                                        );
                                      }
                                    }
                                  },
                                ) : null,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ön Yazı:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(application.coverLetter ?? 'Ön yazı yok'),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'CV:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (application.resumePath != null && application.resumePath!.isNotEmpty)
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              // CV dosyasını göster/indir
                                            },
                                            icon: const Icon(Icons.file_present),
                                            label: const Text('CV\'yi Görüntüle'),
                                          )
                                        else
                                          const Text('CV yok'),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Durum Güncelle:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            if (application.status != 'accepted')
                                              ElevatedButton.icon(
                                                onPressed: () => _updateApplicationStatus(application.id, 'accepted'),
                                                icon: const Icon(Icons.check, size: 16),
                                                label: const Text('Kabul Et', style: TextStyle(fontSize: 12)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                  minimumSize: const Size(80, 36),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                            if (application.status != 'rejected')
                                              ElevatedButton.icon(
                                                onPressed: () => _updateApplicationStatus(application.id, 'rejected'),
                                                icon: const Icon(Icons.close, size: 16),
                                                label: const Text('Reddet', style: TextStyle(fontSize: 12)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                  minimumSize: const Size(80, 36),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                            if (application.status != 'reviewed')
                                              ElevatedButton.icon(
                                                onPressed: () => _updateApplicationStatus(application.id, 'reviewed'),
                                                icon: const Icon(Icons.visibility, size: 16),
                                                label: const Text('İncelendi', style: TextStyle(fontSize: 12)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                  minimumSize: const Size(80, 36),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 