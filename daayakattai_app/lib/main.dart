import 'package:flutter/material.dart';
import 'daayakattai_board.dart';
import 'agora_video_header.dart'; // Bubble video integration placeholder

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
        scaffoldBackgroundColor: const Color(0xFF3F0E0E), // Match the raw silk red background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD9A843), // Gold/Brass seed color
          brightness: Brightness.dark,
          primary: const Color(0xFFD9A843),
          secondary: const Color(0xFFD62E2E), // Red Team color
        ),
        useMaterial3: true,
        fontFamily: 'Outfit', // High-end premium typography font fallback
      ),
      home: const DaayakattaiGameScreen(),
    );
  }
}

class DaayakattaiGameScreen extends StatelessWidget {
  const DaayakattaiGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Agora Video Header integrated at the top
            AgoraVideoHeader(channelName: 'family-daayakattai-room'),
            
            // Scaled Game Board
            Expanded(
              child: DaayakattaiBoard(),
            ),
          ],
        ),
      ),
    );
  }
}
