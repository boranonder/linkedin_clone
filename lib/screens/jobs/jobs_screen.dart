import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'job_detail_screen.dart';
import 'create_job_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<JobModel> _jobs = [];
  bool _isLoading = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    // Build aşaması tamamlandıktan sonra çalışmasını sağlayalım
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      List<JobModel> jobs;

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        jobs = await jobProvider.searchJobs(_searchQuery!);
      } else {
        jobs = await jobProvider.getAllJobs();
      }

      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İş ilanları yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'İş ilanlarında ara',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: _performSearch,
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery != null && _searchQuery!.isNotEmpty
                      ? '"${_searchQuery!}" için arama sonuçları'
                      : 'Tüm iş ilanları',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _jobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.work_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery != null && _searchQuery!.isNotEmpty
                                  ? 'Arama sonucu bulunamadı'
                                  : 'Henüz iş ilanı yok',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        child: ListView.builder(
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                            final job = _jobs[index];
                            return JobListItem(
                              job: job,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JobDetailScreen(jobId: job.id),
                                  ),
                                ).then((_) => _loadJobs());
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateJobScreen(),
            ),
          ).then((_) => _loadJobs());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class JobListItem extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobListItem({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                job.company,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    job.location,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              job.salary != null && job.salary!.isNotEmpty
                  ? Row(
                      children: [
                        const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          job.salary!,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      job.jobType,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(job.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    final DateTime dateTime = DateTime.parse(dateString);
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
} 