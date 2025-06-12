import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'linkedin.db');
    
    // Veritabanı dosyasını silip yeniden oluşturalım
    try {
      await deleteDatabase(path);
      print("Veritabanı silindi, yeniden oluşturuluyor...");
    } catch (e) {
      print("Veritabanı silinirken hata: $e");
    }
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        print("Veritabanı açıldı");
        // Tablo varlığını kontrol et
        await _ensureTablesExist(db);
        // Hata ayıklama için tablo listesini yazdır
        var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        print("Mevcut tablolar: $tables");
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Kullanıcılar tablosu
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        bio TEXT,
        profileImage TEXT,
        location TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Eğitim tablosu
    await db.execute('''
      CREATE TABLE education(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        school TEXT NOT NULL,
        degree TEXT,
        field TEXT,
        startDate TEXT,
        endDate TEXT,
        description TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // İş deneyimi tablosu
    await db.execute('''
      CREATE TABLE experience(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        company TEXT NOT NULL,
        title TEXT NOT NULL,
        location TEXT,
        startDate TEXT,
        endDate TEXT,
        description TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Beceriler tablosu
    await db.execute('''
      CREATE TABLE skills(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        skill TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Gönderiler tablosu
    await db.execute('''
      CREATE TABLE posts(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        content TEXT NOT NULL,
        imageUrl TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Beğeniler tablosu
    await db.execute('''
      CREATE TABLE likes(
        id TEXT PRIMARY KEY,
        postId TEXT NOT NULL,
        userId TEXT NOT NULL,
        FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Bağlantı istekleri tablosu
    await db.execute('''
      CREATE TABLE connection_requests(
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        message TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (senderId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiverId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Bağlantılar tablosu
    await db.execute('''
      CREATE TABLE connections(
        id TEXT PRIMARY KEY,
        user1Id TEXT NOT NULL,
        user2Id TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (user1Id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (user2Id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // İş ilanları tablosu
    await db.execute('''
      CREATE TABLE jobs(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        company TEXT NOT NULL,
        location TEXT NOT NULL,
        description TEXT NOT NULL,
        requirements TEXT NOT NULL,
        salary TEXT,
        jobType TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // İş başvuruları tablosu
    await db.execute('''
      CREATE TABLE job_applications(
        id TEXT PRIMARY KEY,
        jobId TEXT NOT NULL,
        userId TEXT NOT NULL,
        resumePath TEXT,
        coverLetter TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (jobId) REFERENCES jobs (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Mesajlar tablosu
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        content TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (senderId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiverId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Örnek kullanıcı oluştur
    await db.insert('users', {
      'id': '1',
      'fullName': 'Demo Kullanıcı',
      'email': 'demo@example.com',
      'password': 'password123',
      'bio': 'Bu bir demo kullanıcıdır',
      'profileImage': '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Örnek gönderiler oluştur
    await db.insert('posts', {
      'id': '1',
      'userId': '1',
      'content': 'LinkedIn klonuna hoş geldiniz! Bu bir örnek gönderidir.',
      'imageUrl': null,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('posts', {
      'id': '2',
      'userId': '1',
      'content': 'Flutter ile geliştirme yapmak çok keyifli!',
      'imageUrl': null,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    });

    // Örnek iş ilanları oluştur
    await db.insert('jobs', {
      'id': '1',
      'userId': '1',
      'title': 'Flutter Geliştirici',
      'company': 'TechCo',
      'location': 'İstanbul, Türkiye',
      'description': 'Flutter kullanarak mobil uygulamalar geliştirmek için deneyimli bir geliştirici arıyoruz.',
      'requirements': 'Flutter, Dart, Git, Firebase',
      'salary': '20,000 - 30,000 TL',
      'jobType': 'Tam Zamanlı',
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': 1,
    });

    await db.insert('jobs', {
      'id': '2',
      'userId': '1',
      'title': 'UI/UX Tasarımcı',
      'company': 'DesignStudio',
      'location': 'Ankara, Türkiye',
      'description': 'Kullanıcı deneyimi odaklı tasarımlar yapacak yaratıcı bir UI/UX tasarımcı arıyoruz.',
      'requirements': 'Figma, Adobe XD, UI/UX prensipleri',
      'salary': '15,000 - 25,000 TL',
      'jobType': 'Tam Zamanlı',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'isActive': 1,
    });
  }

  // Tabloların varlığını kontrol et, yoksa oluştur
  Future<void> _ensureTablesExist(Database db) async {
    try {
      // Tablonun varlığını kontrol et
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      List<String> tableNames = tables.map((t) => t['name'] as String).toList();
      
      if (!tableNames.contains('users')) {
        print("users tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            fullName TEXT NOT NULL,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            bio TEXT,
            profileImage TEXT,
            location TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      }
      
      if (!tableNames.contains('education')) {
        print("education tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE education(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            school TEXT NOT NULL,
            degree TEXT,
            field TEXT,
            startDate TEXT,
            endDate TEXT,
            description TEXT,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('experience')) {
        print("experience tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE experience(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            company TEXT NOT NULL,
            title TEXT NOT NULL,
            location TEXT,
            startDate TEXT,
            endDate TEXT,
            description TEXT,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('skills')) {
        print("skills tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE skills(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            skill TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('posts')) {
        print("posts tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE posts(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            content TEXT NOT NULL,
            imageUrl TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('likes')) {
        print("likes tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE likes(
            id TEXT PRIMARY KEY,
            postId TEXT NOT NULL,
            userId TEXT NOT NULL,
            FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('connection_requests')) {
        print("connection_requests tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE connection_requests(
            id TEXT PRIMARY KEY,
            senderId TEXT NOT NULL,
            receiverId TEXT NOT NULL,
            message TEXT,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (senderId) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (receiverId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('connections')) {
        print("connections tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE connections(
            id TEXT PRIMARY KEY,
            user1Id TEXT NOT NULL,
            user2Id TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (user1Id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (user2Id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('jobs')) {
        print("jobs tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE jobs(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            title TEXT NOT NULL,
            company TEXT NOT NULL,
            location TEXT NOT NULL,
            description TEXT NOT NULL,
            requirements TEXT NOT NULL,
            salary TEXT,
            jobType TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('job_applications')) {
        print("job_applications tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE job_applications(
            id TEXT PRIMARY KEY,
            jobId TEXT NOT NULL,
            userId TEXT NOT NULL,
            resumePath TEXT,
            coverLetter TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (jobId) REFERENCES jobs (id) ON DELETE CASCADE,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (!tableNames.contains('messages')) {
        print("messages tablosu bulunamadı, oluşturuluyor...");
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            senderId TEXT NOT NULL,
            receiverId TEXT NOT NULL,
            content TEXT NOT NULL,
            isRead INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (senderId) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (receiverId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      // Demo kullanıcısını oluştur
      var user = await db.query('users', where: 'email = ?', whereArgs: ['demo@example.com']);
      if (user.isEmpty) {
        print("Demo kullanıcısı oluşturuluyor...");
        await db.insert('users', {
          'id': '1',
          'fullName': 'Demo Kullanıcı',
          'email': 'demo@example.com',
          'password': 'password123',
          'bio': 'Bu bir demo kullanıcıdır',
          'profileImage': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      
      // Admin kullanıcısını oluştur
      var adminUser = await db.query('users', where: 'email = ?', whereArgs: ['admin@example.com']);
      if (adminUser.isEmpty) {
        print("Admin kullanıcısı oluşturuluyor...");
        await db.insert('users', {
          'id': '2',
          'fullName': 'Admin Kullanıcı',
          'email': 'admin@example.com',
          'password': 'admin123',
          'bio': 'Bu bir admin kullanıcıdır',
          'profileImage': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      
    } catch (e) {
      print("Tablolar kontrol edilirken hata oluştu: $e");
    }
  }

  // Kullanıcı işlemleri
  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
    }
    return null;
  }

  Future<UserModel?> authenticateUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [email.toLowerCase(), password],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
    }
    return null;
  }

  Future<UserModel> createUser(String fullName, String email, String password) async {
    final existingUser = await getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Bu e-posta adresi zaten kullanılıyor');
    }
    
    final db = await database;
    final String id = const Uuid().v4();
    
    final user = UserModel(
      id: id,
      fullName: fullName,
      email: email.toLowerCase(),
      bio: '',
      profileImage: '',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    await db.insert('users', {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'password': password,
      'bio': user.bio,
      'profileImage': user.profileImage,
      'createdAt': user.createdAt,
    });
    
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    
    try {
      // Tüm işlemi bir transaction içinde yap
      await db.transaction((txn) async {
        // Ana kullanıcı bilgilerini güncelle
        await txn.update(
          'users',
          {
            'fullName': user.fullName,
            'bio': user.bio,
            'profileImage': user.profileImage,
            'location': user.location,
          },
          where: 'id = ?',
          whereArgs: [user.id],
        );
        
        print("Ana kullanıcı bilgileri güncellendi: ${user.fullName}");
        
        // Eğitim bilgilerini güncelle
        await txn.delete(
          'education',
          where: 'userId = ?',
          whereArgs: [user.id],
        );
        
        print("Eğitim bilgileri silindi, ${user.education.length} yeni kayıt eklenecek");
        
        for (var edu in user.education) {
          await txn.insert('education', {
            'id': edu['id'] ?? const Uuid().v4(),
            'userId': user.id,
            'school': edu['school'],
            'degree': edu['degree'] ?? '',
            'field': edu['field'] ?? '',
            'startDate': edu['startDate'] ?? '',
            'endDate': edu['endDate'] ?? '',
            'description': edu['description'] ?? '',
          });
        }
        
        // İş deneyimi bilgilerini güncelle
        await txn.delete(
          'experience',
          where: 'userId = ?',
          whereArgs: [user.id],
        );
        
        print("Deneyim bilgileri silindi, ${user.experience.length} yeni kayıt eklenecek");
        
        for (var exp in user.experience) {
          await txn.insert('experience', {
            'id': exp['id'] ?? const Uuid().v4(),
            'userId': user.id,
            'company': exp['company'],
            'title': exp['title'],
            'location': exp['location'] ?? '',
            'startDate': exp['startDate'] ?? '',
            'endDate': exp['endDate'] ?? '',
            'description': exp['description'] ?? '',
          });
        }
        
        // Beceri bilgilerini güncelle
        await txn.delete(
          'skills',
          where: 'userId = ?',
          whereArgs: [user.id],
        );
        
        print("Beceri bilgileri silindi, ${user.skills.length} yeni kayıt eklenecek");
        
        for (var skill in user.skills) {
          await txn.insert('skills', {
            'id': const Uuid().v4(),
            'userId': user.id,
            'skill': skill,
          });
        }
      });
      
      print("Tüm kullanıcı verileri başarıyla güncellendi");
    } catch (e) {
      print("Kullanıcı güncelleme hatası: $e");
      rethrow;
    }
  }
  
  // Eğitim bilgilerini getir
  Future<List<Map<String, dynamic>>> getEducation(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'education',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startDate DESC',
    );
    
    return maps;
  }
  
  // İş deneyimi bilgilerini getir
  Future<List<Map<String, dynamic>>> getExperience(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'experience',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startDate DESC',
    );
    
    return maps;
  }
  
  // Beceri bilgilerini getir
  Future<List<String>> getSkills(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'skills',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    
    return List.generate(maps.length, (i) => maps[i]['skill'] as String);
  }

  // Tam kullanıcı profilini getir (tüm bilgilerle birlikte)
  Future<UserModel?> getFullUserProfile(String userId) async {
    final db = await database;
    
    try {
      print("getFullUserProfile çağrıldı: userId=$userId");
      final List<Map<String, dynamic>> userMaps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (userMaps.isEmpty) {
        print("Kullanıcı bulunamadı: $userId");
        return null;
      }
      
      // Temel kullanıcı bilgilerini al
      final user = UserModel.fromJson(userMaps.first);
      
      // Eğitim bilgilerini al
      final education = await getEducation(userId);
      print("Eğitim bilgileri alındı: ${education.length} kayıt");
      
      // İş deneyimi bilgilerini al
      final experience = await getExperience(userId);
      print("Deneyim bilgileri alındı: ${experience.length} kayıt");
      
      // Beceri bilgilerini al
      final skills = await getSkills(userId);
      print("Beceri bilgileri alındı: ${skills.length} kayıt");
      
      // Tam profili döndür
      final fullUser = user.copyWith(
        education: education,
        experience: experience,
        skills: skills,
      );
      
      print("Tam kullanıcı profili döndürüldü:");
      print("- Bio: ${fullUser.bio}");
      print("- Education: ${fullUser.education.length} items");
      print("- Experience: ${fullUser.experience.length} items");
      print("- Skills: ${fullUser.skills.length} items");
      
      return fullUser;
    } catch (e) {
      print("Kullanıcı profili getirme hatası: $e");
      rethrow;
    }
  }

  // Gönderi işlemleri
  Future<List<PostModel>> getPosts() async {
    final db = await database;
    
    // Gönderileri ve kullanıcı bilgilerini birleştirerek getir
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, u.fullName as userName, u.profileImage as userProfileImage
      FROM posts p
      INNER JOIN users u ON p.userId = u.id
      ORDER BY p.createdAt DESC
    ''');

    List<PostModel> posts = [];
    
    for (var map in maps) {
      // Post beğenilerini getir
      final likes = await getPostLikes(map['id']);
      
      posts.add(PostModel(
        id: map['id'],
        userId: map['userId'],
        content: map['content'],
        imageUrl: map['imageUrl'],
        createdAt: map['createdAt'],
        likes: likes,
        userName: map['userName'] ?? 'Kullanıcı',
        userProfileImage: map['userProfileImage'],
      ));
    }
    
    return posts;
  }
  
  // Kullanıcının gönderilerini getir
  Future<List<PostModel>> getUserPosts(String userId) async {
    final db = await database;
    
    // Gönderileri ve kullanıcı bilgilerini birleştirerek getir
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, u.fullName as userName, u.profileImage as userProfileImage
      FROM posts p
      INNER JOIN users u ON p.userId = u.id
      WHERE p.userId = ?
      ORDER BY p.createdAt DESC
    ''', [userId]);
    
    List<PostModel> posts = [];
    
    for (var map in maps) {
      // Post beğenilerini getir
      final likes = await getPostLikes(map['id']);
      
      posts.add(PostModel(
        id: map['id'],
        userId: map['userId'],
        content: map['content'],
        imageUrl: map['imageUrl'],
        createdAt: map['createdAt'],
        likes: likes,
        userName: map['userName'] ?? 'Kullanıcı',
        userProfileImage: map['userProfileImage'],
      ));
    }
    
    return posts;
  }

  Future<PostModel> createPost(String userId, String content, String? imageUrl) async {
    final db = await database;
    final String id = const Uuid().v4();
    
    // Kullanıcı bilgilerini al
    final user = await getUserById(userId);
    if (user == null) {
      throw Exception('Kullanıcı bulunamadı');
    }
    
    final post = PostModel(
      id: id,
      userId: userId,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now().toIso8601String(),
      likes: [],
      userName: user.fullName,
      userProfileImage: user.profileImage,
    );
    
    await db.insert('posts', {
      'id': post.id,
      'userId': post.userId,
      'content': post.content,
      'imageUrl': post.imageUrl,
      'createdAt': post.createdAt,
    });
    
    return post;
  }

  Future<List<String>> getPostLikes(String postId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'likes',
      where: 'postId = ?',
      whereArgs: [postId],
    );

    return List.generate(maps.length, (i) => maps[i]['userId'] as String);
  }

  Future<void> toggleLike(String postId, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> existingLike = await db.query(
      'likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );

    if (existingLike.isEmpty) {
      // Like ekle
      await db.insert('likes', {
        'id': const Uuid().v4(),
        'postId': postId,
        'userId': userId,
      });
    } else {
      // Like kaldır
      await db.delete(
        'likes',
        where: 'postId = ? AND userId = ?',
        whereArgs: [postId, userId],
      );
    }
  }

  // Kullanıcı arama fonksiyonu
  Future<List<UserModel>> searchUsers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'fullName LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return List.generate(maps.length, (i) {
      return UserModel.fromJson(maps[i]);
    });
  }

  // Yorum ekleme fonksiyonu
  Future<void> addComment(String postId, String userId, String content) async {
    final db = await database;
    
    // Yorumlar tablosu yoksa oluştur
    await db.execute('''
      CREATE TABLE IF NOT EXISTS comments(
        id TEXT PRIMARY KEY,
        postId TEXT NOT NULL,
        userId TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Yorum ekle
    await db.insert('comments', {
      'id': const Uuid().v4(),
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
  
  // Post yorumlarını getir
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final db = await database;
    
    // Yorumlar tablosu yoksa oluştur
    await db.execute('''
      CREATE TABLE IF NOT EXISTS comments(
        id TEXT PRIMARY KEY,
        postId TEXT NOT NULL,
        userId TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'postId = ?',
      whereArgs: [postId],
      orderBy: 'createdAt DESC',
    );
    
    List<Map<String, dynamic>> commentsWithUserData = [];
    
    for (var comment in maps) {
      final userData = await getUserById(comment['userId']);
      commentsWithUserData.add({
        ...comment,
        'userName': userData?.fullName ?? 'Kullanıcı',
        'userImage': userData?.profileImage,
      });
    }
    
    return commentsWithUserData;
  }

  // Bağlantı istekleri ve bağlantılar için metodlar
  
  // Bağlantı isteği gönder
  Future<void> sendConnectionRequest(String senderId, String receiverId, String? message) async {
    final db = await database;
    
    // Zaten istek var mı kontrol et
    final existingRequests = await db.query(
      'connection_requests',
      where: '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [senderId, receiverId, receiverId, senderId],
    );
    
    if (existingRequests.isNotEmpty) {
      return; // Zaten bağlantı isteği var
    }
    
    // Zaten bağlantılı mı kontrol et
    final existingConnections = await db.query(
      'connections',
      where: '(user1Id = ? AND user2Id = ?) OR (user1Id = ? AND user2Id = ?)',
      whereArgs: [senderId, receiverId, receiverId, senderId],
    );
    
    if (existingConnections.isNotEmpty) {
      return; // Zaten bağlantı kurulmuş
    }
    
    // Yeni istek oluştur
    await db.insert('connection_requests', {
      'id': const Uuid().v4(),
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'status': 'pending', // pending, accepted, rejected
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
  
  // Bağlantı isteklerini getir
  Future<List<Map<String, dynamic>>> getConnectionRequests(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> requests = await db.query(
      'connection_requests',
      where: 'receiverId = ? AND status = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'createdAt DESC',
    );
    
    // Gönderenlerin bilgilerini ekle
    List<Map<String, dynamic>> requestsWithSenderInfo = [];
    for (var request in requests) {
      final sender = await getUserById(request['senderId']);
      if (sender != null) {
        requestsWithSenderInfo.add({
          ...request,
          'senderName': sender.fullName,
          'senderProfileImage': sender.profileImage,
        });
      }
    }
    
    return requestsWithSenderInfo;
  }
  
  // Gönderilen bağlantı isteklerini getir
  Future<List<Map<String, dynamic>>> getSentConnectionRequests(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> requests = await db.query(
      'connection_requests',
      where: 'senderId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    
    // Alıcıların bilgilerini ekle
    List<Map<String, dynamic>> requestsWithReceiverInfo = [];
    for (var request in requests) {
      final receiver = await getUserById(request['receiverId']);
      if (receiver != null) {
        requestsWithReceiverInfo.add({
          ...request,
          'receiverName': receiver.fullName,
          'receiverProfileImage': receiver.profileImage,
        });
      }
    }
    
    return requestsWithReceiverInfo;
  }
  
  // Bağlantı isteğini yanıtla (kabul et veya reddet)
  Future<void> respondToConnectionRequest(String requestId, String status) async {
    final db = await database;
    
    if (status == 'accepted' || status == 'rejected') {
      // İsteği güncelle
      await db.update(
        'connection_requests',
        {'status': status},
        where: 'id = ?',
        whereArgs: [requestId],
      );
      
      if (status == 'accepted') {
        // İsteği getir
        final List<Map<String, dynamic>> requests = await db.query(
          'connection_requests',
          where: 'id = ?',
          whereArgs: [requestId],
        );
        
        if (requests.isNotEmpty) {
          // Bağlantı oluştur
          await db.insert('connections', {
            'id': const Uuid().v4(),
            'user1Id': requests[0]['senderId'],
            'user2Id': requests[0]['receiverId'],
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }
  }
  
  // Kullanıcı bağlantılarını getir
  Future<List<Map<String, dynamic>>> getUserConnections(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> connections = await db.rawQuery('''
      SELECT * FROM connections 
      WHERE user1Id = ? OR user2Id = ?
    ''', [userId, userId]);
    
    List<Map<String, dynamic>> connectionsWithUserInfo = [];
    for (var connection in connections) {
      final String otherUserId = connection['user1Id'] == userId 
          ? connection['user2Id'] 
          : connection['user1Id'];
      
      final otherUser = await getUserById(otherUserId);
      if (otherUser != null) {
        connectionsWithUserInfo.add({
          'connectionId': connection['id'],
          'userId': otherUserId,
          'name': otherUser.fullName,
          'profileImage': otherUser.profileImage,
          'bio': otherUser.bio,
          'createdAt': connection['createdAt'],
        });
      }
    }
    
    return connectionsWithUserInfo;
  }
  
  // İki kullanıcı arasındaki bağlantı durumunu kontrol et
  Future<String> checkConnectionStatus(String userId1, String userId2) async {
    final db = await database;
    
    // Zaten bağlantılı mı kontrol et
    final existingConnections = await db.query(
      'connections',
      where: '(user1Id = ? AND user2Id = ?) OR (user1Id = ? AND user2Id = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
    );
    
    if (existingConnections.isNotEmpty) {
      return 'connected';
    }
    
    // Bekleyen istek var mı kontrol et
    final pendingRequest = await db.query(
      'connection_requests',
      where: '(senderId = ? AND receiverId = ? AND status = ?) OR (senderId = ? AND receiverId = ? AND status = ?)',
      whereArgs: [userId1, userId2, 'pending', userId2, userId1, 'pending'],
    );
    
    if (pendingRequest.isNotEmpty) {
      if (pendingRequest[0]['senderId'] == userId1) {
        return 'request_sent';
      } else {
        return 'request_received';
      }
    }
    
    return 'not_connected';
  }
  
  // Bağlantıyı kaldır
  Future<void> removeConnection(String connectionId) async {
    final db = await database;
    await db.delete(
      'connections',
      where: 'id = ?',
      whereArgs: [connectionId],
    );
  }

  // İş ilanları için metodlar
  
  // İş ilanı oluştur
  Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    final db = await database;
    final String id = const Uuid().v4();
    
    final job = {
      'id': id,
      'userId': jobData['userId'],
      'title': jobData['title'],
      'company': jobData['company'],
      'location': jobData['location'],
      'description': jobData['description'],
      'requirements': jobData['requirements'],
      'salary': jobData['salary'],
      'jobType': jobData['jobType'],
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': 1,
    };
    
    await db.insert('jobs', job);
    
    return job;
  }
  
  // İş ilanını güncelle
  Future<void> updateJob(Map<String, dynamic> jobData) async {
    final db = await database;
    
    await db.update(
      'jobs',
      {
        'title': jobData['title'],
        'company': jobData['company'],
        'location': jobData['location'],
        'description': jobData['description'],
        'requirements': jobData['requirements'],
        'salary': jobData['salary'],
        'jobType': jobData['jobType'],
        'isActive': jobData['isActive'],
      },
      where: 'id = ?',
      whereArgs: [jobData['id']],
    );
  }
  
  // İş ilanını sil
  Future<void> deleteJob(String jobId) async {
    final db = await database;
    
    await db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }
  
  // Tüm iş ilanlarını getir
  Future<List<Map<String, dynamic>>> getAllJobs() async {
    final db = await database;
    
    final List<Map<String, dynamic>> jobs = await db.query(
      'jobs',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    
    List<Map<String, dynamic>> jobsWithUserData = [];
    
    for (var job in jobs) {
      final userData = await getUserById(job['userId']);
      jobsWithUserData.add({
        ...job,
        'userName': userData?.fullName ?? 'Bilinmeyen Kullanıcı',
        'userImage': userData?.profileImage,
      });
    }
    
    return jobsWithUserData;
  }
  
  // Anahtar kelimeye göre iş ilanlarını ara
  Future<List<Map<String, dynamic>>> searchJobs(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> jobs = await db.query(
      'jobs',
      where: 'isActive = ? AND (title LIKE ? OR company LIKE ? OR description LIKE ? OR requirements LIKE ?)',
      whereArgs: [1, '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    
    List<Map<String, dynamic>> jobsWithUserData = [];
    
    for (var job in jobs) {
      final userData = await getUserById(job['userId']);
      jobsWithUserData.add({
        ...job,
        'userName': userData?.fullName ?? 'Bilinmeyen Kullanıcı',
        'userImage': userData?.profileImage,
      });
    }
    
    return jobsWithUserData;
  }
  
  // Kullanıcının iş ilanlarını getir
  Future<List<Map<String, dynamic>>> getUserJobs(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> jobs = await db.query(
      'jobs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    
    return jobs;
  }
  
  // İş ilanı detaylarını getir
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> jobs = await db.query(
      'jobs',
      where: 'id = ?',
      whereArgs: [jobId],
    );
    
    if (jobs.isEmpty) {
      return null;
    }
    
    final job = jobs.first;
    final userData = await getUserById(job['userId']);
    
    return {
      ...job,
      'userName': userData?.fullName ?? 'Bilinmeyen Kullanıcı',
      'userImage': userData?.profileImage,
    };
  }
  
  // İş başvurusu için metodlar
  
  // İş başvurusu oluştur
  Future<Map<String, dynamic>> createJobApplication(Map<String, dynamic> applicationData) async {
    final db = await database;
    final String id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    
    final application = {
      'id': id,
      'jobId': applicationData['jobId'],
      'userId': applicationData['userId'],
      'resumePath': applicationData['resumePath'],
      'coverLetter': applicationData['coverLetter'],
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    };
    
    await db.insert('job_applications', application);
    
    return application;
  }
  
  // İş başvurusunu güncelle
  Future<void> updateJobApplication(String applicationId, String status) async {
    final db = await database;
    
    await db.update(
      'job_applications',
      {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [applicationId],
    );
  }
  
  // İş ilanına yapılan başvuruları getir
  Future<List<Map<String, dynamic>>> getJobApplications(String jobId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> applications = await db.query(
      'job_applications',
      where: 'jobId = ?',
      whereArgs: [jobId],
      orderBy: 'createdAt DESC',
    );
    
    List<Map<String, dynamic>> applicationsWithUserData = [];
    
    for (var application in applications) {
      final userData = await getUserById(application['userId']);
      applicationsWithUserData.add({
        ...application,
        'userName': userData?.fullName ?? 'Bilinmeyen Kullanıcı',
        'userImage': userData?.profileImage,
        'userEmail': userData?.email,
      });
    }
    
    return applicationsWithUserData;
  }
  
  // Kullanıcının iş başvurularını getir
  Future<List<Map<String, dynamic>>> getUserApplications(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> applications = await db.query(
      'job_applications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    
    List<Map<String, dynamic>> applicationsWithJobData = [];
    
    for (var application in applications) {
      final jobData = await getJobById(application['jobId']);
      if (jobData != null) {
        applicationsWithJobData.add({
          ...application,
          'jobTitle': jobData['title'],
          'jobCompany': jobData['company'],
          'jobLocation': jobData['location'],
        });
      }
    }
    
    return applicationsWithJobData;
  }
  
  // Belirli bir kullanıcının belirli bir iş ilanına başvurup başvurmadığını kontrol et
  Future<bool> hasUserApplied(String userId, String jobId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> applications = await db.query(
      'job_applications',
      where: 'userId = ? AND jobId = ?',
      whereArgs: [userId, jobId],
    );
    
    return applications.isNotEmpty;
  }

  // Mesajlaşma işlemleri için metotlar
  
  // Mesaj gönderme
  Future<Map<String, dynamic>> sendMessage(String senderId, String receiverId, String content) async {
    final db = await database;
    final String id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    
    final message = {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'isRead': 0,
      'createdAt': now,
    };
    
    await db.insert('messages', message);
    
    return message;
  }
  
  // Kullanıcılar arasındaki mesajları getirme
  Future<List<Map<String, dynamic>>> getMessages(String userId1, String userId2) async {
    final db = await database;
    
    final List<Map<String, dynamic>> messages = await db.query(
      'messages',
      where: '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
      orderBy: 'createdAt ASC',
    );
    
    return messages;
  }
  
  // Kullanıcının tüm konuşmalarını getirme
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    final db = await database;
    
    // Son mesajların olduğu kullanıcıları getir
    final List<Map<String, dynamic>> conversations = await db.rawQuery('''
      SELECT 
        m.*, 
        u.fullName as userName, 
        u.profileImage as userProfileImage,
        u.id as userId,
        (SELECT COUNT(*) FROM messages WHERE senderId = u.id AND receiverId = ? AND isRead = 0) as unreadCount
      FROM messages m
      INNER JOIN (
        SELECT 
          CASE 
            WHEN senderId = ? THEN receiverId 
            ELSE senderId 
          END as userId,
          MAX(createdAt) as lastMessageTime
        FROM messages
        WHERE senderId = ? OR receiverId = ?
        GROUP BY userId
      ) as latest ON (latest.userId = m.senderId OR latest.userId = m.receiverId) AND m.createdAt = latest.lastMessageTime
      INNER JOIN users u ON u.id = latest.userId
      WHERE (m.senderId = ? OR m.receiverId = ?) AND u.id != ?
      ORDER BY m.createdAt DESC
    ''', [userId, userId, userId, userId, userId, userId, userId]);
    
    return conversations;
  }
  
  // Mesajları okundu olarak işaretleme
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    final db = await database;
    
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'senderId = ? AND receiverId = ? AND isRead = 0',
      whereArgs: [senderId, receiverId],
    );
  }
  
  // Okunmamış mesaj sayısını getirme
  Future<int> getUnreadMessageCount(String userId) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM messages 
      WHERE receiverId = ? AND isRead = 0
    ''', [userId]);
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Bağlantılı kullanıcıları getir
  Future<List<Map<String, dynamic>>> getConnections(String userId) async {
    final db = await database;
    
    try {
      // JOIN sorgusu yerine daha basit bir sorgu kullan
      final List<Map<String, dynamic>> connections = [];
      
      // Kullanıcının bağlantılarını al
      final List<Map<String, dynamic>> rawConnections = await db.query(
        'connections',
        where: 'user1Id = ? OR user2Id = ?',
        whereArgs: [userId, userId],
      );
      
      // Her bağlantı için diğer kullanıcıyı bul
      for (var connection in rawConnections) {
        final String otherUserId = connection['user1Id'] == userId 
            ? connection['user2Id'] 
            : connection['user1Id'];
        
        final List<Map<String, dynamic>> userMaps = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [otherUserId],
        );
        
        if (userMaps.isNotEmpty) {
          connections.addAll(userMaps);
        }
      }
      
      print("Bağlantılar başarıyla getirildi: ${connections.length} adet");
      return connections;
    } catch (e) {
      print("Bağlantıları getirirken hata: $e");
      rethrow;
    }
  }

  // Gönderi sil (Admin için)
  Future<void> deletePost(String postId) async {
    final db = await database;
    
    // Önce ilişkili beğenileri sil
    await db.delete(
      'likes',
      where: 'postId = ?',
      whereArgs: [postId],
    );
    
    // Sonra gönderiyi sil
    await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
    );
  }

  // İş başvurusu durumunu güncelle
  Future<void> updateJobApplicationStatus(String applicationId, String status) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'job_applications',
      {
        'status': status,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [applicationId],
    );
  }
  
  // İş başvurusunu sil (Admin için)
  Future<void> deleteJobApplication(String applicationId) async {
    final db = await database;
    
    await db.delete(
      'job_applications',
      where: 'id = ?',
      whereArgs: [applicationId],
    );
  }
} 