import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Real sound effects (synthesised WAVs in assets/sfx) plus haptics.
/// Players are preloaded in low-latency mode so playback is instant.
class Sfx {
  static bool enabled = true;
  static bool _ready = false;

  static const Map<String, String> _files = {
    'tap': 'sfx/tap.wav',
    'summon': 'sfx/summon.wav',
    'merge': 'sfx/merge.wav',
    'bigmerge': 'sfx/bigmerge.wav',
    'waveclear': 'sfx/waveclear.wav',
    'boss': 'sfx/boss.wav',
    'error': 'sfx/error.wav',
  };

  static final Map<String, AudioPlayer> _players = {};

  /// Preload every effect. Safe to call once at startup; failures are ignored
  /// so a device without audio never breaks the game.
  static Future<void> init() async {
    if (_ready) return;
    for (final entry in _files.entries) {
      try {
        final p = AudioPlayer(playerId: 'sfx_${entry.key}');
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource(entry.value));
        await p.setVolume(0.9);
        _players[entry.key] = p;
      } catch (e) {
        debugPrint('Sfx: failed to load ${entry.key}: $e');
      }
    }
    _ready = true;
  }

  static void _play(String key) {
    if (!enabled) return;
    final p = _players[key];
    if (p == null) return;
    // Restart from the top so rapid repeats always retrigger.
    p.seek(Duration.zero).then((_) => p.resume()).catchError((_) {});
  }

  static void tap() {
    HapticFeedback.selectionClick();
    _play('tap');
  }

  static void summon() {
    HapticFeedback.lightImpact();
    _play('summon');
  }

  static void merge() {
    HapticFeedback.mediumImpact();
    _play('merge');
  }

  static void bigMerge() {
    HapticFeedback.heavyImpact();
    _play('bigmerge');
  }

  static void waveClear() {
    HapticFeedback.mediumImpact();
    _play('waveclear');
  }

  static void boss() {
    HapticFeedback.heavyImpact();
    _play('boss');
  }

  static void error() {
    HapticFeedback.vibrate();
    _play('error');
  }
}
