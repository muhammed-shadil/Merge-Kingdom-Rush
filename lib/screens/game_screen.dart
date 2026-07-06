import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../widgets/battle_arena.dart';
import '../widgets/effects.dart';
import '../widgets/merge_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // --- Currencies & progression ---
  double _gold = 80;
  int _gems = 0;
  int _wave = 1;
  int _totalSummons = 0;
  int _bestLevel = 1;

  // --- Board ---
  final List<BoardUnit?> _board = List.filled(kBoardSize, null);
  int _nextId = 0;

  // --- Enemy ---
  late double _enemyMaxHp;
  late double _enemyHp;

  // --- Boost ---
  int _boostTicksLeft = 0;

  // --- Loop ---
  Timer? _timer;
  int _tick = 0;

  // --- Wave banner ---
  String? _banner;

  static const _tickMs = 100;

  bool get _isBoss => _wave % 5 == 0;

  @override
  void initState() {
    super.initState();
    // Seed a starter army so the board isn't empty.
    _spawnAt(0, 1);
    _spawnAt(1, 1);
    _spawnAt(2, 2);
    _enemyMaxHp = _hpForWave(_wave);
    _enemyHp = _enemyMaxHp;
    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), _onTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- economy
  double _hpForWave(int w) {
    final base = 45 * math.pow(1.32, w - 1).toDouble();
    return _wave % 5 == 0 ? base * 4.5 : base;
  }

  int get _summonCost => (10 * math.pow(1.12, _totalSummons)).round();

  double get _armyPower {
    double total = 0;
    for (final u in _board) {
      if (u != null) total += powerFor(u.level);
    }
    return total;
  }

  double get _dps => _armyPower * (_boostTicksLeft > 0 ? 2 : 1);

  // ---------------------------------------------------------------- loop
  void _onTick(Timer _) {
    _tick++;
    setState(() {
      // Combat
      final dmg = _dps * (_tickMs / 1000.0);
      if (dmg > 0 && _enemyHp > 0) {
        _enemyHp -= dmg;
        if (_enemyHp <= 0) _onEnemyDefeated();
      }
      // Boost countdown
      if (_boostTicksLeft > 0) _boostTicksLeft--;
      // Passive trickle so a wiped board can always recover.
      if (_tick % 10 == 0) _gold += 1 + _wave.toDouble();
    });
  }

  void _onEnemyDefeated() {
    final boss = _isBoss;
    final reward = (6 * _wave + 10) * (boss ? 3 : 1);
    _gold += reward;
    if (boss) _gems += 2;

    _wave++;
    _enemyMaxHp = _hpForWave(_wave);
    _enemyHp = _enemyMaxHp;

    _banner = _isBoss ? 'BOSS INCOMING!' : 'WAVE $_wave';
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  // ---------------------------------------------------------------- board ops
  void _spawnAt(int index, int level) {
    _board[index] = BoardUnit(_nextId++, level);
    _bestLevel = math.max(_bestLevel, level);
  }

  int? get _firstEmpty {
    for (var i = 0; i < kBoardSize; i++) {
      if (_board[i] == null) return i;
    }
    return null;
  }

  void _summon() {
    if (_gold < _summonCost) {
      _toast('Not enough gold — defeat enemies to earn more!');
      return;
    }
    final slot = _firstEmpty;
    if (slot == null) {
      _toast('Board full! Merge units to make space.');
      return;
    }
    setState(() {
      _gold -= _summonCost;
      _totalSummons++;
      _spawnAt(slot, 1);
    });
  }

  void _handleDrop(int from, int to) {
    if (from == to) return;
    final a = _board[from];
    final b = _board[to];
    if (a == null) return;

    setState(() {
      if (b == null) {
        // Move to empty cell.
        _board[to] = a;
        _board[from] = null;
      } else if (b.level == a.level && b.level < kMaxLevel) {
        // Merge! Target levels up, source is consumed.
        b.level += 1;
        _board[from] = null;
        _bestLevel = math.max(_bestLevel, b.level);
        _gold += powerFor(b.level); // small merge reward
      } else {
        // Swap.
        _board[from] = b;
        _board[to] = a;
      }
    });
  }

  void _boost() {
    if (_boostTicksLeft > 0) return;
    if (_gems < 2) {
      _toast('Need 2 gems — beat a boss (every 5th wave) to earn gems.');
      return;
    }
    setState(() {
      _gems -= 2;
      _boostTicksLeft = (8000 / _tickMs).round(); // 8 seconds
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

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('💰', _gold, AppColors.gold),
          _stat('💎', _gems.toDouble(), AppColors.cyan),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('BEST', style: AppText.label),
              Row(
                children: [
                  Text(tierFor(_bestLevel).emoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('Lv$_bestLevel',
                      style: AppText.heading.copyWith(fontSize: 16)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String icon, double value, Color color) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 6),
        AnimatedCounter(
          value: value,
          style: AppText.heading.copyWith(fontSize: 20, color: color),
        ),
      ],
    );
  }

  Widget _arenaSection() {
    return BattleArena(
      wave: _wave,
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
          Expanded(
            child: MergeGrid(board: _board, onDrop: _handleDrop),
          ),
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
