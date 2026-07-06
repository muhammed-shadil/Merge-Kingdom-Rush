import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'effects.dart';

/// The auto-battle stage: your castle blasts the incoming enemy.
class BattleArena extends StatefulWidget {
  final int wave;
  final double enemyHp;
  final double enemyMaxHp;
  final double dps;
  final bool isBoss;
  final bool boosted;

  const BattleArena({
    super.key,
    required this.wave,
    required this.enemyHp,
    required this.enemyMaxHp,
    required this.dps,
    required this.isBoss,
    required this.boosted,
  });

  @override
  State<BattleArena> createState() => _BattleArenaState();
}

class _BattleArenaState extends State<BattleArena>
    with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  final List<Widget> _floaters = [];
  int _floatKey = 0;
  double _accumDamage = 0;
  int _tickCount = 0;

  @override
  void didUpdateWidget(BattleArena old) {
    super.didUpdateWidget(old);
    if (widget.wave != old.wave) {
      _enter.forward(from: 0);
    }
    final delta = old.enemyHp - widget.enemyHp;
    if (delta > 0) {
      _shake.forward(from: 0);
      _accumDamage += delta;
      _tickCount++;
      if (_tickCount >= 3) {
        _spawnDamage(_accumDamage);
        _accumDamage = 0;
        _tickCount = 0;
      }
    }
  }

  void _spawnDamage(double amount) {
    final key = _floatKey++;
    final rnd = math.Random();
    final w = Positioned(
      key: ValueKey(key),
      right: 40.0 + rnd.nextDouble() * 60,
      top: 30.0 + rnd.nextDouble() * 40,
      child: FloatingText(
        text: '-${fmt(amount)}',
        color: widget.boosted ? AppColors.gold : Colors.white,
        fontSize: 18 + math.min(amount / widget.enemyMaxHp, 1) * 14,
        onDone: () {
          _floaters.removeWhere((e) => e.key == ValueKey(key));
          if (mounted) setState(() {});
        },
      ),
    );
    _floaters.add(w);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bob.dispose();
    _shake.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hpFrac = (widget.enemyHp / widget.enemyMaxHp).clamp(0.0, 1.0);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                AppColors.purple.withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
        ),
        // Wave label
        Positioned(
          left: 16,
          top: 12,
          child: Row(
            children: [
              Text(
                widget.isBoss ? '👑 BOSS' : 'WAVE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                  color: widget.isBoss ? AppColors.gold : Colors.white70,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.wave}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // DPS readout
        Positioned(
          right: 16,
          top: 12,
          child: Row(
            children: [
              Icon(Icons.bolt,
                  size: 16,
                  color: widget.boosted ? AppColors.gold : AppColors.cyan),
              const SizedBox(width: 2),
              Text(
                '${fmt(widget.dps)}/s',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: widget.boosted ? AppColors.gold : AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
        // Castle (left)
        const Positioned(
          left: 16,
          bottom: 16,
          child: Text('🏰', style: TextStyle(fontSize: 52)),
        ),
        // Enemy (right) with entrance slide, idle bob, hit shake
        AnimatedBuilder(
          animation: Listenable.merge([_bob, _shake, _enter]),
          builder: (context, _) {
            final bob = math.sin(_bob.value * math.pi) * 6;
            final shakeX =
                math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 8;
            final enter = Curves.easeOutBack.transform(_enter.value);
            return Positioned(
              right: 24 + (1 - enter) * 120,
              bottom: 30 + bob,
              child: Opacity(
                opacity: enter.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(shakeX, 0),
                  child: _EnemyView(
                    isBoss: widget.isBoss,
                    hpFrac: hpFrac,
                    hp: widget.enemyHp,
                    maxHp: widget.enemyMaxHp,
                  ),
                ),
              ),
            );
          },
        ),
        ..._floaters,
      ],
    );
  }
}

class _EnemyView extends StatelessWidget {
  final bool isBoss;
  final double hpFrac;
  final double hp;
  final double maxHp;
  const _EnemyView({
    required this.isBoss,
    required this.hpFrac,
    required this.hp,
    required this.maxHp,
  });

  @override
  Widget build(BuildContext context) {
    final size = isBoss ? 84.0 : 62.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // HP bar
        SizedBox(
          width: size + 24,
          child: Column(
            children: [
              Text(
                fmt(hp),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 7,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 120),
                      widthFactor: hpFrac,
                      child: Container(
                        height: 7,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.green, AppColors.gold],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (isBoss ? AppColors.danger : AppColors.magenta)
                    .withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Text(
            isBoss ? '🐲' : '👹',
            style: TextStyle(fontSize: size * 0.7),
          ),
        ),
      ],
    );
  }
}
