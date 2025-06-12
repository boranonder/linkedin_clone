import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/post_model.dart';

class CommentScreen extends StatefulWidget {
  final PostModel post;
  
  const CommentScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final comments = await userProvider.getComments(widget.post.id);
      
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorumlar yüklenirken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.addComment(
        widget.post.id,
        authProvider.user!.id,
        text,
      );

      _commentController.clear();
      await _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum eklenirken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yorumlar'),
      ),
      body: Column(
        children: [
          // Post özeti
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: widget.post.userProfileImage != null && widget.post.userProfileImage!.isNotEmpty
                            ? FileImage(File(widget.post.userProfileImage!))
                            : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // Yorumlar
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('Henüz yorum yapılmamış'))
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment['userImage'] != null && comment['userImage'].toString().isNotEmpty
                                  ? FileImage(File(comment['userImage']))
                                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            ),
                            title: Row(
                              children: [
                                Text(
                                  comment['userName'] ?? 'Kullanıcı',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(DateTime.parse(comment['createdAt'])),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(comment['content']),
                            ),
                          );
                        },
                      ),
          ),
          
          // Yorum yapma alanı
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Yorum giriş alanı
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Yorum yazın...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                // Gönder butonu
                IconButton(
                  onPressed: _isLoading ? null : _addComment,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
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
        if (difference.inMinutes == 0) {
          return 'Az önce';
        }
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