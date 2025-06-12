import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'job_detail_screen.dart';
import 'create_job_screen.dart';
import 'job_applications_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<JobModel> _jobs = [];
  List<JobModel> _inactiveJobs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await Provider.of<JobProvider>(context, listen: false).getUserJobs(context);
      
      setState(() {
        _jobs = jobs.where((job) => job.isActive).toList();
        _inactiveJobs = jobs.where((job) => !job.isActive).toList();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Aktif İlanlar'),
                  Tab(text: 'Kapalı İlanlar'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Aktif İlanlar Tab
                _jobs.isEmpty
                    ? _buildEmptyState('Henüz aktif iş ilanınız yok', true)
                    : _buildJobList(_jobs, true),
                
                // Kapalı İlanlar Tab
                _inactiveJobs.isEmpty
                    ? _buildEmptyState('Kapalı iş ilanınız yok', false)
                    : _buildJobList(_inactiveJobs, false),
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

  Widget _buildEmptyState(String message, bool showAddButton) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (showAddButton) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateJobScreen(),
                  ),
                ).then((_) => _loadJobs());
              },
              icon: const Icon(Icons.add),
              label: const Text('Yeni İlan Oluştur'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobList(List<JobModel> jobs, bool isActive) {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.company),
                      Text('${job.location} • ${job.jobType}'),
                      if (job.salary != null && job.salary!.isNotEmpty)
                        Text('Maaş: ${job.salary}'),
                    ],
                  ),
                  trailing: Text(
                    _formatDate(job.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailScreen(
                          jobId: job.id,
                          isMyJob: true,
                        ),
                      ),
                    ).then((_) => _loadJobs());
                  },
                ),
                const Divider(height: 0),
                ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobApplicationsScreen(jobId: job.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people, size: 20),
                      label: const Text('Başvurular'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _toggleJobStatus(job);
                      },
                      icon: Icon(
                        isActive ? Icons.close : Icons.refresh,
                        size: 20,
                        color: isActive ? Colors.red : Colors.green,
                      ),
                      label: Text(
                        isActive ? 'İlanı Kapat' : 'İlanı Aç',
                        style: TextStyle(
                          color: isActive ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleJobStatus(JobModel job) async {
    final updatedJob = job.copyWith(isActive: !job.isActive);
    
    try {
      await Provider.of<JobProvider>(context, listen: false).updateJob(updatedJob);
      _loadJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İlan durumu güncellenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
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