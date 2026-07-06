import 'package:flutter/material.dart';

/// A single power tier. Merging two identical units produces the next tier up.
class Tier {
  final String name;
  final String emoji;
  final List<Color> gradient;
  final double power;
  const Tier(this.name, this.emoji, this.gradient, this.power);
}

const int kBoardCols = 5;
const int kBoardRows = 4;
const int kBoardSize = kBoardCols * kBoardRows;

/// The full progression ladder. Level is 1-based → index = level - 1.
const List<Tier> kTiers = [
  Tier('Slime', '🟢', [Color(0xFF3AE374), Color(0xFF12B39B)], 3),
  Tier('Imp', '👾', [Color(0xFF5B7CFA), Color(0xFF3A2FD8)], 9),
  Tier('Wolf', '🐺', [Color(0xFF9AA7B5), Color(0xFF4A5568)], 24),
  Tier('Golem', '🗿', [Color(0xFFC98A46), Color(0xFF7A4E1E)], 60),
  Tier('Knight', '⚔️', [Color(0xFF31E7FF), Color(0xFF0091EA)], 150),
  Tier('Mage', '🔮', [Color(0xFFB07CFF), Color(0xFF6A2CD8)], 380),
  Tier('Dragon', '🐉', [Color(0xFFFF6B6B), Color(0xFFD81E5B)], 950),
  Tier('Phoenix', '🔥', [Color(0xFFFFD23C), Color(0xFFFF6A00)], 2400),
];

int get kMaxLevel => kTiers.length;

Tier tierFor(int level) => kTiers[(level - 1).clamp(0, kTiers.length - 1)];

double powerFor(int level) => tierFor(level).power;

/// A unit sitting on the merge board. [id] is stable across moves/merges so
/// widgets can keep their animation state.
class BoardUnit {
  final int id;
  int level;
  BoardUnit(this.id, this.level);
}

/// Compact number formatting: 1.2K, 3.4M, 5.6B.
String fmt(num n) {
  if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}
