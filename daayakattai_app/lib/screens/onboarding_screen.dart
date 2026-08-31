import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MaterialApp(
    home: OnboardingScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _playNow() {
    final name = _nameController.text.trim();
    Navigator.pop(context, name.isEmpty ? 'Player' : name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B0A0A),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40, right: 20),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFFD9A843),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              // PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _WelcomePage(),
                    _HowToPlayPage(),
                    _GetStartedPage(
                      nameController: _nameController,
                      onPlayNow: _playNow,
                    ),
                  ],
                ),
              ),
              // Dot indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: _currentPage == index ? 24 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFD9A843)
                            : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Page 1: Welcome
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Daayakattai',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD9A843),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'தமிழரின் பாரம்பரிய விளையாட்டு',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFFF1E4C4),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'The Ancient Tamil Board Game',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFF1E4C4),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Custom 7x7 grid illustration
          CustomPaint(
            size: const Size(280, 280),
            painter: _GridPainter(),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the 7x7 grid
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 7;
    final random = Random(42); // Fixed seed for consistent pattern

    // Draw cells
    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < 7; col++) {
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        // Alternate colors with some randomness
        final isSpecial = (row + col) % 3 == 0;
        final color = isSpecial
            ? const Color(0xFFD9A843).withValues(alpha: 0.8)
            : const Color(0xFF3F0E0E).withValues(alpha: 0.9);

        // Draw cell background
        canvas.drawRect(rect, Paint()..color = color);

        // Draw cell border
        canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFFD9A843).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Draw some decorative dots
        if (random.nextBool() && !isSpecial) {
          final dotPaint = Paint()
            ..color = const Color(0xFFF1E4C4).withValues(alpha: 0.3);
          canvas.drawCircle(
            rect.center,
            cellSize * 0.15,
            dotPaint,
          );
        }
      }
    }

    // Draw outer border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color(0xFFD9A843)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Page 2: How to Play
class _HowToPlayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rules = [
      {
        'icon': Icons.casino,
        'text': 'Roll dice (1,5,6,12 = bonus roll)',
      },
      {
        'icon': Icons.people,
        'text': 'Pairs (Jodu) block enemies',
      },
      {
        'icon': Icons.cut,
        'text': 'Capture (Vettu) to enter inner track',
      },
      {
        'icon': Icons.emoji_events,
        'text': 'First team to finish all pieces wins',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How to Play / விளையாடுவது எப்படி',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD9A843),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ...rules.map((rule) => _RuleCard(
                icon: rule['icon'] as IconData,
                text: rule['text'] as String,
              )),
        ],
      ),
    );
  }
}

// Rule card widget
class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3F0E0E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD9A843),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFD9A843),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFF1E4C4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Page 3: Get Started
class _GetStartedPage extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onPlayNow;

  const _GetStartedPage({
    required this.nameController,
    required this.onPlayNow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Start Playing!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD9A843),
            ),
          ),
          const SizedBox(height: 40),
          // Name input field
          TextField(
            controller: nameController,
            style: const TextStyle(
              color: Color(0xFFF1E4C4),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(
                color: const Color(0xFFF1E4C4).withValues(alpha: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFD9A843),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFD9A843),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Play Now button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onPlayNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9A843),
                foregroundColor: const Color(0xFF2B0A0A),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Play Now',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}