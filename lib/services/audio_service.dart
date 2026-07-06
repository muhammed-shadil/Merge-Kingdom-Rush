import 'package:flutter/services.dart';

/// Lightweight feedback layer — haptics + built-in system clicks, no assets.
/// (Swap these for real SFX later by dropping an audio package in here.)
class Sfx {
  static bool enabled = true;

  static void tap() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  static void summon() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  static void merge() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void bigMerge() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void waveClear() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void boss() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void error() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }
}
