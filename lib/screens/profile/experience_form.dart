import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class ExperienceForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function? onSuccess;

  const ExperienceForm({super.key, this.initialData, this.onSuccess});

  @override
  State<ExperienceForm> createState() => _ExperienceFormState();
}

class _ExperienceFormState extends State<ExperienceForm> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isCurrentlyWorking = false;
  bool _isLoading = false;
  String? _experienceId;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _companyController.text = widget.initialData!['company'] ?? '';
      _titleController.text = widget.initialData!['title'] ?? '';
      _locationController.text = widget.initialData!['location'] ?? '';
      _startDateController.text = widget.initialData!['startDate'] ?? '';
      _endDateController.text = widget.initialData!['endDate'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _experienceId = widget.initialData!['id'];
      _isCurrentlyWorking = widget.initialData!['endDate'] == 'Devam Ediyor';
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveExperience() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final endDate = _isCurrentlyWorking ? 'Devam Ediyor' : _endDateController.text;

        if (_experienceId != null) {
          // Mevcut deneyimi güncelle
          final user = await userProvider.getUserData(userId);
          final experience = List<Map<String, dynamic>>.from(user['experience']);
          final index = experience.indexWhere((e) => e['id'] == _experienceId);
          if (index != -1) {
            experience[index] = {
              'id': _experienceId,
              'company': _companyController.text,
              'title': _titleController.text,
              'location': _locationController.text,
              'startDate': _startDateController.text,
              'endDate': endDate,
              'description': _descriptionController.text,
            };
            await userProvider.updateProfile(
              userId: userId,
              experience: experience,
            );
          }
        } else {
          // Yeni deneyim ekle
          await userProvider.addExperience(
            userId: userId,
            company: _companyController.text,
            title: _titleController.text,
            location: _locationController.text,
            startDate: _startDateController.text,
            endDate: endDate,
            description: _descriptionController.text,
          );
        }

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_experienceId != null ? 'İş Deneyimi Düzenle' : 'İş Deneyimi Ekle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveExperience,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Unvan *',
                  border: OutlineInputBorder(),
                  hintText: 'Örn: Yazılım Mühendisi',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen unvan girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Şirket *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şirket adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum',
                  border: OutlineInputBorder(),
                  hintText: 'Örn: İstanbul, Türkiye',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Başlangıç Tarihi',
                        border: OutlineInputBorder(),
                        hintText: 'Ay/Yıl',
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _startDateController),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'Bitiş Tarihi',
                        border: OutlineInputBorder(),
                        hintText: 'Ay/Yıl',
                      ),
                      readOnly: true,
                      onTap: _isCurrentlyWorking ? null : () => _selectDate(context, _endDateController),
                      enabled: !_isCurrentlyWorking,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isCurrentlyWorking,
                    onChanged: (value) {
                      setState(() {
                        _isCurrentlyWorking = value ?? false;
                        if (_isCurrentlyWorking) {
                          _endDateController.text = 'Devam Ediyor';
                        } else {
                          _endDateController.text = '';
                        }
                      });
                    },
                  ),
                  const Text('Halen çalışıyorum'),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  hintText: 'Sorumluluklar, başarılar, vb.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveExperience,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _experienceId != null ? 'Güncelle' : 'Ekle',
                      style: const TextStyle(fontSize: 16),
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