import 'dart:async';

import 'package:flutter/services.dart';

/// Accessibility service for Daayakattai.
///
/// Provides "Grandparent Mode" settings, font scaling, tap target sizing,
/// and haptic feedback. Persistence is simulated with an in-memory static
/// map for now (no external packages).
class DaayakattaiAccessibilityService {
  DaayakattaiAccessibilityService._();

  /// Whether Grandparent Mode is enabled.
  static bool grandparentMode = false;

  /// Simple in-memory storage simulating SharedPreferences.
  static final Map<String, dynamic> _prefs = {};

  /// Key used for storing the grandparent mode preference.
  static const String _grandparentModeKey = 'grandparentMode';

  /// Base font size depending on mode.
  static double get baseFontSize => grandparentMode ? 22.0 : 16.0;

  /// Title font size depending on mode.
  static double get titleFontSize => grandparentMode ? 28.0 : 20.0;

  /// Button font size depending on mode.
  static double get buttonFontSize => grandparentMode ? 24.0 : 18.0;

  /// Minimum tap target size depending on mode.
  static double get minTapTarget => grandparentMode ? 64.0 : 48.0;

  /// Loads saved preferences on startup.
  static Future<void> load() async {
    // Simulate async loading from persistent storage.
    await Future<void>.delayed(Duration.zero);
    final savedValue = _prefs[_grandparentModeKey];
    if (savedValue is bool) {
      grandparentMode = savedValue;
    }
  }

  /// Sets Grandparent Mode, persists it, and triggers haptic feedback.
  static Future<void> setGrandparentMode(bool enabled) async {
    grandparentMode = enabled;
    _prefs[_grandparentModeKey] = enabled;
    await HapticFeedback.mediumImpact();
  }

  /// Provides haptic feedback when a UI element is tapped.
  static void speakOnTap() {
    // fire-and-forget haptic selection click
    unawaited(HapticFeedback.selectionClick());
  }
}