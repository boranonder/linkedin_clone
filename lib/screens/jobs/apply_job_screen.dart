import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobId;

  const ApplyJobScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  JobModel? _job;
  File? _resume;
  bool _isLoading = false;

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
      final job = await Provider.of<JobProvider>(context, listen: false).getJobById(widget.jobId);
      if (mounted) {
        setState(() {
          _job = job;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İş detayları yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickResume() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _resume = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitApplication() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_resume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen CV yükleyin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<JobProvider>(context, listen: false).applyToJob(
        context,
        jobId: widget.jobId,
        resume: _resume,
        coverLetter: _coverLetterController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Başvurunuz başarıyla gönderildi')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başvuru yapılırken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Başvurusu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _job == null
              ? const Center(child: Text('İş ilanı bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İş bilgileri
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
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
                        
                        // CV yükleme
                        Text(
                          'CV Yükle (Gerekli)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickResume,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _resume != null ? Icons.check_circle : Icons.upload_file,
                                  size: 48,
                                  color: _resume != null ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _resume != null ? 'CV Seçildi' : 'CV Seçmek İçin Tıklayın',
                                  style: TextStyle(
                                    color: _resume != null ? Colors.green : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_resume != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _resume!.path.split('/').last,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Ön yazı
                        Text(
                          'Ön Yazı',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _coverLetterController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Bu pozisyon için neden uygun olduğunuzu açıklayın...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir ön yazı girin';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Başvur butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitApplication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'BAŞVUR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 