import 'package:flutter/material.dart';
import 'agora_video_header.dart';
import 'screens/profile_screen.dart';
import 'screens/family_group_screen.dart';
import 'screens/game_setup_screen.dart';
import 'screens/stats_screen.dart';

void main() {
  runApp(const DaayakattaiApp());
}

class DaayakattaiApp extends StatelessWidget {
  const DaayakattaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Daayakattai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF3F0E0E), // Match raw silk red
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD9A843), // Gold/Brass seed color
          brightness: Brightness.dark,
          primary: const Color(0xFFD9A843),
          secondary: const Color(0xFFD62E2E), // Red Team color
        ),
        useMaterial3: true,
        fontFamily: 'Outfit', // High-end premium typography font fallback
      ),
      home: const DaayakattaiDashboardScreen(),
    );
  }
}

class DaayakattaiDashboardScreen extends StatefulWidget {
  const DaayakattaiDashboardScreen({super.key});

  @override
  State<DaayakattaiDashboardScreen> createState() => _DaayakattaiDashboardScreenState();
}

class _DaayakattaiDashboardScreenState extends State<DaayakattaiDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const GameSetupScreen(),
    const ProfileScreen(),
    const FamilyGroupScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Agora Video Header integrated persistently at the top
            const AgoraVideoHeader(channelName: 'family-daayakattai-room'),
            
            // Scaled Tab Page View
            Expanded(
              child: _tabs[_currentIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF3F0E0E),
        selectedItemColor: const Color(0xFFD9A843),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle_filled),
            label: 'Start Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profiles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
