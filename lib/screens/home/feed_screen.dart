import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/post_model.dart';
import '../profile/profile_screen.dart';
import 'create_post_screen.dart';
import 'comment_screen.dart';
import 'dart:io';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _isLoading = false;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        // Admin ise tüm gönderileri göster
        if (authProvider.user!.isAdmin) {
          _posts = await userProvider.getPosts();
        } else {
          // Normal kullanıcı ise sadece bağlantılarının gönderilerini göster
          // Önce bağlantılı kullanıcıları al
          final connections = await userProvider.getUserConnections(authProvider.user!.id);
          final connectedUserIds = connections.map((c) => c['id'] as String).toList();
          
          // Kullanıcının kendi ID'sini de ekle (kendi gönderilerini de görebilmesi için)
          connectedUserIds.add(authProvider.user!.id);
          
          // Sadece bağlantılı kullanıcıların gönderilerini getir
          final posts = await userProvider.getPosts();
          _posts = posts.where((post) => connectedUserIds.contains(post.userId)).toList();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderiler yüklenirken hata: $e')),
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

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
    
    if (result == true) {
      _loadPosts(); // Gönderi oluşturulduysa yenile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        tooltip: 'Gönderi Oluştur',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(
                  child: Text('Henüz hiç gönderi yok.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return _buildPostCard(post);
                    },
                  ),
                ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user!.id;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Kullanıcının post'u beğenip beğenmediğini kontrol et
    final bool isLiked = post.likes.contains(userId);
    final bool isAdmin = authProvider.user!.isAdmin;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post.userProfileImage != null && post.userProfileImage!.isNotEmpty
                  ? FileImage(File(post.userProfileImage!))
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
            title: Text(post.userName),
            subtitle: Text(_formatDate(DateTime.parse(post.createdAt))),
            trailing: isAdmin ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                // Admin için gönderi silme işlevi
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Gönderiyi Sil'),
                    content: const Text('Bu gönderiyi silmek istediğinizden emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  try {
                    // Gönderiyi sil (Bu metodu UserProvider'a eklemeniz gerekecek)
                    await userProvider.deletePost(post.id);
                    _loadPosts(); // Listeyi yenile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gönderi silindi')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gönderi silinirken hata: $e')),
                    );
                  }
                }
              },
            ) : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(post.content),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Image.file(
              File(post.imageUrl!),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ButtonBar(
            children: [
              TextButton.icon(
                icon: Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: isLiked ? Colors.blue : null,
                ),
                label: Text(
                  '${post.likes.length}',
                  style: TextStyle(
                    color: isLiked ? Colors.blue : null,
                  ),
                ),
                onPressed: () async {
                  try {
                    await userProvider.toggleLike(post.id, userId);
                    // Post'ları tekrar yükle
                    _loadPosts();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Beğeni işlemi sırasında hata: $e')),
                    );
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.comment),
                label: const Text('Yorum'),
                onPressed: () {
                  // Yorum ekranına git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentScreen(post: post),
                    ),
                  ).then((_) {
                    // Yorumlardan döndükten sonra sayfayı yenile
                    _loadPosts();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
} 