import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/effects.dart';

/// A friendly, scrollable guide: how to play and how to win.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground(scenery: false)),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                    children: const [
                      _Step(
                        emoji: '⚔️',
                        title: '1 · Summon units',
                        body: 'Tap SUMMON to drop a new unit onto the board. '
                            'Each summon costs a little gold and gets slightly '
                            'pricier — so spend wisely.',
                      ),
                      _Step(
                        emoji: '✨',
                        title: '2 · Merge to grow',
                        body: 'Drag one unit onto another of the SAME level. '
                            'They fuse into the next tier — bigger, shinier and '
                            'far more powerful. Dropping onto an empty cell just '
                            'moves the unit.',
                      ),
                      _Step(
                        emoji: '🏰',
                        title: '3 · Auto-battle',
                        body: 'Your whole army fights on its own. The combined '
                            'power of every unit on the board is your damage per '
                            'second — the stronger your board, the faster enemies '
                            'fall.',
                      ),
                      _Step(
                        emoji: '💰',
                        title: '4 · Earn & spend',
                        body: 'Defeating enemies drops gold. Reinvest it into more '
                            'summons, then merge those into higher tiers. This is '
                            'the loop: summon → merge → power up → repeat.',
                      ),
                      _Step(
                        emoji: '👑',
                        title: '5 · Bosses & gems',
                        body: 'Every 5th wave is a BOSS with huge health. Beat it '
                            'to earn 💎 gems. Spend 2 gems on BOOST for double '
                            'damage for 8 seconds — perfect for tough bosses.',
                      ),
                      _Step(
                        emoji: '✦',
                        title: '6 · Rebirth (Prestige)',
                        body: 'Reach wave 10 to unlock Rebirth. Resetting your run '
                            'grants Prestige Points, each giving a PERMANENT +25% '
                            'army power. Gems and your Codex are always kept.',
                      ),
                      SizedBox(height: 10),
                      _WinCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Text('How to Play',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String emoji, title, body;
  const _Step({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinCard extends StatelessWidget {
  const _WinCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 26)),
              SizedBox(width: 10),
              Text('How to Win',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'There is no final boss — the goal is to push your wave count and '
            'unit tier as high as possible.\n\n'
            '• Always keep merging: two Lv2s beat four Lv1s.\n'
            '• Leave one empty cell so you can always summon.\n'
            '• Save BOOST for bosses.\n'
            '• Rebirth often once it pays out — the permanent bonus '
            'compounds and lets you blast past your old best.',
            style: TextStyle(
                fontSize: 13.5, height: 1.5, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
