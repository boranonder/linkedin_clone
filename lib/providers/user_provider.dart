import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String _errorMessage = '';
  
  bool get isLoading => _isLoading;

  String getCurrentUserId(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }
    return authProvider.user!.id;
  }

  Future<void> updateProfile({
    required String userId,
    String? bio,
    String? location,
    File? profileImage,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<String>? skills,
  }) async {
    try {
      _setLoading(true);
      
      // Her zaman tam ve güncel kullanıcı verilerini al
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      print("Profil güncellemeden ÖNCE:");
      print("Bio: ${user.bio}");
      print("Location: ${user.location}");
      print("Education: ${user.education.length} items");
      print("Experience: ${user.experience.length} items");
      print("Skills: ${user.skills.length} items");
      
      String? profileImagePath = user.profileImage;
      
      if (profileImage != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'profile_$userId.jpg';
        final filePath = path.join(directory.path, fileName);
        
        // Dosyayı kopyala
        await profileImage.copy(filePath);
        profileImagePath = filePath;
      }
      
      print("Profil güncelleniyor:");
      print("Bio: ${bio ?? user.bio}");
      print("Location: ${location ?? user.location}");
      print("Education: ${education != null ? education.length : user.education.length} items");
      print("Experience: ${experience != null ? experience.length : user.experience.length} items");
      print("Skills: ${skills != null ? skills.length : user.skills.length} items");
      
      // Mevcut kullanıcı bilgilerini koru, sadece değişenleri güncelle
      UserModel updatedUser = user.copyWith(
        bio: bio ?? user.bio,
        location: location ?? user.location,
        profileImage: profileImagePath,
        education: education ?? user.education,
        experience: experience ?? user.experience,
        skills: skills ?? user.skills,
      );
      
      // Veritabanını güncelle
      await _databaseService.updateUser(updatedUser);
      
      // Tam kullanıcı profilini yeniden yükle
      final refreshedUser = await _databaseService.getFullUserProfile(userId);
      if (refreshedUser != null) {
        print("Güncellenmiş profil:");
        print("Bio: ${refreshedUser.bio}");
        print("Education: ${refreshedUser.education.length} items");
        print("Experience: ${refreshedUser.experience.length} items");
        print("Skills: ${refreshedUser.skills.length} items");
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      _setLoading(false);
      _setError('Profil güncellenirken hata: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      return user.toJson();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createPost({
    required String userId,
    required String content,
    File? image,
  }) async {
    try {
      String? imageUrl;
      
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = path.join(directory.path, fileName);
        
        // Dosyayı kopyala
        await image.copy(filePath);
        imageUrl = filePath;
      }
      
      await _databaseService.createPost(userId, content, imageUrl);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PostModel>> getPosts() async {
    try {
      return await _databaseService.getPosts();
    } catch (e) {
      rethrow;
    }
  }
  
  Stream<List<PostModel>> getPostsStream() {
    // SQLite doğrudan stream desteklemediği için akış simülasyonu yapıyoruz
    return Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) => _databaseService.getPosts());
  }
  
  Future<void> toggleLike(String postId, String userId) async {
    try {
      await _databaseService.toggleLike(postId, userId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // Admin için gönderi silme metodu
  Future<void> deletePost(String postId) async {
    try {
      await _databaseService.deletePost(postId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gönderi silinirken hata: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<List<String>> getPostLikes(String postId) async {
    try {
      return await _databaseService.getPostLikes(postId);
    } catch (e) {
      rethrow;
    }
  }
  
  // Post'a yorum ekleme
  Future<void> addComment(String postId, String userId, String content) async {
    try {
      await _databaseService.addComment(postId, userId, content);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // Post yorumlarını getirme
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      return await _databaseService.getComments(postId);
    } catch (e) {
      rethrow;
    }
  }

  // Eğitim bilgisi ekle
  Future<void> addEducation({
    required String userId,
    required String school,
    String? degree,
    String? field,
    String? startDate,
    String? endDate,
    String? description,
  }) async {
    try {
      _setLoading(true);
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      final newEducation = {
        'id': const Uuid().v4(),
        'school': school,
        'degree': degree ?? '',
        'field': field ?? '',
        'startDate': startDate ?? '',
        'endDate': endDate ?? '',
        'description': description ?? '',
      };
      
      print("Yeni eğitim ekleniyor: ${newEducation['school']}");
      
      // Kopyası yerine doğrudan referansı güncellemek daha güvenli
      List<Map<String, dynamic>> updatedEducation = List.from(user.education);
      updatedEducation.add(newEducation);
      
      await updateProfile(
        userId: userId,
        education: updatedEducation,
      );
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print("Eğitim ekleme hatası: $e");
      _setLoading(false);
      _setError('Eğitim eklenirken hata: $e');
      rethrow;
    }
  }
  
  // İş deneyimi ekle
  Future<void> addExperience({
    required String userId,
    required String company,
    required String title,
    String? location,
    String? startDate,
    String? endDate,
    String? description,
  }) async {
    try {
      _setLoading(true);
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      final newExperience = {
        'id': const Uuid().v4(),
        'company': company,
        'title': title,
        'location': location ?? '',
        'startDate': startDate ?? '',
        'endDate': endDate ?? '',
        'description': description ?? '',
      };
      
      print("Yeni deneyim ekleniyor: ${newExperience['title']} at ${newExperience['company']}");
      
      // Kopyası yerine doğrudan referansı güncellemek daha güvenli
      List<Map<String, dynamic>> updatedExperience = List.from(user.experience);
      updatedExperience.add(newExperience);
      
      await updateProfile(
        userId: userId,
        experience: updatedExperience,
      );
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print("Deneyim ekleme hatası: $e");
      _setLoading(false);
      _setError('Deneyim eklenirken hata: $e');
      rethrow;
    }
  }
  
  // Beceri ekle
  Future<void> addSkill({
    required String userId,
    required String skill,
  }) async {
    try {
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      // Aynı beceri zaten varsa ekleme
      if (user.skills.contains(skill)) {
        return;
      }
      
      List<String> updatedSkills = [...user.skills, skill];
      
      await updateProfile(
        userId: userId,
        skills: updatedSkills,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Beceri sil
  Future<void> removeSkill({
    required String userId,
    required String skill,
  }) async {
    try {
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      List<String> updatedSkills = List.from(user.skills)..remove(skill);
      
      await updateProfile(
        userId: userId,
        skills: updatedSkills,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Eğitim bilgisi sil
  Future<void> removeEducation({
    required String userId,
    required String educationId,
  }) async {
    try {
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      List<Map<String, dynamic>> updatedEducation = List.from(user.education)
        ..removeWhere((edu) => edu['id'] == educationId);
      
      await updateProfile(
        userId: userId,
        education: updatedEducation,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // İş deneyimi sil
  Future<void> removeExperience({
    required String userId,
    required String experienceId,
  }) async {
    try {
      UserModel? user = await _databaseService.getFullUserProfile(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      List<Map<String, dynamic>> updatedExperience = List.from(user.experience)
        ..removeWhere((exp) => exp['id'] == experienceId);
      
      await updateProfile(
        userId: userId,
        experience: updatedExperience,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Bağlantı işlemleri için metodlar
  
  // Kullanıcı profilini ID'ye göre getir
  Future<UserModel?> getUserById(String userId) async {
    try {
      final user = await _databaseService.getFullUserProfile(userId);
      return user;
    } catch (e) {
      _errorMessage = 'Kullanıcı bilgileri yüklenirken hata: $e';
      notifyListeners();
      return null;
    }
  }
  
  // Kullanıcının gönderilerini getir
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final posts = await _databaseService.getUserPosts(userId);
      return posts;
    } catch (e) {
      _errorMessage = 'Kullanıcı gönderileri yüklenirken hata: $e';
      notifyListeners();
      return [];
    }
  }
  
  // Bağlantı isteği gönder
  Future<void> sendConnectionRequest(String senderId, String receiverId) async {
    try {
      await _databaseService.sendConnectionRequest(senderId, receiverId, null);
    } catch (e) {
      _errorMessage = 'Bağlantı isteği gönderilirken hata: $e';
      notifyListeners();
      throw e;
    }
  }
  
  // Bağlantı durumunu kontrol et
  Future<String> checkConnectionStatus(String userId1, String userId2) async {
    try {
      return await _databaseService.checkConnectionStatus(userId1, userId2);
    } catch (e) {
      _errorMessage = 'Bağlantı durumu kontrol edilirken hata: $e';
      notifyListeners();
      return 'not_connected';
    }
  }
  
  // Bağlantı isteklerini getir
  Future<List<Map<String, dynamic>>> getConnectionRequests(String userId) async {
    try {
      return await _databaseService.getConnectionRequests(userId);
    } catch (e) {
      _errorMessage = 'Bağlantı istekleri yüklenirken hata: $e';
      notifyListeners();
      return [];
    }
  }
  
  // Gönderilen bağlantı isteklerini getir
  Future<List<Map<String, dynamic>>> getSentConnectionRequests(String userId) async {
    try {
      return await _databaseService.getSentConnectionRequests(userId);
    } catch (e) {
      _errorMessage = 'Gönderilen bağlantı istekleri yüklenirken hata: $e';
      notifyListeners();
      return [];
    }
  }
  
  // Bağlantı isteğini yanıtla
  Future<void> respondToConnectionRequest(String requestId, String status) async {
    try {
      await _databaseService.respondToConnectionRequest(requestId, status);
    } catch (e) {
      _errorMessage = 'Bağlantı isteğine yanıt verilirken hata: $e';
      notifyListeners();
      throw e;
    }
  }
  
  // Kullanıcı bağlantılarını getir
  Future<List<Map<String, dynamic>>> getUserConnections(String userId) async {
    try {
      return await _databaseService.getUserConnections(userId);
    } catch (e) {
      _errorMessage = 'Kullanıcı bağlantıları yüklenirken hata: $e';
      notifyListeners();
      return [];
    }
  }

  // Bağlantıyı kaldır
  Future<void> removeConnection(String connectionId) async {
    try {
      await _databaseService.removeConnection(connectionId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Bağlantı kaldırılırken hata: $e';
      notifyListeners();
      throw e;
    }
  }

  // Kullanıcıları ara (searchUsers metodu yerine findUsers methodunu kullanmak için)
  Future<List<UserModel>> findUsers(String query) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final users = await _databaseService.searchUsers(query);
      
      _isLoading = false;
      notifyListeners();
      
      return users;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Kullanıcılar aranırken hata: $e';
      notifyListeners();
      return [];
    }
  }
  
  Future<UserModel?> getCurrentUser(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final userId = getCurrentUserId(context);
      final user = await _databaseService.getUserById(userId);
      
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserProfile(
    BuildContext context, {
    String? fullName,
    String? bio,
    String? location,
    File? profileImage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final userId = getCurrentUserId(context);
      // Her zaman tam ve güncel kullanıcı verilerini al
      final user = await _databaseService.getFullUserProfile(userId);
      
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      String? profileImagePath = user.profileImage;
      
      // Eğer yeni bir profil resmi seçildiyse, bu dosyayı kaydet
      if (profileImage != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(profileImage.path)}';
        final savedImage = await profileImage.copy('${directory.path}/$fileName');
        profileImagePath = savedImage.path;
      }

      // Tüm kullanıcı bilgilerini güncelle, sadece verilen alanları değil
      final updatedUser = user.copyWith(
        fullName: fullName ?? user.fullName,
        bio: bio ?? user.bio,
        location: location ?? user.location,
        profileImage: profileImagePath,
      );
      
      await _databaseService.updateUser(updatedUser);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
} 