import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class MessageProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  // Mevcut kullanıcı sohbetleri
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;

  // Aktif sohbetteki mesajlar
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = false;
  String? _messagesError;
  
  // Getters
  List<Map<String, dynamic>> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get conversationsError => _conversationsError;
  
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;
  
  // Kullanıcının tüm sohbetlerini getir
  Future<void> fetchConversations(String userId) async {
    try {
      _isLoadingConversations = true;
      _conversationsError = null;
      notifyListeners();

      _conversations = await _databaseService.getConversations(userId);
      
      _isLoadingConversations = false;
      notifyListeners();
    } catch (e) {
      _isLoadingConversations = false;
      _conversationsError = 'Konuşmalar yüklenirken hata: $e';
      notifyListeners();
    }
  }
  
  // İki kullanıcı arasındaki mesajları getir
  Future<void> fetchMessages(String userId1, String userId2) async {
    try {
      _isLoadingMessages = true;
      _messagesError = null;
      notifyListeners();

      _messages = await _databaseService.getMessages(userId1, userId2);
      
      // Mesajları okundu olarak işaretle
      await _databaseService.markMessagesAsRead(userId2, userId1);
      
      _isLoadingMessages = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMessages = false;
      _messagesError = 'Mesajlar yüklenirken hata: $e';
      notifyListeners();
    }
  }
  
  // Mesaj gönder
  Future<void> sendMessage(String senderId, String receiverId, String content) async {
    try {
      final message = await _databaseService.sendMessage(senderId, receiverId, content);
      
      // Mesajları yeniden yükle
      await fetchMessages(senderId, receiverId);
      
      // Konuşmaları güncelle
      await fetchConversations(senderId);
    } catch (e) {
      _messagesError = 'Mesaj gönderilirken hata: $e';
      notifyListeners();
      throw e;
    }
  }
  
  // Okunmamış mesaj sayısını getir
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      return await _databaseService.getUnreadMessageCount(userId);
    } catch (e) {
      return 0;
    }
  }
  
  // Mesajları temizle (örneğin, kullanıcı sohbetten çıktığında)
  void clearMessages() {
    _messages = [];
    _isLoadingMessages = false;
    _messagesError = null;
    notifyListeners();
  }
  
  // Hata mesajlarını temizle
  void clearErrors() {
    _conversationsError = null;
    _messagesError = null;
    notifyListeners();
  }
} 