import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../theme/app_theme.dart';
import '../widgets/battle_arena.dart';
import '../widgets/effects.dart';
import '../widgets/merge_grid.dart';
import 'codex_screen.dart';
import 'how_to_play_screen.dart';

class GameScreen extends StatefulWidget {
  final GameData data;
  const GameScreen({super.key, required this.data});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  GameData get d => widget.data;

  final List<BoardUnit?> _units = List.filled(kBoardSize, null);
  int _nextId = 0;

  late double _enemyMaxHp;
  late double _enemyHp;
  int _boostTicksLeft = 0;

  Timer? _timer;
  int _tick = 0;
  String? _banner;

  static const _tickMs = 100;

  bool get _isBoss => d.wave % 5 == 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (var i = 0; i < kBoardSize; i++) {
      if (d.board[i] > 0) _units[i] = BoardUnit(_nextId++, d.board[i]);
    }
    _enemyMaxHp = _hpForWave(d.wave);
    _enemyHp = _enemyMaxHp;
    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), _onTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _saveNow();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _saveNow();
  }

  // ---------------------------------------------------------------- persistence
  void _commitBoard() {
    for (var i = 0; i < kBoardSize; i++) {
      d.board[i] = _units[i]?.level ?? 0;
    }
  }

  void _saveNow() {
    _commitBoard();
    SaveService.save(d);
  }

  // ---------------------------------------------------------------- economy
  double _hpForWave(int w) {
    final base = 45 * math.pow(1.32, w - 1).toDouble();
    return w % 5 == 0 ? base * 4.5 : base;
  }

  int get _summonCost => (10 * math.pow(1.12, d.totalSummons)).round();

  double get _rawArmyPower {
    double total = 0;
    for (final u in _units) {
      if (u != null) total += powerFor(u.level);
    }
    return total;
  }

  double get _armyPower => _rawArmyPower * d.prestigeMult;
  double get _dps => _armyPower * (_boostTicksLeft > 0 ? 2 : 1);

  // ---------------------------------------------------------------- loop
  void _onTick(Timer _) {
    _tick++;
    setState(() {
      final dmg = _dps * (_tickMs / 1000.0);
      if (dmg > 0 && _enemyHp > 0) {
        _enemyHp -= dmg;
        if (_enemyHp <= 0) _onEnemyDefeated();
      }
      if (_boostTicksLeft > 0) _boostTicksLeft--;
      if (_tick % 10 == 0) d.gold += 1 + d.wave.toDouble();
    });
    if (_tick % 50 == 0) _saveNow(); // autosave every 5s
  }

  void _onEnemyDefeated() {
    final boss = _isBoss;
    final reward = (6 * d.wave + 10) * (boss ? 3 : 1);
    d.gold += reward;
    if (boss) {
      d.gems += 2;
      Sfx.boss();
    } else {
      Sfx.waveClear();
    }

    d.wave++;
    if (d.wave > d.highestWave) d.highestWave = d.wave;
    _enemyMaxHp = _hpForWave(d.wave);
    _enemyHp = _enemyMaxHp;

    _banner = _isBoss ? 'BOSS INCOMING!' : 'WAVE ${d.wave}';
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  // ---------------------------------------------------------------- board ops
  int? get _firstEmpty {
    for (var i = 0; i < kBoardSize; i++) {
      if (_units[i] == null) return i;
    }
    return null;
  }

  void _summon() {
    if (d.gold < _summonCost) {
      Sfx.error();
      _toast('Not enough gold — defeat enemies to earn more!');
      return;
    }
    final slot = _firstEmpty;
    if (slot == null) {
      Sfx.error();
      _toast('Board full! Merge units to make space.');
      return;
    }
    Sfx.summon();
    setState(() {
      d.gold -= _summonCost;
      d.totalSummons++;
      _units[slot] = BoardUnit(_nextId++, 1);
    });
  }

  void _handleDrop(int from, int to) {
    if (from == to) return;
    final a = _units[from];
    final b = _units[to];
    if (a == null) return;

    setState(() {
      if (b == null) {
        _units[to] = a;
        _units[from] = null;
      } else if (b.level == a.level && b.level < kMaxLevel) {
        b.level += 1;
        _units[from] = null;
        d.bestLevel = math.max(d.bestLevel, b.level);
        d.codexMaxLevel = math.max(d.codexMaxLevel, b.level);
        d.gold += powerFor(b.level);
        if (b.level >= 6) {
          Sfx.bigMerge();
        } else {
          Sfx.merge();
        }
      } else {
        _units[from] = b;
        _units[to] = a;
        Sfx.tap();
      }
    });
  }

  void _boost() {
    if (_boostTicksLeft > 0) return;
    if (d.gems < 2) {
      Sfx.error();
      _toast('Need 2 gems — beat a boss (every 5th wave) to earn gems.');
      return;
    }
    Sfx.tap();
    setState(() {
      d.gems -= 2;
      _boostTicksLeft = (8000 / _tickMs).round();
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.bg2,
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  // ---------------------------------------------------------------- menus
  void _openPauseSheet() {
    Sfx.tap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PauseSheet(
        data: d,
        onResume: () => Navigator.pop(ctx),
        onHowTo: () {
          Navigator.pop(ctx);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HowToPlayScreen()));
        },
        onCodex: () {
          Navigator.pop(ctx);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => CodexScreen(data: d)));
        },
        onPrestige: () {
          Navigator.pop(ctx);
          _confirmPrestige();
        },
        onQuit: () {
          _saveNow();
          Navigator.pop(ctx);
          Navigator.pop(context); // back to menu
        },
      ),
    );
  }

  void _confirmPrestige() {
    if (!d.canPrestige) {
      _toast('Reach wave 10 to unlock Rebirth (Prestige).');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('👑 Rebirth?', style: AppText.heading),
        content: Text(
          'Reset your run (gold, board, wave) to gain '
          '${d.pendingPrestige} Prestige Point(s).\n\n'
          'Each point permanently boosts your army by +25% power.\n\n'
          'Your gems, codex and prestige bonus are kept.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.magenta),
            onPressed: () {
              Navigator.pop(ctx);
              _doPrestige();
            },
            child: const Text('Rebirth'),
          ),
        ],
      ),
    );
  }

  void _doPrestige() {
    Sfx.boss();
    setState(() {
      d.prestige();
      for (var i = 0; i < kBoardSize; i++) {
        _units[i] = d.board[i] > 0 ? BoardUnit(_nextId++, d.board[i]) : null;
      }
      _boostTicksLeft = 0;
      _enemyMaxHp = _hpForWave(d.wave);
      _enemyHp = _enemyMaxHp;
      _banner = 'REBORN! +${d.prestigePoints} ✦';
    });
    _saveNow();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground(scenery: false)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  _topBar(),
                  const SizedBox(height: 10),
                  Expanded(flex: 5, child: _arenaSection()),
                  const SizedBox(height: 12),
                  _controls(),
                  const SizedBox(height: 12),
                  Expanded(flex: 6, child: _boardSection()),
                ],
              ),
            ),
          ),
          if (_banner != null) _bannerOverlay(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('💰', d.gold, AppColors.gold),
          _stat('💎', d.gems.toDouble(), AppColors.cyan),
          if (d.prestigePoints > 0)
            _stat('✦', d.prestigePoints.toDouble(), AppColors.magenta),
          IconButton(
            onPressed: _openPauseSheet,
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            tooltip: 'Menu',
          ),
        ],
      ),
    );
  }

  Widget _stat(String icon, double value, Color color) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        AnimatedCounter(
          value: value,
          style: AppText.heading.copyWith(fontSize: 18, color: color),
        ),
      ],
    );
  }

  Widget _arenaSection() {
    return BattleArena(
      wave: d.wave,
      enemyHp: _enemyHp.clamp(0, _enemyMaxHp),
      enemyMaxHp: _enemyMaxHp,
      dps: _dps,
      isBoss: _isBoss,
      boosted: _boostTicksLeft > 0,
    );
  }

  Widget _controls() {
    final boosting = _boostTicksLeft > 0;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GlowButton(
            gradient: const [AppColors.green, Color(0xFF12B39B)],
            onTap: _summon,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SUMMON',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.white)),
                    Text('💰 ${fmt(_summonCost)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlowButton(
            gradient: boosting
                ? const [AppColors.gold, Color(0xFFFF6A00)]
                : const [AppColors.purple, AppColors.magenta],
            onTap: _boost,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(boosting ? '🔥 x2' : '🚀 BOOST',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white)),
                Text(
                  boosting
                      ? '${(_boostTicksLeft * _tickMs / 1000).ceil()}s'
                      : '💎 2',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _boardSection() {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MERGE BOARD', style: AppText.label),
              Row(
                children: [
                  const Icon(Icons.bolt, size: 15, color: AppColors.cyan),
                  const SizedBox(width: 2),
                  Text('Army ${fmt(_armyPower)}',
                      style: AppText.label.copyWith(color: AppColors.cyan)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: MergeGrid(board: _units, onDrop: _handleDrop)),
          const SizedBox(height: 6),
          const Text('Drag two identical units together to merge ✨',
              style: TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _bannerOverlay() {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_banner),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, v, _) => Transform.scale(
            scale: v.clamp(0.0, 1.2),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.magenta, AppColors.purple]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.magenta.withValues(alpha: 0.5),
                      blurRadius: 30),
                ],
              ),
              child: Text(_banner!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: 1)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet pause menu.
class _PauseSheet extends StatefulWidget {
  final GameData data;
  final VoidCallback onResume, onHowTo, onCodex, onPrestige, onQuit;
  const _PauseSheet({
    required this.data,
    required this.onResume,
    required this.onHowTo,
    required this.onCodex,
    required this.onPrestige,
    required this.onQuit,
  });

  @override
  State<_PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends State<_PauseSheet> {
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bg2, AppColors.bg0],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Text('PAUSED',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          _row(Icons.play_arrow_rounded, 'Resume', widget.onResume),
          _row(Icons.help_outline_rounded, 'How to Play', widget.onHowTo),
          _row(Icons.auto_awesome_mosaic_rounded, 'Codex', widget.onCodex),
          _row(
            Icons.autorenew_rounded,
            d.canPrestige
                ? 'Rebirth  (+${d.pendingPrestige} ✦)'
                : 'Rebirth  (wave 10+)',
            widget.onPrestige,
            color: d.canPrestige ? AppColors.magenta : Colors.white38,
          ),
          _row(
            Sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            Sfx.enabled ? 'Sound: On' : 'Sound: Off',
            () async {
              Sfx.enabled = !Sfx.enabled;
              await SaveService.saveSfx(Sfx.enabled);
              setState(() {});
            },
          ),
          const Divider(color: Colors.white12, height: 26),
          _row(Icons.home_rounded, 'Quit to Menu', widget.onQuit,
              color: AppColors.danger),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, VoidCallback onTap,
      {Color color = Colors.white}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
