import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../profile/user_profile_screen.dart';

class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionRequestsScreen> createState() => _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _connections = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        final String userId = authProvider.user!.id;
        
        // Gelen ve giden istekleri yükle
        _receivedRequests = await userProvider.getConnectionRequests(userId);
        _sentRequests = await userProvider.getSentConnectionRequests(userId);
        
        // Bağlantıları yükle
        _connections = await userProvider.getUserConnections(userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı istekleri yüklenirken hata: $e')),
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
        title: const Text('Bağlantılar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gelen İstekler'),
            Tab(text: 'Gönderilen İstekler'),
            Tab(text: 'Bağlantılar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedRequestsList(),
          _buildSentRequestsList(),
          _buildConnectionsList(),
        ],
      ),
    );
  }

  Widget _buildReceivedRequestsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receivedRequests.isEmpty) {
      return const Center(
        child: Text('Herhangi bir bağlantı isteği yok.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        itemCount: _receivedRequests.length,
        itemBuilder: (context, index) {
          final request = _receivedRequests[index];
          final String senderId = request['senderId'];
          final String senderName = request['senderName'] ?? 'Bilinmeyen Kullanıcı';
          final String? senderImage = request['senderProfileImage'];
          final String requestId = request['id'];
          final String createdAt = request['createdAt'];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: senderId),
                        ),
                      ).then((_) => _loadRequests());
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: senderImage != null && senderImage.isNotEmpty
                              ? FileImage(File(senderImage))
                              : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatDate(DateTime.parse(createdAt)),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _respondToRequest(requestId, 'rejected'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Reddet', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () => _respondToRequest(requestId, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Kabul Et', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentRequestsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sentRequests.isEmpty) {
      return const Center(
        child: Text('Gönderilen bağlantı isteği yok.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          final String receiverId = request['receiverId'];
          final String receiverName = request['receiverName'] ?? 'Bilinmeyen Kullanıcı';
          final String? receiverImage = request['receiverProfileImage'];
          final String requestId = request['id'];
          final String status = request['status'];
          final String createdAt = request['createdAt'];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: receiverId),
                        ),
                      ).then((_) => _loadRequests());
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: receiverImage != null && receiverImage.isNotEmpty
                              ? FileImage(File(receiverImage))
                              : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receiverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatSentRequestStatus(status),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatDate(DateTime.parse(createdAt)),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _cancelRequest(requestId),
                            child: const Text('İsteği İptal Et'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_connections.isEmpty) {
      return const Center(
        child: Text('Henüz bir bağlantınız yok.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        itemCount: _connections.length,
        itemBuilder: (context, index) {
          final connection = _connections[index];
          final String userId = connection['userId'];
          final String name = connection['name'] ?? 'Bilinmeyen Kullanıcı';
          final String? profileImage = connection['profileImage'];
          final String? bio = connection['bio'];
          final String connectionId = connection['connectionId'];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: userId),
                        ),
                      ).then((_) => _loadRequests());
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: profileImage != null && profileImage.isNotEmpty
                              ? FileImage(File(profileImage))
                              : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (bio != null && bio.isNotEmpty)
                                Text(
                                  bio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _removeConnection(connectionId),
                        icon: const Icon(Icons.person_remove, size: 16, color: Colors.red),
                        label: const Text('Bağlantıyı Kaldır', style: TextStyle(fontSize: 12, color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _respondToRequest(String requestId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.respondToConnectionRequest(requestId, status);
      
      // Yeniden yükle
      await _loadRequests();
      
      // Başarılı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? 'Bağlantı isteği kabul edildi' : 'Bağlantı isteği reddedildi'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem sırasında hata: $e')),
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

  Future<void> _cancelRequest(String requestId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.respondToConnectionRequest(requestId, 'cancelled');
      
      // Yeniden yükle
      await _loadRequests();
      
      // Başarılı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı isteği iptal edildi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem sırasında hata: $e')),
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

  Future<void> _removeConnection(String connectionId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Bağlantıyı kaldır
      await userProvider.removeConnection(connectionId);
      
      // Yeniden yükle
      await _loadRequests();
      
      // Başarılı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı kaldırıldı'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem sırasında hata: $e')),
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

  String _formatSentRequestStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
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