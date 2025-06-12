import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'apply_job_screen.dart';
import 'job_applications_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  final bool isMyJob;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    this.isMyJob = false,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobModel? _job;
  bool _isLoading = false;
  bool _hasApplied = false;

  @override
  void initState() {
    super.initState();
    // Build aşaması tamamlandıktan sonra çalışmasını sağlayalım
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobDetails();
    });
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      final job = await jobProvider.getJobById(widget.jobId);
      
      if (job != null) {
        setState(() {
          _job = job;
        });

        if (!widget.isMyJob) {
          final hasApplied = await jobProvider.hasUserApplied(context, widget.jobId);
          setState(() {
            _hasApplied = hasApplied;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İş ilanı detayları yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Detayları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _job == null
              ? const Center(child: Text('İş ilanı bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İş başlığı
                      Text(
                        _job!.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Şirket ve konum
                      Row(
                        children: [
                          Icon(Icons.business, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            _job!.company,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Konum
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            _job!.location,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // İş türü
                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            _job!.jobType,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      
                      // Maaş (varsa)
                      if (_job!.salary != null && _job!.salary!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.monetization_on, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              _job!.salary!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // İş Açıklaması
                      Text(
                        'İş Açıklaması',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _job!.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Gereksinimler
                      Text(
                        'Gereksinimler',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _job!.requirements,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // İlan Tarihi
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'İlan Tarihi: ${_formatDate(_job!.createdAt)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      bottomNavigationBar: _job == null
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: widget.isMyJob
                  ? ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobApplicationsScreen(jobId: widget.jobId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people),
                      label: const Text('Başvuruları Görüntüle'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  : _hasApplied
                      ? ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check),
                          label: const Text('Başvuru Yapıldı'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: Colors.green.withOpacity(0.7),
                            disabledForegroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplyJobScreen(jobId: widget.jobId),
                              ),
                            ).then((_) => _loadJobDetails());
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Başvur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
            ),
    );
  }

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    
    return '$day/$month/$year';
  }
} 