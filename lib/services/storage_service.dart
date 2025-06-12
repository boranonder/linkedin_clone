import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class StorageService {
  late SharedPreferences _prefs;
  late Directory _appDir;
  final String _userKey = 'users';
  final String _postKey = 'posts';
  final String _currentUserKey = 'currentUser';

  // Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _appDir = await getApplicationDocumentsDirectory();
    
    // Initialize the users and posts if not already done
    if (!_prefs.containsKey(_userKey)) {
      _prefs.setString(_userKey, jsonEncode([]));
    }
    
    if (!_prefs.containsKey(_postKey)) {
      _prefs.setString(_postKey, jsonEncode([]));
    }
  }

  // Get the current user
  UserModel? getCurrentUser() {
    final String? userJson = _prefs.getString(_currentUserKey);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  // Set the current user
  Future<void> setCurrentUser(UserModel? user) async {
    if (user == null) {
      await _prefs.remove(_currentUserKey);
    } else {
      await _prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    }
  }

  // Get all users
  List<UserModel> getUsers() {
    final String usersJson = _prefs.getString(_userKey) ?? '[]';
    List<dynamic> usersData = jsonDecode(usersJson);
    return usersData.map((user) => UserModel.fromJson(user)).toList();
  }

  // Add a new user
  Future<UserModel> addUser(String fullName, String email, String password) async {
    final users = getUsers();
    
    // Check if user already exists
    if (users.any((user) => user.email == email)) {
      throw Exception('User with this email already exists');
    }
    
    final newUser = UserModel(
      id: const Uuid().v4(),
      fullName: fullName,
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
    
    users.add(newUser);
    await _prefs.setString(_userKey, jsonEncode(users.map((user) => user.toJson()).toList()));
    
    // Also store password (in a real app, this would be done differently)
    await _prefs.setString('password_${newUser.id}', password);
    
    return newUser;
  }

  // Update user
  Future<UserModel> updateUser(UserModel user) async {
    final users = getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    
    if (index == -1) {
      throw Exception('User not found');
    }
    
    users[index] = user;
    await _prefs.setString(_userKey, jsonEncode(users.map((user) => user.toJson()).toList()));
    
    // Update current user if this is the current user
    final currentUser = getCurrentUser();
    if (currentUser != null && currentUser.id == user.id) {
      await setCurrentUser(user);
    }
    
    return user;
  }

  // Get user by id
  UserModel? getUserById(String userId) {
    final users = getUsers();
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Get user by email
  UserModel? getUserByEmail(String email) {
    final users = getUsers();
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  // Authenticate user
  Future<UserModel?> authenticateUser(String email, String password) async {
    final user = getUserByEmail(email);
    if (user == null) return null;
    
    final storedPassword = _prefs.getString('password_${user.id}');
    if (storedPassword == password) {
      return user;
    }
    
    return null;
  }

  // Get all posts
  List<PostModel> getPosts() {
    final String postsJson = _prefs.getString(_postKey) ?? '[]';
    List<dynamic> postsData = jsonDecode(postsJson);
    return postsData.map((post) => PostModel.fromJson(post)).toList();
  }

  // Add a new post
  Future<PostModel> addPost(String userId, String content, File? image) async {
    String? imageUrl;
    
    // If there's an image, save it to the file system
    if (image != null) {
      final fileName = '${const Uuid().v4()}.jpg';
      final imagePath = '${_appDir.path}/$fileName';
      await image.copy(imagePath);
      imageUrl = imagePath;
    }
    
    final posts = getPosts();
    final newPost = PostModel(
      id: const Uuid().v4(),
      userId: userId,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now().toIso8601String(),
      likes: [],
    );
    
    posts.add(newPost);
    await _prefs.setString(_postKey, jsonEncode(posts.map((post) => post.toJson()).toList()));
    
    return newPost;
  }
} 