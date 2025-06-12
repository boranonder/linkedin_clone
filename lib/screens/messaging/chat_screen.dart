import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userImage;
  
  const ChatScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.userImage,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInit = false;
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _fetchMessages();
      _isInit = true;
    }
    super.didChangeDependencies();
  }
  
  Future<void> _fetchMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await messageProvider.fetchMessages(authProvider.user!.id, widget.userId);
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      try {
        await messageProvider.sendMessage(
          authProvider.user!.id,
          widget.userId,
          _messageController.text.trim(),
        );
        
        _messageController.clear();
        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mesaj gönderilirken hata: $e')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final messageProvider = Provider.of<MessageProvider>(context);
    
    if (authProvider.user == null) {
      return const Center(
        child: Text('Mesajlaşmak için giriş yapmanız gerekiyor.'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.userImage != null && widget.userImage!.isNotEmpty
                  ? FileImage(File(widget.userImage!))
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
            const SizedBox(width: 8),
            Text(widget.userName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messageProvider.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messageProvider.messagesError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(messageProvider.messagesError!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchMessages,
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : messageProvider.messages.isEmpty
                        ? const Center(
                            child: Text('Henüz mesaj yok.'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messageProvider.messages.length,
                            itemBuilder: (context, index) {
                              final message = messageProvider.messages[index];
                              final bool isMe = message['senderId'] == authProvider.user!.id;
                              
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['content'],
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(DateTime.parse(message['createdAt'])),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMe ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
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
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return 'Dün ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
} 