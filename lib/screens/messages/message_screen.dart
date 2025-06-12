import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message_model.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  static const routeName = '/messages';

  const MessageScreen({Key? key}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    try {
      await messageProvider.fetchConversations(authProvider.user!.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohbetler yüklenirken hata: $e')),
      );
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
    final messageProvider = Provider.of<MessageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : messageProvider.conversations.isEmpty
              ? const Center(
                  child: Text('Henüz bir sohbet başlatmadınız.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: messageProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = messageProvider.conversations[index];
                      final otherUserId = conversation['userId'];
                      final lastMessage = conversation['lastMessage'];
                      final unreadCount = conversation['unreadCount'];
                      final timestamp = DateTime.parse(conversation['timestamp']);
                      final timeAgo = _getTimeAgo(timestamp);

                      return FutureBuilder(
                        future: userProvider.getUserData(otherUserId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text('Yükleniyor...'),
                            );
                          }

                          final userData = snapshot.data;
                          final userName = userData != null
                              ? '${userData['firstName']} ${userData['lastName']}'
                              : 'Bilinmeyen Kullanıcı';
                          final userImage = userData?['profileImage'];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userImage != null
                                  ? FileImage(userImage)
                                  : null,
                              child: userImage == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(userName),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    receiverId: otherUserId,
                                    receiverName: userName,
                                    receiverImage: userImage,
                                  ),
                                ),
                              ).then((_) => _loadConversations());
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 1) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Az önce';
    }
  }
} 