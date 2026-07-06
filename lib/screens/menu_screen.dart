import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../theme/app_theme.dart';
import '../widgets/effects.dart';
import 'codex_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';

/// The home hub: play, learn, collect and rebirth.
class MenuScreen extends StatefulWidget {
  final GameData data;
  final double offlineGold;
  const MenuScreen({super.key, required this.data, this.offlineGold = 0});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  GameData get d => widget.data;

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    if (widget.offlineGold > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOffline());
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _showOffline() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.bg2, AppColors.bg1],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 46)),
              const SizedBox(height: 8),
              const Text('Welcome back!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 10),
              const Text('Your army kept fighting while you were away:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Text('💰 +${fmt(widget.offlineGold)}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold)),
              const SizedBox(height: 18),
              GlowButton(
                gradient: const [AppColors.gold, Color(0xFFFF6A00)],
                onTap: () {
                  Sfx.tap();
                  Navigator.pop(ctx);
                },
                child: const Text('COLLECT',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _play() async {
    Sfx.tap();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(data: d)),
    );
    if (mounted) setState(() {}); // refresh stats after returning
  }

  void _prestige() {
    if (!d.canPrestige) {
      Sfx.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reach wave 10 in a run to unlock Rebirth.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.bg2,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('👑 Rebirth?', style: AppText.heading),
        content: Text(
          'Reset your run to gain ${d.pendingPrestige} Prestige Point(s), '
          'each giving a permanent +25% army power.\n\n'
          'Gems and Codex are kept.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.magenta),
            onPressed: () {
              Sfx.boss();
              d.prestige();
              SaveService.save(d);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Rebirth'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: FadeTransition(
              opacity: _in,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _logo(),
                    const SizedBox(height: 18),
                    _statsStrip(),
                    const Spacer(flex: 2),
                    GlowButton(
                      gradient: const [AppColors.green, Color(0xFF12B39B)],
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      onTap: _play,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text('PLAY',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 2,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _menuButton(
                            const [AppColors.cyan, Color(0xFF0091EA)],
                            Icons.help_outline_rounded,
                            'How to Play',
                            () {
                              Sfx.tap();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HowToPlayScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _menuButton(
                            const [AppColors.purple, Color(0xFF6A2CD8)],
                            Icons.auto_awesome_mosaic_rounded,
                            'Codex',
                            () {
                              Sfx.tap();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CodexScreen(data: d)));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _menuButton(
                      d.canPrestige
                          ? const [AppColors.magenta, AppColors.purple]
                          : const [Color(0xFF3A3550), Color(0xFF2A2740)],
                      Icons.autorenew_rounded,
                      d.canPrestige
                          ? 'Rebirth  ·  +${d.pendingPrestige} ✦'
                          : 'Rebirth  ·  reach wave 10',
                      _prestige,
                      full: true,
                    ),
                    const Spacer(flex: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _soundToggle(),
                        const SizedBox(width: 8),
                        const Text('Merge Kingdom Rush  ·  v1.0',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.magenta]),
            boxShadow: [
              BoxShadow(
                  color: AppColors.magenta.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 2),
            ],
          ),
          child: const Text('👑', style: TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 14),
        const Text('MERGE KINGDOM',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white)),
        const Text('RUSH',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: AppColors.gold)),
      ],
    );
  }

  Widget _statsStrip() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Best Wave', '${d.highestWave}', AppColors.cyan),
          _divider(),
          _statItem('Top Tier', tierFor(d.codexMaxLevel).emoji, Colors.white),
          _divider(),
          _statItem('Prestige', '${d.prestigePoints} ✦', AppColors.magenta),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: Colors.white12);

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _menuButton(
      List<Color> gradient, IconData icon, String label, VoidCallback onTap,
      {bool full = false}) {
    return GlowButton(
      gradient: gradient,
      padding: const EdgeInsets.symmetric(vertical: 15),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _soundToggle() {
    return GestureDetector(
      onTap: () async {
        Sfx.enabled = !Sfx.enabled;
        await SaveService.saveSfx(Sfx.enabled);
        Sfx.tap();
        setState(() {});
      },
      child: Icon(
        Sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: Colors.white54,
        size: 18,
      ),
    );
  }
}
