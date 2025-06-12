import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../profile/profile_screen.dart';
import '../messaging/conversations_screen.dart';
import '../connections/connection_requests_screen.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import '../jobs/jobs_screen.dart';
import '../jobs/my_jobs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const FeedScreen(),
      const JobsScreen(),
      const ConversationsScreen(),
      const MyJobsScreen(),
      ProfileScreen(userId: Provider.of<AuthProvider>(context, listen: false).user?.id),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Mesaj ve bağlantı istekleri sayısını yükle
    if (authProvider.user != null) {
      messageProvider.getUnreadMessageCount(authProvider.user!.id).then((count) {
        // Bu değeri UI'da göstermek için kullanacağız
      });
      
      // Bağlantı isteklerini kontrol et
      userProvider.getConnectionRequests(authProvider.user!.id).then((requests) {
        // Bağlantı istekleri varsa bildirim gösterilebilir
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConnectionRequestsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'İş İlanları',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'İlanlarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
} 