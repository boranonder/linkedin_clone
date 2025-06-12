import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import 'education_form.dart';
import 'experience_form.dart';
import 'skills_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = widget.userId ??
          Provider.of<AuthProvider>(context, listen: false).user!.id;
      final userData =
          await Provider.of<UserProvider>(context, listen: false).getUserData(userId);
      setState(() {
        _userData = userData;
        _bioController.text = userData['bio'] ?? '';
        _locationController.text = userData['location'] ?? '';
      });
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

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
        await Provider.of<UserProvider>(context, listen: false).updateProfile(
          userId: userId,
          bio: _bioController.text,
          location: _locationController.text,
        );
        
        // Profil güncelleştikten sonra verileri yeniden yükle
        await _loadUserData();
        
        setState(() {
          _isEditing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profil güncellenirken hata: ${e.toString()}')),
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

  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
        await Provider.of<UserProvider>(context, listen: false).updateProfile(
          userId: userId,
          profileImage: File(pickedFile.path),
        );
        await _loadUserData();
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

  void _navigateToEducationForm([Map<String, dynamic>? initialData]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationForm(
          initialData: initialData,
          onSuccess: _loadUserData,
        ),
      ),
    );
  }

  void _navigateToExperienceForm([Map<String, dynamic>? initialData]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperienceForm(
          initialData: initialData,
          onSuccess: _loadUserData,
        ),
      ),
    );
  }

  void _navigateToSkillsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SkillsScreen(),
      ),
    ).then((_) => _loadUserData());
  }

  Future<void> _removeEducation(String educationId) async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
      await Provider.of<UserProvider>(context, listen: false).removeEducation(
        userId: userId,
        educationId: educationId,
      );
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeExperience(String experienceId) async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
      await Provider.of<UserProvider>(context, listen: false).removeExperience(
        userId: userId,
        experienceId: experienceId,
      );
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı bulunamadı')),
      );
    }

    final isCurrentUser = widget.userId == null ||
        widget.userId ==
            Provider.of<AuthProvider>(context, listen: false).user!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_userData!['fullName']),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _updateProfile();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: isCurrentUser ? _updateProfileImage : null,
                  child: Hero(
                    tag: 'profile_${_userData!['fullName']}',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _userData!['profileImage'] != null && _userData!['profileImage'].isNotEmpty
                          ? FileImage(File(_userData!['profileImage']))
                          : null,
                      backgroundColor: Colors.blue.shade100,
                      child: _userData!['profileImage'] == null || _userData!['profileImage'].isEmpty
                          ? Text(
                              _userData!['fullName'][0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                if (isCurrentUser)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _updateProfileImage,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _userData!['fullName'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userData!['email'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (!_isEditing && _userData!['location'] != null && _userData!['location'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _userData!['location'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Hakkımda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Biyografi',
                        border: OutlineInputBorder(),
                        hintText: 'Kendiniz hakkında kısa bir bilgi yazın',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Konum',
                        border: OutlineInputBorder(),
                        hintText: 'Örn: İstanbul, Türkiye',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _bioController.text = _userData!['bio'] ?? '';
                              _locationController.text = _userData!['location'] ?? '';
                              _isEditing = false;
                            });
                          },
                          child: const Text('İptal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _userData!['bio']?.isNotEmpty == true
                      ? _userData!['bio']
                      : 'Henüz biyografi eklenmemiş',
                  style: TextStyle(
                    color: _userData!['bio']?.isNotEmpty == true ? null : Colors.grey,
                    fontStyle: _userData!['bio']?.isNotEmpty == true ? null : FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            
            // Eğitim bilgileri
            ProfileSection(
              title: 'Eğitim',
              icon: Icons.school,
              isCurrentUser: isCurrentUser,
              onAddPressed: () => _navigateToEducationForm(),
              itemCount: (_userData!['education'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final education = (_userData!['education'] as List)[index];
                return EducationItem(
                  education: education,
                  isCurrentUser: isCurrentUser,
                  onEdit: () => _navigateToEducationForm(education),
                  onDelete: () => _removeEducation(education['id']),
                );
              },
              emptyText: 'Henüz eğitim bilgisi eklenmemiş',
            ),
            
            const Divider(),
            
            // İş deneyimi bilgileri
            ProfileSection(
              title: 'İş Deneyimi',
              icon: Icons.work,
              isCurrentUser: isCurrentUser,
              onAddPressed: () => _navigateToExperienceForm(),
              itemCount: (_userData!['experience'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final experience = (_userData!['experience'] as List)[index];
                return ExperienceItem(
                  experience: experience,
                  isCurrentUser: isCurrentUser,
                  onEdit: () => _navigateToExperienceForm(experience),
                  onDelete: () => _removeExperience(experience['id']),
                );
              },
              emptyText: 'Henüz iş deneyimi eklenmemiş',
            ),
            
            const Divider(),
            
            // Beceriler
            ProfileSection(
              title: 'Beceriler',
              icon: Icons.star,
              isCurrentUser: isCurrentUser,
              onAddPressed: _navigateToSkillsScreen,
              itemCount: (_userData!['skills'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final skill = (_userData!['skills'] as List)[index];
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue.shade50,
                );
              },
              emptyText: 'Henüz beceri eklenmemiş',
              isWrapped: true,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isCurrentUser;
  final VoidCallback onAddPressed;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final String emptyText;
  final bool isWrapped;

  const ProfileSection({
    super.key,
    required this.title,
    required this.icon,
    required this.isCurrentUser,
    required this.onAddPressed,
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyText,
    this.isWrapped = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isCurrentUser)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: onAddPressed,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (itemCount == 0)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              emptyText,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
        else if (isWrapped)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                itemCount,
                (index) => itemBuilder(context, index),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class EducationItem extends StatelessWidget {
  final Map<String, dynamic> education;
  final bool isCurrentUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EducationItem({
    super.key,
    required this.education,
    required this.isCurrentUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        education['school'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (education['degree']?.isNotEmpty == true ||
                          education['field']?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            [
                              if (education['degree']?.isNotEmpty == true) education['degree'],
                              if (education['field']?.isNotEmpty == true) education['field'],
                            ].join(', '),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
              ],
            ),
            if (education['startDate']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  education['endDate'] == null || education['endDate'].isEmpty
                      ? '${education['startDate']} - Şu anda'
                      : '${education['startDate']} - ${education['endDate']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            if (education['description']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  education['description'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ExperienceItem extends StatelessWidget {
  final Map<String, dynamic> experience;
  final bool isCurrentUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExperienceItem({
    super.key,
    required this.experience,
    required this.isCurrentUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        experience['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          experience['company'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
              ],
            ),
            if (experience['location']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  experience['location'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (experience['startDate']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  experience['endDate'] == null || experience['endDate'].isEmpty
                      ? '${experience['startDate']} - Şu anda'
                      : '${experience['startDate']} - ${experience['endDate']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            if (experience['description']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  experience['description'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 