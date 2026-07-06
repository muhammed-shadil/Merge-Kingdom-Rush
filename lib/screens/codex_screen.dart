import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../widgets/effects.dart';
import '../widgets/unit_tile.dart';

/// The collection screen — every tier, with locked ones hidden until discovered.
class CodexScreen extends StatelessWidget {
  final GameData data;
  const CodexScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final discovered = data.codexMaxLevel;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground(scenery: false)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const Text('Codex',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const Spacer(),
                      Text('$discovered / $kMaxLevel',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold)),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: kMaxLevel,
                    itemBuilder: (context, i) {
                      final level = i + 1;
                      final unlocked = level <= discovered;
                      return _CodexCard(level: level, unlocked: unlocked);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodexCard extends StatelessWidget {
  final int level;
  final bool unlocked;
  const _CodexCard({required this.level, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final tier = tierFor(level);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (unlocked)
            UnitCard(level: level, size: 58)
          else
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.white30),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  unlocked ? tier.name : '???',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: unlocked ? Colors.white : Colors.white38,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Tier $level',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 13, color: AppColors.cyan),
                    Text(
                      unlocked ? fmt(tier.power) : '—',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cyan),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
