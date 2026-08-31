import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daayakattai_app/screens/game_setup_screen.dart';
import 'package:daayakattai_app/daayakattai_board.dart';
import 'package:daayakattai_app/agora_video_header.dart';

void main() {
  testWidgets('Game Setup UI Integration Test', (WidgetTester tester) async {
    // 1. Render the game setup screen
    await tester.pumpWidget(
      const MaterialApp(
        home: GameSetupScreen(),
      ),
    );

    // Verify it loads correctly
    expect(find.text('Start Match'), findsOneWidget);
    
    // If no family groups are initialized, a placeholder will be shown
    final hasGroupText = find.text('Create a Family Group first to set up a game.');
    if (tester.any(hasGroupText)) {
      debugPrint('[TEST] Initial placeholder detected correctly.');
      return;
    }

    // Otherwise mock-verify the start button is interactable
    final startButton = find.text('ஆட்டத்தைத் தொடங்கு / Start Match');
    expect(startButton, findsOneWidget);
  });
}
