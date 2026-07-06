import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'effects.dart';

/// Pure visual for a unit — reused by the board and the drag feedback.
class UnitCard extends StatelessWidget {
  final int level;
  final double size;
  final bool dragging;
  const UnitCard({
    super.key,
    required this.level,
    required this.size,
    this.dragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final tier = tierFor(level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tier.gradient,
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tier.gradient.last.withValues(alpha: dragging ? 0.8 : 0.5),
            blurRadius: dragging ? 26 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glossy top highlight (3D bevel — light from above).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size * 0.44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * 0.24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom inner shade (3D bevel — darker underside).
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size * 0.38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(size * 0.24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Text(tier.emoji, style: TextStyle(fontSize: size * 0.42)),
          ),
          // Level badge.
          Positioned(
            left: 5,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$level',
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Power readout.
          Positioned(
            bottom: 4,
            right: 6,
            child: Text(
              fmt(tier.power),
              style: TextStyle(
                fontSize: size * 0.16,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful board tile: elastic pop-in on spawn, punch + particles on merge.
class UnitTile extends StatefulWidget {
  final int level;
  final double size;
  const UnitTile({super.key, required this.level, required this.size});

  @override
  State<UnitTile> createState() => _UnitTileState();
}

class _UnitTileState extends State<UnitTile> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final AnimationController _punch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2200 + (widget.level * 137) % 900),
  )..repeat(reverse: true);
  late final Animation<double> _introScale =
      CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
  late final Animation<double> _punchScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
    TweenSequenceItem(
      tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: 60,
    ),
  ]).animate(_punch);

  bool _burst = false;

  @override
  void initState() {
    super.initState();
    _intro.forward();
  }

  @override
  void didUpdateWidget(UnitTile old) {
    super.didUpdateWidget(old);
    if (widget.level > old.level) {
      _punch.forward(from: 0);
      setState(() => _burst = true);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _punch.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _punch, _bob]),
      builder: (_, child) {
        final bob = math.sin(_bob.value * math.pi * 2) * widget.size * 0.03;
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(
            scale: _introScale.value.clamp(0.0, 2.0) * _punchScale.value,
            child: child,
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          UnitCard(level: widget.level, size: widget.size),
          if (_burst)
            Positioned.fill(
              child: ParticleBurst(
                colors: tierFor(widget.level).gradient,
                onDone: () {
                  if (mounted) setState(() => _burst = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty board cell; glows when a draggable is hovering over it.
class EmptySlot extends StatelessWidget {
  final double size;
  final bool highlight;
  const EmptySlot({super.key, required this.size, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.12 : 0.04),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: highlight
              ? AppColors.cyan.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.10),
          width: highlight ? 2 : 1.2,
        ),
        boxShadow: highlight
            ? [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.4), blurRadius: 14)]
            : null,
      ),
    );
  }
}
