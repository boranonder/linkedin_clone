import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _user;

  UserModel? get user => _user;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Email kontrolü
      final existingUser = await _databaseService.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Bu email adresi zaten kullanılıyor');
      }

      // Yeni kullanıcı oluştur
      final newUser = await _databaseService.createUser(
        fullName,
        email,
        password,
      );
      
      _user = newUser;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _databaseService.authenticateUser(email, password);
      
      if (user == null) {
        throw Exception('Geçersiz email veya şifre');
      }
      
      _user = user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }
  
  // Demo hesabı ile otomatik giriş, geliştirme sırasında kolaylık sağlar
  Future<void> signInWithDemo() async {
    try {
      final user = await _databaseService.authenticateUser('demo@example.com', 'password123');
      _user = user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // Admin hesabı ile giriş
  Future<void> signInAsAdmin() async {
    try {
      final user = await _databaseService.authenticateUser('admin@example.com', 'admin123');
      if (user == null) {
        throw Exception('Admin kullanıcısı bulunamadı');
      }
      
      // Admin yetkilerini ekle
      final adminUser = user.copyWith(isAdmin: true);
      _user = adminUser;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
} 