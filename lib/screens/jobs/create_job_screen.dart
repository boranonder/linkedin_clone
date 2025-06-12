import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _salaryController = TextEditingController();
  String _jobType = 'Tam Zamanlı';
  bool _isLoading = false;

  final List<String> _jobTypes = [
    'Tam Zamanlı',
    'Yarı Zamanlı',
    'Uzaktan',
    'Staj',
    'Proje Bazlı',
    'Sözleşmeli',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<JobProvider>(context, listen: false).createJob(
        context,
        title: _titleController.text,
        company: _companyController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        requirements: _requirementsController.text,
        salary: _salaryController.text.isEmpty ? null : _salaryController.text,
        jobType: _jobType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş ilanı başarıyla oluşturuldu')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İş ilanı oluşturulurken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş İlanı Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İş Başlığı
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'İş Başlığı *',
                  hintText: 'Örn: Flutter Geliştirici',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'İş başlığı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Şirket
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Şirket *',
                  hintText: 'Örn: TechCo',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şirket adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Konum
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum *',
                  hintText: 'Örn: İstanbul, Türkiye',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konum gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // İş Türü
              DropdownButtonFormField<String>(
                value: _jobType,
                decoration: const InputDecoration(
                  labelText: 'İş Türü *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _jobTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _jobType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Maaş (Opsiyonel)
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Maaş (Opsiyonel)',
                  hintText: 'Örn: 20,000 - 30,000 TL',
                  prefixIcon: Icon(Icons.monetization_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // İş Açıklaması
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'İş Açıklaması *',
                  hintText: 'İş pozisyonu hakkında detaylı bilgi...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'İş açıklaması gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gereksinimler
              TextFormField(
                controller: _requirementsController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Gereksinimler *',
                  hintText: 'Gerekli beceriler, deneyim, eğitim vs...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Gereksinimler gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Önizleme
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Önizleme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(
                      _titleController.text.isEmpty ? 'İş Başlığı' : _titleController.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _companyController.text.isEmpty ? 'Şirket Adı' : _companyController.text,
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
                          _locationController.text.isEmpty ? 'Konum' : _locationController.text,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _jobType,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (_salaryController.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _salaryController.text,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Oluştur Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'İLANI YAYINLA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 