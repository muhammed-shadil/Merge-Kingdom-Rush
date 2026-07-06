import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_data.dart';

/// Persists a [GameData] to local storage and computes offline earnings.
class SaveService {
  static const _key = 'merge_kingdom_save_v1';
  static const _sfxKey = 'sfx_enabled';

  /// Max time (seconds) that offline earnings accrue for — 4 hours.
  static const _offlineCapSec = 4 * 60 * 60;

  static Future<GameData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return GameData.fresh();
    try {
      return GameData.decode(raw);
    } catch (_) {
      return GameData.fresh();
    }
  }

  static Future<void> save(GameData data) async {
    final prefs = await SharedPreferences.getInstance();
    data.lastSeenMs = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_key, data.encode());
  }

  static Future<bool> loadSfx() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sfxKey) ?? true;
  }

  static Future<void> saveSfx(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, enabled);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Gold earned while away, based on time elapsed since [GameData.lastSeenMs].
  /// Returns 0 if the gap is trivially short or there is no prior save.
  static double offlineGold(GameData data) {
    if (data.lastSeenMs == 0) return 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = (nowMs - data.lastSeenMs) / 1000.0;
    if (elapsedSec < 60) return 0;
    final capped = elapsedSec.clamp(0, _offlineCapSec.toDouble());
    final perSec = data.wave * 2 + data.armyPower * 0.03;
    return capped * perSec;
  }
}
