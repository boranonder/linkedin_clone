import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../messaging/chat_screen.dart';
import '../../services/database_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  UserModel? _user;
  List<PostModel> _userPosts = [];
  String _connectionStatus = 'not_connected'; // 'not_connected', 'pending', 'connected'
  bool _isCurrentUser = false;
  bool _isLoadingConnection = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Kullanıcının kendisi mi kontrol et
      _isCurrentUser = widget.userId == authProvider.user?.id;
      
      // Kullanıcı verilerini yükle
      _user = await userProvider.getUserById(widget.userId);
      
      if (_user != null) {
        // Kullanıcının gönderilerini yükle
        _userPosts = await userProvider.getUserPosts(widget.userId);
        
        // Bağlantı durumunu kontrol et
        if (!_isCurrentUser && authProvider.user != null) {
          _connectionStatus = await userProvider.checkConnectionStatus(
            authProvider.user!.id,
            widget.userId,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı verileri yüklenirken hata: $e')),
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

  Future<void> _sendConnectionRequest() async {
    if (_isLoadingConnection) return;
    
    setState(() {
      _isLoadingConnection = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        await userProvider.sendConnectionRequest(
          authProvider.user!.id,
          widget.userId,
        );
        
        setState(() {
          _connectionStatus = 'pending';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı isteği gönderilirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConnection = false;
        });
      }
    }
  }

  Future<void> _removeConnection() async {
    if (_isLoadingConnection) return;
    
    setState(() {
      _isLoadingConnection = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        // Bağlantıları getir
        final connections = await userProvider.getUserConnections(authProvider.user!.id);
        
        // Bu kullanıcıyla olan bağlantıyı bul
        final connection = connections.firstWhere(
          (c) => c['userId'] == widget.userId,
          orElse: () => <String, dynamic>{},
        );
        
        if (connection.isNotEmpty) {
          // Bağlantıyı kaldır
          await _databaseService.removeConnection(connection['connectionId']);
          
          setState(() {
            _connectionStatus = 'not_connected';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bağlantı kaldırıldı'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı kaldırılırken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConnection = false;
        });
      }
    }
  }

  Widget _buildConnectionButton() {
    if (_isCurrentUser) {
      return const SizedBox.shrink();
    }

    switch (_connectionStatus) {
      case 'not_connected':
        return ElevatedButton.icon(
          onPressed: _isLoadingConnection ? null : _sendConnectionRequest,
          icon: const Icon(Icons.person_add),
          label: _isLoadingConnection 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Bağlantı Gönder'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        );
        
      case 'pending':
        return OutlinedButton.icon(
          onPressed: null, // Bekleyen istek geri çekme özelliği eklenebilir
          icon: const Icon(Icons.hourglass_top),
          label: const Text('İstek Gönderildi'),
        );
        
      case 'connected':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // Mesaj gönderme ekranına git
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      userId: widget.userId,
                      userName: _user?.fullName ?? 'Kullanıcı',
                      userImage: _user?.profileImage,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Mesaj', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              onPressed: _removeConnection,
              icon: const Icon(Icons.person_remove, color: Colors.red, size: 16),
              label: const Text('Kaldır', style: TextStyle(color: Colors.red, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.fullName ?? 'Kullanıcı Profili'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Kullanıcı bulunamadı.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil bilgileri bölümü
                      _buildProfileHeader(),
                      
                      const Divider(height: 20),
                      
                      // Hakkında bölümü
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hakkında',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _user?.bio?.isNotEmpty == true
                                  ? _user!.bio!
                                  : 'Kullanıcı henüz bir açıklama eklememiş.',
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(height: 20),
                      
                      // Deneyim bölümü
                      if (_user?.experience.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deneyim',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._user!.experience.map((exp) => _buildExperienceItem(exp)),
                            ],
                          ),
                        ),
                      
                      const Divider(height: 20),
                      
                      // Eğitim bölümü
                      if (_user?.education.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Eğitim',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._user!.education.map((edu) => _buildEducationItem(edu)),
                            ],
                          ),
                        ),
                      
                      const Divider(height: 20),
                      
                      // Beceriler bölümü
                      if (_user?.skills.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Beceriler',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _user!.skills.map((skill) => Chip(
                                  label: Text(skill),
                                  backgroundColor: Colors.grey[200],
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      
                      const Divider(height: 20),
                      
                      // Gönderiler bölümü
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gönderiler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _userPosts.isEmpty
                                ? const Text('Kullanıcı henüz bir gönderi paylaşmamış.')
                                : Column(
                                    children: _userPosts.map((post) => _buildPostItem(post)).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          color: Colors.blue[100],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _user?.profileImage != null && _user!.profileImage!.isNotEmpty
                        ? FileImage(File(_user!.profileImage!))
                        : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.fullName ?? 'İsimsiz Kullanıcı',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_user?.location != null && _user!.location!.isNotEmpty)
                          Text(
                            _user!.location!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 8),
                        _buildConnectionButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceItem(Map<String, dynamic> experience) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${experience['title']} - ${experience['company']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (experience['location'] != null && experience['location'].isNotEmpty)
            Text(experience['location']),
          if (experience['startDate'] != null && experience['startDate'].isNotEmpty)
            Text('${experience['startDate']} - ${experience['endDate'] ?? 'Devam ediyor'}'),
          if (experience['description'] != null && experience['description'].isNotEmpty)
            Text(
              experience['description'],
              style: TextStyle(color: Colors.grey[700]),
            ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(Map<String, dynamic> education) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            education['school'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (education['degree'] != null && education['degree'].isNotEmpty)
            Text('${education['degree']}${education['field'] != null && education['field'].isNotEmpty ? ' - ${education['field']}' : ''}'),
          if (education['startDate'] != null && education['startDate'].isNotEmpty)
            Text('${education['startDate']} - ${education['endDate'] ?? 'Devam ediyor'}'),
          if (education['description'] != null && education['description'].isNotEmpty)
            Text(
              education['description'],
              style: TextStyle(color: Colors.grey[700]),
            ),
        ],
      ),
    );
  }

  Widget _buildPostItem(PostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: _user?.profileImage != null && _user!.profileImage!.isNotEmpty
                      ? FileImage(File(_user!.profileImage!))
                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.fullName ?? 'İsimsiz Kullanıcı',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(DateTime.parse(post.createdAt)),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.file(
                  File(post.imageUrl!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${post.likes.length} beğeni'),
                // Buraya yorum sayısı eklenebilir
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} yıl önce';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ay önce';
    } else if (difference.inDays > 0) {
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