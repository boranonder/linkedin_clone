import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class EducationForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function? onSuccess;

  const EducationForm({super.key, this.initialData, this.onSuccess});

  @override
  State<EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends State<EducationForm> {
  final _formKey = GlobalKey<FormState>();
  final _schoolController = TextEditingController();
  final _degreeController = TextEditingController();
  final _fieldController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isCurrentlyStudying = false;
  bool _isLoading = false;
  String? _educationId;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _schoolController.text = widget.initialData!['school'] ?? '';
      _degreeController.text = widget.initialData!['degree'] ?? '';
      _fieldController.text = widget.initialData!['field'] ?? '';
      _startDateController.text = widget.initialData!['startDate'] ?? '';
      _endDateController.text = widget.initialData!['endDate'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _educationId = widget.initialData!['id'];
      _isCurrentlyStudying = widget.initialData!['endDate'] == 'Devam Ediyor';
    }
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
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

  Future<void> _saveEducation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final endDate = _isCurrentlyStudying ? 'Devam Ediyor' : _endDateController.text;

        if (_educationId != null) {
          // Mevcut eğitim bilgisini güncelle
          final user = await userProvider.getUserData(userId);
          final education = List<Map<String, dynamic>>.from(user['education']);
          final index = education.indexWhere((e) => e['id'] == _educationId);
          if (index != -1) {
            education[index] = {
              'id': _educationId,
              'school': _schoolController.text,
              'degree': _degreeController.text,
              'field': _fieldController.text,
              'startDate': _startDateController.text,
              'endDate': endDate,
              'description': _descriptionController.text,
            };
            await userProvider.updateProfile(
              userId: userId,
              education: education,
            );
          }
        } else {
          // Yeni eğitim bilgisi ekle
          await userProvider.addEducation(
            userId: userId,
            school: _schoolController.text,
            degree: _degreeController.text,
            field: _fieldController.text,
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
        title: Text(_educationId != null ? 'Eğitim Düzenle' : 'Eğitim Ekle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveEducation,
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
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'Okul *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen okul adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _degreeController,
                decoration: const InputDecoration(
                  labelText: 'Derece',
                  border: OutlineInputBorder(),
                  hintText: 'Lisans, Yüksek Lisans, vb.',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fieldController,
                decoration: const InputDecoration(
                  labelText: 'Alan/Bölüm',
                  border: OutlineInputBorder(),
                  hintText: 'Bilgisayar Mühendisliği, İşletme, vb.',
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
                      onTap: _isCurrentlyStudying ? null : () => _selectDate(context, _endDateController),
                      enabled: !_isCurrentlyStudying,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isCurrentlyStudying,
                    onChanged: (value) {
                      setState(() {
                        _isCurrentlyStudying = value ?? false;
                        if (_isCurrentlyStudying) {
                          _endDateController.text = 'Devam Ediyor';
                        } else {
                          _endDateController.text = '';
                        }
                      });
                    },
                  ),
                  const Text('Halen okuyorum'),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  hintText: 'Aktiviteler, başarılar, vb.',
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
                    onPressed: _saveEducation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _educationId != null ? 'Güncelle' : 'Ekle',
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