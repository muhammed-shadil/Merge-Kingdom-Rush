import 'dart:convert';
import 'game_models.dart';

/// The full persistent state of a save. Mutated in-place by the game screen and
/// serialised to JSON by [SaveService].
class GameData {
  double gold;
  int gems;
  int wave;
  int totalSummons;
  int bestLevel; // best tier in the *current* run
  int highestWave; // best wave reached this run (for prestige payout)
  int codexMaxLevel; // best tier ever reached (permanent, survives prestige)
  int prestigePoints; // permanent, each grants a DPS bonus
  List<int> board; // length kBoardSize; 0 = empty, else unit level
  int lastSeenMs; // epoch millis of last save (for offline earnings)

  GameData({
    required this.gold,
    required this.gems,
    required this.wave,
    required this.totalSummons,
    required this.bestLevel,
    required this.highestWave,
    required this.codexMaxLevel,
    required this.prestigePoints,
    required this.board,
    required this.lastSeenMs,
  });

  /// A brand-new save with a small starter army.
  factory GameData.fresh() {
    final board = List<int>.filled(kBoardSize, 0);
    board[0] = 1;
    board[1] = 1;
    board[2] = 2;
    return GameData(
      gold: 80,
      gems: 0,
      wave: 1,
      totalSummons: 0,
      bestLevel: 2,
      highestWave: 1,
      codexMaxLevel: 2,
      prestigePoints: 0,
      board: board,
      lastSeenMs: 0,
    );
  }

  // ---- Derived values ---------------------------------------------------
  double get prestigeMult => 1 + prestigePoints * 0.25;

  double get rawArmyPower {
    double t = 0;
    for (final lv in board) {
      if (lv > 0) t += powerFor(lv);
    }
    return t;
  }

  double get armyPower => rawArmyPower * prestigeMult;

  // ---- Prestige ---------------------------------------------------------
  /// Points you'd earn by prestiging right now.
  int get pendingPrestige => highestWave ~/ 10;
  bool get canPrestige => pendingPrestige >= 1;

  /// Rebirth: wipe the run for a permanent power multiplier. Keeps gems,
  /// prestige points and the codex.
  void prestige() {
    prestigePoints += pendingPrestige;
    gold = 80;
    wave = 1;
    highestWave = 1;
    totalSummons = 0;
    bestLevel = 2;
    board = List<int>.filled(kBoardSize, 0);
    board[0] = 1;
    board[1] = 1;
    board[2] = 2;
  }

  // ---- Serialisation ----------------------------------------------------
  Map<String, dynamic> toMap() => {
        'gold': gold,
        'gems': gems,
        'wave': wave,
        'totalSummons': totalSummons,
        'bestLevel': bestLevel,
        'highestWave': highestWave,
        'codexMaxLevel': codexMaxLevel,
        'prestigePoints': prestigePoints,
        'board': board,
        'lastSeenMs': lastSeenMs,
      };

  String encode() => jsonEncode(toMap());

  static GameData decode(String s) {
    final m = jsonDecode(s) as Map<String, dynamic>;
    final rawBoard = (m['board'] as List).map((e) => (e as num).toInt()).toList();
    final board = List<int>.filled(kBoardSize, 0);
    for (var i = 0; i < kBoardSize && i < rawBoard.length; i++) {
      board[i] = rawBoard[i];
    }
    return GameData(
      gold: (m['gold'] as num).toDouble(),
      gems: (m['gems'] as num).toInt(),
      wave: (m['wave'] as num).toInt(),
      totalSummons: (m['totalSummons'] as num).toInt(),
      bestLevel: (m['bestLevel'] as num).toInt(),
      highestWave: (m['highestWave'] as num?)?.toInt() ?? 1,
      codexMaxLevel: (m['codexMaxLevel'] as num?)?.toInt() ?? 1,
      prestigePoints: (m['prestigePoints'] as num?)?.toInt() ?? 0,
      board: board,
      lastSeenMs: (m['lastSeenMs'] as num?)?.toInt() ?? 0,
    );
  }
}
