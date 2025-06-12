import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _fetchConversations();
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _fetchConversations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await messageProvider.fetchConversations(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final messageProvider = Provider.of<MessageProvider>(context);
    
    if (authProvider.user == null) {
      return const Center(
        child: Text('Mesajlarınızı görmek için giriş yapmanız gerekiyor.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchUserDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSearchUserDialog(context),
        child: const Icon(Icons.message),
        tooltip: 'Yeni mesaj',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchConversations,
        child: messageProvider.isLoadingConversations
            ? const Center(child: CircularProgressIndicator())
            : messageProvider.conversationsError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(messageProvider.conversationsError!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchConversations,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : messageProvider.conversations.isEmpty
                    ? const Center(
                        child: Text('Henüz hiç mesajınız bulunmuyor.'),
                      )
                    : ListView.builder(
                        itemCount: messageProvider.conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = messageProvider.conversations[index];
                          final DateTime messageTime = DateTime.parse(conversation['lastMessageTime'] ?? DateTime.now().toIso8601String());
                          final String userName = conversation['userName'] ?? 'Kullanıcı';
                          final String? userProfileImage = conversation['userProfileImage'];
                          final String userId = conversation['userId'] ?? '';
                          final String content = conversation['content'] ?? '';
                          final int unreadCount = conversation['unreadCount'] ?? 0;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: userProfileImage != null && userProfileImage.isNotEmpty
                                  ? FileImage(File(userProfileImage))
                                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            ),
                            title: Text(
                              userName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    content,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: unreadCount > 0
                                          ? Colors.black
                                          : Colors.grey,
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDate(messageTime),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
                                    userId: userId,
                                    userName: userName,
                                    userImage: userProfileImage,
                                  ),
                                ),
                              ).then((_) {
                                // Mesaj ekranından geri dönüldüğünde sohbetleri yenile
                                _fetchConversations();
                              });
                            },
                          );
                        },
                      ),
      ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      // Bugün ise saat göster
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      // Dün ise "Dün" yaz
      return 'Dün';
    } else {
      // Diğer günler
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  Future<void> _showSearchUserDialog(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) return;
    
    final TextEditingController searchController = TextEditingController();
    List<UserModel> searchResults = [];
    bool isSearching = false;
    
    Future<void> searchUsers(String query) async {
      if (query.length < 2) return;
      
      try {
        searchResults = await userProvider.findUsers(query);
        if (searchResults.isNotEmpty) {
          // Kendi hesabını sonuçlardan çıkar
          searchResults = searchResults.where((user) => user.id != authProvider.user!.id).toList();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arama yapılırken hata: $e')),
          );
        }
      }
    }
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Mesaj'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'İsim veya e-posta ile kullanıcı ara',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.length >= 2) {
                          setState(() {
                            isSearching = true;
                          });
                          
                          searchUsers(value).then((_) {
                            setState(() {
                              isSearching = false;
                            });
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isSearching)
                      const Center(child: CircularProgressIndicator())
                    else if (searchResults.isEmpty && searchController.text.length >= 2)
                      const Center(
                        child: Text('Kullanıcı bulunamadı'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                                    ? FileImage(File(user.profileImage!))
                                    : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                              ),
                              title: Text(user.fullName),
                              subtitle: Text(user.email),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      userId: user.id,
                                      userName: user.fullName,
                                      userImage: user.profileImage,
                                    ),
                                  ),
                                ).then((_) {
                                  // Mesaj ekranından dönünce sohbetleri yenile
                                  _fetchConversations();
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('İptal'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 