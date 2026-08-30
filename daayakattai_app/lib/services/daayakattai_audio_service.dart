import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class DaayakattaiAudioService {
  // Singleton instance
  static final DaayakattaiAudioService _instance = DaayakattaiAudioService._internal();
  factory DaayakattaiAudioService() => _instance;
  DaayakattaiAudioService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Tamil number translations for dice rolls (1-12)
  static const Map<int, String> _tamilNumbers = {
    1: 'தாயம்',
    2: 'இரண்டு',
    3: 'மூன்று',
    4: 'நான்கு',
    5: 'ஐந்து',
    6: 'ஆறு',
    7: 'ஏழு',
    8: 'எட்டு',
    9: 'ஒன்பது',
    10: 'பத்து',
    11: 'பதினொன்று',
    12: 'பன்னிரண்டு',
  };

  /// Initialize the TTS engine with Tamil settings
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Set language to Tamil (India)
      await _flutterTts.setLanguage('ta-IN');
      // Set pitch for clear, natural voice
      await _flutterTts.setPitch(1.0);
      // Slow speech rate for elderly-friendly clarity
      await _flutterTts.setSpeechRate(0.45);
      // Set volume to maximum for better audibility
      await _flutterTts.setVolume(1.0);

      // Set completion handler to reset speaking flag
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((error) {
        _isSpeaking = false;
        debugPrint('TTS Error: $error');
      });

      _isInitialized = true;
      debugPrint('DaayakattaiAudioService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize TTS: $e');
      _isInitialized = false;
    }
  }

  /// Internal method to speak text with error handling
  Future<void> _speak(String text) async {
    if (!_isInitialized) {
      debugPrint('TTS not initialized. Attempting to initialize...');
      await init();
      if (!_isInitialized) {
        debugPrint('TTS initialization failed. Cannot speak: $text');
        return;
      }
    }

    try {
      if (_isSpeaking) {
        // Stop any ongoing speech before speaking new text
        await _flutterTts.stop();
      }
      _isSpeaking = true;
      await _flutterTts.speak(text);
      debugPrint('Speaking: $text');
    } catch (e) {
      _isSpeaking = false;
      debugPrint('Failed to speak: $e');
    }
  }

  /// Announce dice roll value in Tamil
  Future<void> speakRoll(int value) async {
    if (value < 1 || value > 12) {
      debugPrint('Invalid dice roll value: $value');
      return;
    }

    String tamilNumber = _tamilNumbers[value] ?? 'தெரியவில்லை';
    String message = 'தாயம் $tamilNumber';
    await _speak(message);
  }

  /// Announce player's turn in Tamil
  Future<void> speakTurn(String playerName) async {
    if (playerName.isEmpty) {
      debugPrint('Empty player name provided');
      return;
    }

    String message = '$playerName, உங்கள் முறை';
    await _speak(message);
  }

  /// Announce pawn capture in Tamil
  Future<void> speakCut() async {
    await _speak('வெட்டு! காய் வெட்டப்பட்டது!');
  }

  /// Announce 3-strike forfeit in Tamil
  Future<void> speakForfeit() async {
    await _speak('மூன்று முறை தாயம்! வாய்ப்பு இழந்தது.');
  }

  /// Announce victory celebration in Tamil
  Future<void> speakVictory(int teamId) async {
    if (teamId <= 0) {
      debugPrint('Invalid team ID: $teamId');
      return;
    }

    String message = 'வெற்றி! குழு $teamId வெற்றி பெற்றது!';
    await _speak(message);
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Failed to stop TTS: $e');
    }
  }

  /// Dispose the TTS engine
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      _isInitialized = false;
      _isSpeaking = false;
      debugPrint('DaayakattaiAudioService disposed');
    } catch (e) {
      debugPrint('Failed to dispose TTS: $e');
    }
  }
}