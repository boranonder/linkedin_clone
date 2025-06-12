import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _skillController = TextEditingController();
  bool _isLoading = false;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
      final userData = await Provider.of<UserProvider>(context, listen: false).getUserData(userId);
      
      setState(() {
        _skills = List<String>.from(userData['skills'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addSkill() async {
    final skill = _skillController.text.trim();
    if (skill.isEmpty) {
      return;
    }

    // Aynı beceri zaten varsa ekleme
    if (_skills.contains(skill)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu beceri zaten eklenmiş')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
      
      await Provider.of<UserProvider>(context, listen: false).addSkill(
        userId: userId,
        skill: skill,
      );
      
      _skillController.clear();
      await _loadSkills();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeSkill(String skill) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
      
      await Provider.of<UserProvider>(context, listen: false).removeSkill(
        userId: userId,
        skill: skill,
      );
      
      await _loadSkills();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beceriler'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(
                      labelText: 'Yeni Beceri',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: Flutter, React, Python',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addSkill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(50, 56),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Becerileriniz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _skills.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Henüz beceri eklenmemiş'),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _skills.length,
                          itemBuilder: (context, index) {
                            final skill = _skills[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(skill),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeSkill(skill),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
} 